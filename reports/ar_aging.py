import os
import psycopg2
import csv
import pandas as pd
import pathlib
import logging
from bokeh.plotting import figure, show
from bokeh.io import output_file, save,export_png
from bokeh.layouts import column, row
from bokeh.models import (HoverTool,ColumnDataSource, CustomJSTransform, NumeralTickFormatter,CustomJSTickFormatter, Select)

logger = logging.getLogger(__name__)

# Get connection
# def _get_conn(pw, user_str):
#     conn = psycopg2.connect(host="localhost",
#                             database = db,
#                             user= user_str,
#                             password=pw)
#     conn.autocommit = False
#     return conn

# get connection via psycopg2
def _get_conn(user_str):
    """use .pgpass to store postgres variables"""
    conn = psycopg2.connect(host="localhost",
                            database = db,
                            user= user_str
                            )
    conn.autocommit = False
    return conn 
    
def ar_aging(conn, company_code, query_date):
    sql_file = open('reports/ar_aging_w_p.sql', 'r')
    sql = sql_file.read()
    
    with conn.cursor() as curs:
        curs.execute("set search_path to ocean_stream;")
        curs.execute(sql, {'company_code':company_code, 'query_date':query_date})  #cursor closed after the execute action
        (ar_aging) = curs.fetchall()
        return ar_aging
    conn.commit()

def ar_aging_from_function(conn, company_code, query_date, customer_id=None):
    sql_query = "set search_path to ocean_stream; SELECT * FROM ar_aging_report_with_id(%s, %s, %s);"
    
    with conn.cursor() as curs:
        curs.execute(sql_query, (company_code, customer_id, query_date))  #cursor closed after the execute action
        ar_aging_records = curs.fetchall()
        return ar_aging_records
    conn.commit()

def to_csv(conn, company_code, query_date,customer_id=None):
    ar_aging_tups = ar_aging_from_function(conn, company_code, query_date, customer_id) 
      
    with open(os.path.join('reporting_results', f'ar_aging_report_with_id{query_date}.csv'),'w', newline='') as write_obj:
        ar_aging_writer = csv.writer(write_obj)
        ar_aging_writer.writerow(['Customer Name','Customer_id', 'Phone number', 'Total current AR', 'Within 10 days','Within 20 days ', 'Within 30 days', 'Over 30 days']) # write header
        for tup in ar_aging_tups:
            ar_aging_writer.writerow(tup) 
        logger.info('aging report done writing')   

 #plot in bokeh 
def ar_aging_graph(conn, company_code, query_date, customer_id=None):
    ar_aging = ar_aging_from_function(conn, company_code, query_date, customer_id)
    df_a = pd.DataFrame(ar_aging, columns=['customer_name', 'customer_id','phone_number', 'total_current_ar', 'age_in_days','within_10_days','within_20_days ', 'within_30_days', 'over_30_days'])
    df_a['total_current_ar'] = df_a['total_current_ar'].astype(float)
    #print(df_a.head())
    source = ColumnDataSource(df_a)
    
    head, tail =  os.path.split(pathlib.Path(__file__).parent.absolute())
    # save as html file in 'html' folder
    # Create the folders using os.path.join
    html_dir = os.path.join(head, 'reporting_results', 'htmls')
    os.makedirs(html_dir, exist_ok=True)

    png_dir = os.path.join(head, 'reporting_results', 'pngs')
    os.makedirs(png_dir, exist_ok=True)

    path_html = os.path.join(html_dir, f'ar_aging_with_id{query_date}.html')
    output_file(filename=path_html, title=f'Ocean Stream (US) AR aging as of {query_date}') 
    # save as png file in 'png' folder
    path_png = os.path.join(png_dir, f'ar_aging_{query_date}.png') 
    output_file(filename=path_png, title=f'Ocean Stream (US) AR aging as of {query_date}') 
    
    p = figure(#plot_height=500,
              #plot_width=550,
           title=f'Ocean Stream (US) AR aging as of {query_date}',
           x_axis_label="Age in days",
           y_axis_label="Current AR amount",
           toolbar_location="right")
 
    p.scatter(x='age_in_days',
             y = 'total_current_ar',
            source = df_a,
            fill_alpha=1.0, 
            fill_color='gray',
            size=4,
            legend_label='AR ages')

    p.add_tools(HoverTool(tooltips=[('Customer Name', '@customer_name'),                                    
                                ('Phone number', '@phone_number'),
                                ('age_in_days', '@age_in_days'),
                                ('Current AR', '@total_current_ar')], mode='vline'))
                                
          
    #p.xaxis.major_label_orientation = pi/4 
    p.yaxis.formatter=NumeralTickFormatter(format="$‘0 a’") 
    p.xaxis.axis_label_text_font_size = "12pt"
    p.axis.axis_label_text_font_style = 'bold'                               
    p.legend.orientation = "horizontal"
    p.legend.label_text_font_size = '8pt'
    show(p)
    save(p)
    export_png(p, filename=path_png)


if __name__ == '__main__':
    db = 'ocean_stream'
    # pw = os.environ['POSTGRES_PW']
    # user_str = os.environ['POSTGRES_USER']
    # conn = _get_conn(pw, user_str)
    user_str ='ocean_user'
    conn = _get_conn(user_str)
    query_date = '2021-04-16'
    company_code = 'US001'
    # ar_aging(conn, company_code, query_date)
    # ar_aging_from_function(conn, company_code, query_date)
    to_csv(conn, company_code, query_date)
    ar_aging_graph(conn, company_code, query_date)
