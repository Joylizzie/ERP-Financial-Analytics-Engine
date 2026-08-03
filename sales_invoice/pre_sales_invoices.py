import os
import psycopg2
import csv


# fetch existing sales_order_ids and product_ids in database where the company_code is 'US001'
# get connection via psycopg2
# def _get_conn(pw, user_str):
#    """use .bashrc to store postgres variables"""
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


# get shipped sales orders placed by individuals for preparing sales invoices
def get_s_so_items(conn):
    sql_shipped_item = """select 
	                    so.company_code,
	                    so.s_order_date,
	                    so.sales_order_id,
	                    so.customer_id,
                        sum(soi.units * soi.unit_selling_price*(1+t.tax_rate)) as amount
                     from sales_orders_items soi
                     inner join sales_orders so
                     on soi.sales_order_id = so.sales_order_id
                     inner join tax t
                     on t.tax_code = soi.tax_code
                     where soi.shipped = 'yes'
                     and so.company_code='US001' 
                     and so.s_order_date between '2021-03-01' and '2021-03-31'
                     group by
	                    so.company_code,
	                    so.sales_order_id,
	                    so.customer_id
                    order by so.sales_order_id;       
             """
             
    with conn.cursor() as curs:
        curs.execute("set search_path to ocean_stream;")
        curs.execute(sql_shipped_item)  #cursor closed after the execute action
        (shipped_items) = curs.fetchall()

    # write to csv file 
    with open(os.path.join('data/intermediate_csv', 'pre_sales_invoices.csv'), 'w') as write_obj:
        csv_writer = csv.writer(write_obj)
        csv_writer.writerow(['company_code','invoice_date', 'sales_order_id', 'customer_id', 'amount'])
        for shipped_item in shipped_items:
            csv_writer.writerow(shipped_item)
        print('Done writing')
        
    return shipped_items
    
   
if __name__ == '__main__':
    db = 'ocean_stream'
    # pw = os.environ['POSTGRES_PW']
    # user_str = os.environ['POSTGRES_USER']
    # conn = _get_conn(pw, user_str)
    user_str = 'ocean_user'
    conn = _get_conn(user_str)
    get_s_so_items(conn)

    
