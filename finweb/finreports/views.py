from django.shortcuts import render
from pathlib import Path

from django.conf import settings
from django.http import HttpResponse,JsonResponse
from bokeh.plotting import figure
from bokeh.resources import CDN
from django.views import generic
from bokeh.embed import components, file_html
from django.db import connections
from itertools import chain
from pathlib import Path
import csv
from confluent_kafka import Producer
import json

import pandas as pd
from bokeh.models import (HoverTool, ColumnDataSource,NumeralTickFormatter)
from math import pi

# Setup Producer (Points to your local Fedora Kafka)
p = Producer({'bootstrap.servers': 'localhost:9092'})

def index(request):
    return render(request, 'finreports/index.html')

def balancesheet(request):

    BASE_DIR = Path(__file__).resolve().parent.parent.parent
    csv_fp = open(f'{BASE_DIR}/reporting_results/4_sum_bs_03_2021.csv', 'r')
    reader = csv.DictReader(csv_fp)
    out = [row for row in reader]
    return render(request, 'finreports/balancesheet/bs.html', {'data' : out})

def pl(request):
    conn = connections['default']
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
        # # save the html file to folder '/home/lizhi/projects/joylizzie/Financial_reports/reporting_results/htmls'
        # head, tail =  os.path.split(pathlib.Path(__file__).parent.absolute())
 
        # path = os.path.join(head, 'reporting_results/htmls', f'3_profit_loss_by_pc_{end_date.strftime("%m_%Y")}.html')
        # output_file(filename=path, title=f'profit and loss during {end_date.strftime("%b-%Y")}')        

        p = figure(x_range=pcs,                 
                   height=500,
                  width=550,
               title='Profit and loss by profit centre',
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

        script, div = components(p)
 
        return render(request, 'finreports/pl/pl.html', {'script': script, 'div': div})


def araging(request):

    return render(request,"this is Account receivable aging")


# -----------------------------
# New JSON endpoints
# -----------------------------
def pl_json(request):
    conn = connections['default']
    with conn.cursor() as curs:
        curs.execute("set search_path to ocean_stream;")
        curs.execute("""select * from transaction_list('US001',500000, 999999, '2021-03-01', '2021-03-31')""")
        pls = curs.fetchall()
        conn.commit()

    df = pd.DataFrame(pls, columns=['company_code', 'sub_name','profit_centre','currency_id','amount'])
    df['amount'] = df['amount'].astype(float)

    company_code = request.GET.get("company_code")
    if company_code:
        df = df[df['company_code'] == company_code]

    data = df.to_dict(orient='records')
    return JsonResponse({"pl": data})

def balance_sheet_json(request):
    BASE_DIR = Path(__file__).resolve().parent.parent.parent
    with open(f'{BASE_DIR}/reporting_results/4_sum_bs_03_2021.csv', 'r') as csv_fp:
        df = pd.read_csv(csv_fp)

    company = request.GET.get("company")
    if company:
        df = df[df['company'] == company]

    return JsonResponse({"balance_sheet": df.to_dict(orient='records')})

def araging_json(request):
    data = [
        {"customer": "Customer A", "company": "US001", "amount_due": 1000, "days_overdue": 10, "due_date": "2026-01-01"},
        {"customer": "Customer B", "company": "US002", "amount_due": 500, "days_overdue": 30, "due_date": "2025-12-01"},
    ]
    # Logic: If anyone is 30+ days late, tell Kafka!
    for entry in data:
        if entry['days_overdue'] >= 30:
            message = f"Send chasing letter to : {entry['customer']} is {entry['days_overdue']} days late!"
            p.produce('ar-aging-alerts', message.encode('utf-8'))
    
    p.flush() # Ensure message is sent
    return JsonResponse({"ar_aging": data})