import os
import psycopg2
import random
import pandas as pd
import numpy as np
import csv
import itertools


# fetch existing sales_order_ids and product_ids in database where the company_code is 'US001'
# generate sale_orders_items tuples
def _get_conn(pw, user_str):
    conn = psycopg2.connect(host="localhost",
                            database = db,
                            user= user_str,
                            password=pw)
    conn.autocommit = False
    return conn


# get shipped sales order ids placed by individuals
def get_s_so_items(conn):
    sql_so_item = """select
                        soi.company_code,
                        so.s_order_date, 
                        soi.sales_order_id,
                        si.invoice_id,
                        soi.product_id,
                        ac.area,
                        so.customer_id,
                        soi.units * soi.unit_selling_price as amount,
                        soi.units * soi.unit_selling_price * t.tax_rate as tax_amount
                     from sales_orders_items  soi
                     inner join sales_orders so
                     on soi.sales_order_id = so.sales_order_id
                    inner join customer_addresses ca
                    on ca.customer_id = so.customer_id
                    inner join area_code as ac
                    on ca.postcode = ac.zip
                    inner join sales_invoices si
                    on  si.sales_order_id = soi.sales_order_id
                    inner join tax t
                    on soi.tax_code = t.tax_code
               
                     where soi.shipped = 'yes'
                     and soi.company_code='US001' 
                     and so.s_order_date between '2021-03-01' and '2021-03-31'
                     order by soi.sales_order_id;           
             """
    with conn.cursor() as curs:
        curs.execute(sql_so_item)  #cursor closed after the execute action
        (s_so_items) = curs.fetchall()

    # write to csv file 
    with open(os.path.join('data/intermediate_csv', 'pre_ar_invoices_credit_i_1.csv'), 'w') as write_obj:
        csv_writer = csv.writer(write_obj)
        csv_writer.writerow(['company_code', 's_order_date', 'sales_order_id', 'invoice_id', 'product_id', 'area',
        'customer_id', 'amount', 'tax_amount'])
        for s_so_item in s_so_items:
            csv_writer.writerow(s_so_item)
        print('Done writing')
        
    return s_so_items
  

# get cost centre id via a tuple of product_id and area_code
def get_cc_ids(pr_cc):
    df = pd.read_csv('data/intermediate_csv/pre_ar_invoices_credit_i_1.csv')
    df['cc_id'] = df.apply(lambda row: pr_cc[(row.product_id, row.area)], axis =1)
    df.to_csv('data/intermediate_csv/pre_ar_invoices_credit_i_2.csv', index=False)
    return df

   
def get_rie(conn):
    sql = """select * from ar_invoice 
            where company_code = 'US001' 
            and date  between '2021-03-01' and '2021-03-31'
          """
    with conn.cursor() as curs:
        curs.execute(sql)  #cursor closed after the execute action
        (rie_ids) = curs.fetchall() 
        
    # write to csv file 
    with open(os.path.join('data/intermediate_csv', 'rie_ids.csv'), 'w') as write_obj:
        csv_writer = csv.writer(write_obj)
        csv_writer.writerow(['company_code', 'entry_type_id', 'rie_id', 'date','invoice_id'])
        for rie_id in rie_ids:
            csv_writer.writerow(rie_id)
        print('Done writing')        
         
           
def rie_cc(a, b):
    df = pd.merge(a, b[['invoice_id', 'customer_id', 'cc_id', 'amount', 'tax_amount']], on='invoice_id', how='left')
    df_c = df[['company_code', 'rie_id','cc_id', 'amount']]
    df_d = df[['company_code', 'rie_id', 'cc_id','tax_amount']]
    df_c.insert(2,'general_ledger_number', 501001)
    df_d.insert(2, 'general_ledger_number', 203001)
    df_c.insert(4,'currency_id',1)
    df_d.insert(4,'currency_id',1)
    df_c.insert(5, 'debit_credit', 'credit')
    df_d.insert(5, 'debit_credit', 'credit')
    # rename column name 'tax_amount' into 'amount' so that df_c, df_d can be concatenated
    df_e = df_d.rename(columns={'tax_amount':'amount'}, inplace=True)
    df_f = pd.concat([df_c, df_d])  
    # save to csv    
    df_f.to_csv('data/intermediate_csv/pre_ar_invoices_credit_i_3.csv', index=False)
    return df  

    
if __name__ == '__main__':
    db = 'ocean_stream'
    pw = os.environ['POSTGRES_PW']
    user_str = os.environ['POSTGRES_USER']
    conn = _get_conn(pw, user_str)
    
# map customer_id to predefined areas
# predefined areas are SE- north of king county, SP-east of cascade, KG- king and pierce county,
#                      OY - west of pugesound, south of pierce county, west of cascade.    
    pr_cc = {(3, 'SE'): 'PSE02', (3, 'KG'): 'PKG02', (3, 'SP'): 'PSP02', (3, 'OY'): 'POY02', (4, 'SE'): 'PSE04', (4, 'KG'): 'PKG04', (4, 'SP'): 'PSP04', (4, 'OY'): 'POY04', (5, 'SE'): 'SSE03', (5, 'KG'): 'SKG03', (5, 'SP'): 'SSP03', (5, 'OY'): 'SOY03'} 
    get_s_so_items(conn)
    get_cc_ids(pr_cc)
    get_rie(conn)
    a = pd.read_csv('data/intermediate_csv/rie_ids.csv')
    b = pd.read_csv('data/intermediate_csv/pre_ar_invoices_credit_i_2.csv') 
    rie_cc(a,b) 

