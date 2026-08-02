import os
import psycopg2
import csv
from math import pi
import pandas as pd
import pathlib

from bokeh.io import output_notebook, output_file, save
from bokeh.plotting import figure, show
from bokeh.io import curdoc,export_png
from bokeh.layouts import column, row
from bokeh.models import (HoverTool,ColumnDataSource, CustomJSTransform, NumeralTickFormatter,CustomJSTickFormatter, Select)
from bokeh.plotting import figure
# from ocean_connect import _get_conn

# Get connection
def _get_conn(user_str):
    conn = psycopg2.connect(host="localhost",
                            database = db,
                            user= user_str,
                            #password=pw
                            )
    conn.autocommit = False
    return conn
    
def get_ar_aging(conn, company_code, query_date):
    sql_file = open('reports/ar_aging_p_d.sql', 'r')
    sql = sql_file.read()
    
    with conn.cursor() as curs:
        curs.execute("set search_path to ocean_stream;")
        curs.execute(sql, {'company_code':company_code, 'query_date':query_date})  #cursor closed after the execute action
        (ar_aging) = curs.fetchall()
        return ar_aging
    conn.commit()

def to_csv(conn, company_code, query_date):
    ar_aging_tups = get_ar_aging(conn, company_code, query_date) 
      
    with open(os.path.join('reporting_results', f'ar_aging_report_{query_date}_d.csv'),'w', newline='') as write_obj:
        ar_aging_writer = csv.writer(write_obj)
        ar_aging_writer.writerow(['company_code','customer_name', 'Phone number', 'rie_id', 'age_in_days', 'Current AR']) # write header
        for tup in ar_aging_tups:
            ar_aging_writer.writerow(tup) 
        print('aging report done writing')   

# plot in bokeh 
def ar_aging_graph(conn, company_code, query_date):
    ar_aging = get_ar_aging(conn, company_code, query_date)
    df_a = pd.DataFrame(ar_aging, columns=['company_code','customer_name', 'phone_number', 'rie_id', 'age_in_days', 'current_ar'])
    df_a['current_ar'] = df_a['current_ar'].astype(float)
    #print(df_a.head())
    source = ColumnDataSource(df_a)
    
    head, tail =  os.path.split(pathlib.Path(__file__).parent.absolute())
    # save as html file in 'html' folder
    path_html = os.path.join(head, 'reporting_results/htmls', f'ar_aging_{query_date}.html')
    output_file(filename=path_html, title=f'AR aging as of {query_date}') 
    # save as png file in 'png' folder
#    path_png = os.path.join(head, 'reporting_results/pngs', f'ar_aging_{query_date}.png')     
#    output_file(filename=path_png, title=f'AR aging as of {query_date}') 
    
    p = figure(#plot_height=500,
              #plot_width=550,
           title=f'AR aging as of {query_date}',
           x_axis_label="Age in days",
           y_axis_label="Current AR amount",
           toolbar_location="right")
 
    p.scatter(x='age_in_days',
             y = 'current_ar',
            source = df_a,
            fill_alpha=1.0, 
            fill_color='gray',
            size=4,
            legend_label='AR ages')

    p.add_tools(HoverTool(tooltips=[('company_code', '@company_code'),
                                    ('Customer Name', '@customer_name'),                                    
                                ('Phone number', '@phone_number'),
                                ('age_in_days', '@age_in_days'),
                                ('Current AR', '@current_ar')], mode='vline'))
                                
          
    #p.xaxis.major_label_orientation = pi/4 
    p.yaxis.formatter=NumeralTickFormatter(format="$‘0 a’") 
    p.xaxis.axis_label_text_font_size = "12pt"
    p.axis.axis_label_text_font_style = 'bold'                               
    p.legend.orientation = "horizontal"
    p.legend.label_text_font_size = '8pt'
    show(p)
    save(p)
    #export_png(p, filename="path_png")
    
if __name__ == '__main__':
    db = 'ocean_stream'
    # pw = os.environ['POSTGRES_PW']
    # user_str = os.environ['POSTGRES_USER']
    # conn = _get_conn(pw, user_str)
    user_str= 'ocean_user'
    conn = _get_conn(user_str)
    query_date = '2021-04-12'
    company_code = 'US001'
    get_ar_aging(conn, company_code, query_date)
    #to_csv(conn, company_code, query_date)
    ar_aging_graph(conn, company_code, query_date)
