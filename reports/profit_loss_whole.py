import os
import psycopg2
import datetime
import csv
import pandas as pd
from bokeh.io import output_notebook, output_file, save
from bokeh.plotting import figure, show
from bokeh.models import (HoverTool, ColumnDataSource, LabelSet,NumeralTickFormatter)
from math import pi
import pathlib
from millify import millify

# built a waterfall chart showing company level of profit and loss: revenue deduct by cost of goods sold to get gross margin, 
# then deduct all kinds of expenses to get the net profit 

# # connect to Postgres
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

def get_sub_graph(conn):
    func = """select * from trial_balance_bspl_full('US001',50,99, '2021-03-01', '2021-03-31');"""
    with conn.cursor() as curs:
        curs.execute("set search_path to ocean_stream;")
        curs.execute(func)
        pls = curs.fetchall()

    conn.commit()
    label_name = [tup[1] for tup in pls]
    data = {'amount':[float(tup[2]) for tup in pls]}
#    print(index)
#    print(data)
        
    df = pd.DataFrame(data=data,index=label_name)
    #print(df)
    # Determine the total net value by adding the start and all additional transactions
    net = df['amount'].sum()
    df['running_total'] = df['amount'].cumsum()
    df['y_start'] = df['running_total'] - df['amount']

    df['label_pos'] = df['running_total']

    df_net = pd.DataFrame.from_records([(net, net, 0, net)],
                                       columns=['amount', 'running_total', 'y_start', 'label_pos'],
                                       index=["net"])

    df = pd.concat([df, df_net], ignore_index=False)
    #print(df)
    df['color'] = 'grey'
    df.loc[df.amount < 0, 'color'] = 'red'
    df.loc[df.amount < 0, 'label_pos'] = df.label_pos - 100000
    # df["bar_label"] = df["amount"].map('{:,.0f}'.format)
    df["bar_label"] = df["amount"].apply(lambda x: millify(x, precision=1))
    print(df)

    TOOLS = "box_zoom,reset,save"
    source = ColumnDataSource(df)
    p = figure(tools=TOOLS, x_range=list(df.index), y_range=(0, net+40000),
               width=800, title = "Company wide Profit and Loss Waterfall")    
    
    p.segment(x0='index', y0='y_start', x1="index", y1='running_total',
          source=source, color="color", line_width=55)
    
    p.grid.grid_line_alpha=0.3
    p.yaxis[0].formatter = NumeralTickFormatter(format="($ 0 a)")
    p.xaxis.axis_label = "Transactions" 
    
    labels = LabelSet(x='index', y='label_pos', text='bar_label',
                  text_font_size="8pt", level='glyph',
                  x_offset=-20, y_offset=0, source=source)
    p.add_layout(labels)
    
    show(p)    

    # save the html file to folder '~/reporting_results/htmls'
    head, tail =  os.path.split(pathlib.Path(__file__).parent.absolute())

    path = os.path.join(head, 'reporting_results/htmls', f'profit_loss_whole_march_2021.html')
    output_file(filename=path, title=f'profit and loss during March 2021')        
    
if __name__ == '__main__':
    db = 'ocean_stream'
    # pw = os.environ['POSTGRES_PW']
    user_str = 'ocean_user'
    # user_str = os.environ['POSTGRES_USER']
    conn = _get_conn(user_str)

    get_sub_graph(conn)

