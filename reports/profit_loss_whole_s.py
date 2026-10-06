import os
import psycopg2
import datetime
import csv
import pandas as pd
from bokeh.io import output_notebook, output_file, save
from bokeh.plotting import figure, curdoc, show
from bokeh.models import (HoverTool, ColumnDataSource, LabelSet,NumeralTickFormatter, FixedTicker)
from math import pi
import pathlib


# built a waterfall chart showing company level of profit and loss: revenue deduct by cost of goods sold to get gross margin, 
# then deduct all kinds of expenses to get the net profit 

# connect to Postgres
def _get_conn(user_str):
    conn = psycopg2.connect(host="localhost",
                            database = db,
                            user= user_str,
                            )
    conn.autocommit = False
    return conn

def num_format(num, round_to=2):
    magnitude = 0
    while abs(num) >= 1000:
        magnitude += 1
        num = round(num / 1000.0, round_to)
    return '{:.{}f}{}'.format(round(num, round_to), round_to, ['', 'K', 'M', 'G', 'T', 'P'][magnitude])


def get_sub_graph(conn):
    func = """select * from trial_balance_bspl_full('US001',50,99, '2021-03-01', '2021-03-31');"""
    with conn.cursor() as curs:
        curs.execute("set search_path to ocean_stream;")
        curs.execute(func)
        pls = curs.fetchall()

    conn.commit()
    index = [tup[1] for tup in pls]
    data = {'amount':[float(tup[2]) for tup in pls]}
        
    df = pd.DataFrame(data=data,index=index)
    #print(df)
    # Determine the total net value by adding the start and all additional transactions
    net_profit = df['amount'].sum()
    df['running_total'] = df['amount'].cumsum()
    df['y_start'] = df['running_total'] - df['amount']

    # Where do we want to place the label?
    df['label_pos'] = df['running_total']

    df_net = pd.DataFrame.from_records([(net_profit, net_profit, 0, net_profit)],
                                       columns=['amount', 'running_total', 'y_start', 'label_pos'],
                                       index=["Net_profit"])
    df = pd.concat([df, df_net], ignore_index=False)

    df['color'] = 'green'
    df.loc[df.amount < 0, 'color'] = 'red'
    df.loc[df.amount < 0, 'label_pos'] = df.label_pos
    df["bar_label"] = list(map(num_format, df['amount']))

    source = ColumnDataSource(df)
    # the max of y_range will be the max of df['amount'], then increase 5%
    p = figure(x_range=list(df.index), y_range=(0, max(df['amount'])*1.05),
               width=800, title = "Company wide Profit and Loss Waterfall")    

    p.add_tools(HoverTool(tooltips=[("label", "@index"),
                  ("Amount", "@bar_label")], mode='vline'))
    
    p.segment(x0='index', y0='y_start', x1="index", y1='running_total',
          source=source, color="color", line_width=50)
    
    p.grid.grid_line_alpha=0.3
    p.yaxis[0].formatter = NumeralTickFormatter(format="($ 0 a)") # format to million
    p.xaxis.axis_label = "Breakdown of profit and loss"

    p.xaxis.major_label_orientation = pi/4 
    p.xaxis.axis_label_text_font_size = "12pt"
    p.axis.axis_label_text_font_style = 'bold'        
    
    labels = LabelSet(x='df.index', y='label_pos', text='bar_label',
                  text_font_size="10pt", level='glyph', x_offset=-50, y_offset=5000000,source=source)
    p.add_layout(labels)
    show(p)

    
    # save the html file to folder '/home/lizhi/projects/joylizzie/Financial_reports/reporting_results/htmls'
    head, tail =  os.path.split(pathlib.Path(__file__).parent.absolute())

    path = os.path.join(head, 'reporting_results/htmls', f'profit_loss_whole_{end_date.strftime("%m_%Y")}.html')
    output_file(filename=path, title=f'profit and loss during {end_date.strftime("%b-%Y")}')        
    
    save(p)
    
if __name__ == '__main__':
    db = 'ocean_stream'
    # pw = os.environ['POSTGRES_PW']
    # user_str = os.environ['POSTGRES_USER']
    user_str = 'ocean_user'
    conn = _get_conn(user_str)
    end_date = datetime.date(2021,3,31)
    
    get_sub_graph(conn)

