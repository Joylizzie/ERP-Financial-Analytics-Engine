import os
import psycopg2
import datetime
import csv
import pandas as pd
from bokeh.io import output_notebook, output_file, save, export_png
from bokeh.plotting import figure, show
from bokeh.models import (HoverTool, ColumnDataSource,NumeralTickFormatter)
from math import pi
import pathlib

    
# connect to Postgres
def _get_conn(user_str):
    conn = psycopg2.connect(host="localhost",
                            database = db,
                            user= user_str)
    conn.autocommit = False
    return conn

def get_sub_graph(conn, start_date, end_date):
    func = """select * from transaction_list('US001',500000, 999999, '2021-03-01', '2021-03-31')"""
    with conn.cursor() as curs:
        curs.execute("set search_path to ocean_stream;")
        curs.execute(func)
        pls = curs.fetchall()

        conn.commit()
        df = pd.DataFrame(pls, columns=['company_code', 'sub_name','profit_centre','currency_id','amount'])
        df['amount'] = df['amount'].astype(float)
        # a list of unique profit centres for bokeh figure
        pcs = list(df['profit_centre'].unique())
        # a list of unique sub_name for different graphs
        sub_names = list(df['sub_name'].unique())
        # dataframes filtered by sub_name 
        df_rev = df.loc[df['sub_name']== 'Revenue']
        df_exp = df.loc[df['sub_name']== 'Expenses']
        #turn above sub_name dataframe into ColumnDataSource
        source_rev = ColumnDataSource(df_rev)
        source_exp = ColumnDataSource(df_exp)
        # save the html file to folder '/home/lizhi/projects/joylizzie/Financial_reports/reporting_results/htmls'
        head, tail =  os.path.split(pathlib.Path(__file__).parent.absolute())
        html_dir = os.path.join(head, 'reporting_results', 'htmls')
        os.makedirs(html_dir, exist_ok=True)

        png_dir = os.path.join(head, 'reporting_results', 'pngs')
        os.makedirs(png_dir, exist_ok=True)
        file_name = f'profit and loss during {end_date.strftime("%b-%Y")}'
        path_html= os.path.join(html_dir, f'3_profit_loss_by_pc_{end_date.strftime("%m_%Y")}.html')
        output_file(filename=path_html, title=f'profit and loss during {end_date.strftime("%b-%Y")}')        
        path_png = os.path.join(png_dir, f'3_profit_loss_by_pc_{end_date.strftime("%m_%Y")}.png')     
        output_file(filename=path_png, title=f'Ocean Stream (US) P&L by Profit Centre {end_date.strftime("%m_%Y")}') 

        p = figure(x_range=pcs,                 
                   height=500,
                  width=550,
               title='Ocean Stream (US) P&L by profit centre',
               x_axis_label="Profit centres",
               y_axis_label="Amount",
               toolbar_location="right")

        p.vbar(x='profit_centre',
            top='amount',
            bottom = 0,
            source = source_rev,
            width=0.8,
            color='blue',
            legend_label='Revenue')

        p.vbar(x='profit_centre',
            top='amount',
            bottom = 0,
            source = source_exp,
            width=0.9,
            color='red',
            legend_label='Expenses')

        p.add_tools(HoverTool(tooltips=[('company_code', '@company_code'),
                                        ('profit_centre', '@profit_centre'),                                    
                                    ('amount', '@amount')], mode='vline'))
                                    
        p.yaxis.formatter=NumeralTickFormatter(format="$‘0 a’")        
        p.xaxis.major_label_orientation = pi/4 
        p.xaxis.axis_label_text_font_size = "12pt"
        p.axis.axis_label_text_font_style = 'bold'                               
        p.legend.orientation = "horizontal"
        p.legend.label_text_font_size = '8pt'
        
        show(p)
        save(p)
        export_png(p, filename=path_png)
        #return p

if __name__ == '__main__':
    db = 'ocean_stream'
    # pw = os.environ['POSTGRES_PW']
    # user_str = os.environ['POSTGRES_USER']
    # conn = _get_conn(pw, user_str)
    user_str = 'ocean_user'
    conn = _get_conn(user_str)
    start_date = datetime.date(2021,3,1)
    end_date = datetime.date(2021,3,31)
    col_names = ['company_code', 'sub_name','profit_centre', 'currency_id','amount']
    get_sub_graph(conn, start_date, end_date)

