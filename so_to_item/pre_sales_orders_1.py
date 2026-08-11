import os
import psycopg2
import random
import datetime
import csv

random.seed(5)

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

# choose random date bwtween start and end date
def randomdate(start_date, end_date):
    # calculate time between start_date and end_date, then convert the time to days
    days_between_dates = (end_date - start_date).days
    # select random day in above days
    random_number_of_days = random.randrange(days_between_dates)
    random_date = start_date + datetime.timedelta(days=random_number_of_days)
    return random_date

# get a list of tuples customer_ids, with 2 kinds of business_type_id, store into a list
def get_cust_ids(conn):
    business_type_ids = [1,2]
    ret_lst = []
    for bt in business_type_ids:
        sql = """select customer_id from customer_names 
            where business_type_id= %s and company_code='US001';             
                """
        with conn.cursor() as curs:
            curs.execute("set search_path to ocean_stream;")
            curs.execute(sql, (bt,))  #cursor closed after the execute action
            cust_ids = curs.fetchall()# a list of tuples
            ret_lst.append(cust_ids)

        os.makedirs('data/intermediate_csv', exist_ok=True)#print(tups)
        with open(os.path.join('data/intermediate_csv',f'cust_ids_{bt}'), 'w') as write_obj:
            csv_writer = csv.writer(write_obj)
            csv_writer.writerow(['customer_id']) # write header        
            csv_writer.writerows(cust_ids)
    #print('Done writing')    
    return ret_lst           

def generate_value_tuples(n_sample_b, n_sample_i, start_date, end_date,conn):
    cust_ids_b, cust_ids_i = get_cust_ids(conn)            
    b_cust_ids_sample = random.sample(cust_ids_b, n_sample_b)
    #print(b_cust_ids_sample)
    i_cust_ids_sample = random.sample(cust_ids_i, n_sample_i)
    #print(i_cust_ids_sample)
    random_cust_ids = b_cust_ids_sample + i_cust_ids_sample
    #print(random_cust_ids)
    n = n_sample_b + n_sample_i
   
    t = [('US001',randomdate(start_date, end_date),*random_cust_ids[i]) for i in range(n)]
    return t

       
# generate sales order values and save in csv file, then upload to db from psql which is quicker comparing to below way.
def _to_csv(n_sample_b, n_sample_i, start_date, end_date,conn, outfile):
    tups = generate_value_tuples(n_sample_b, n_sample_i, start_date, end_date,conn)
    with open(os.path.join('data/intermediate_csv', outfile), 'w') as write_obj:
        csv_writer = csv.writer(write_obj)
        csv_writer.writerow(['company_code', 's_order_date', 'customer_id']) # write header
        n = n_sample_b + n_sample_i
        for i in range(n):
            csv_writer.writerow(tups[i])
        print('Done pre_sales_orders writing')


if __name__ == '__main__':
    db = 'ocean_stream'
    # pw = os.environ['POSTGRES_PW']
    # user_str = os.environ['POSTGRES_USER']
    user_str = 'ocean_user'
    # conn = _get_conn(pw, user_str)
    conn = _get_conn(user_str)
    start_date = datetime.date(2021, 3, 1)
    end_date = datetime.date(2021, 7, 31)
    sample_b = 750
    sample_i = 1749
    #get_cust_ids(conn)
    generate_value_tuples(sample_b,sample_i, start_date, end_date,conn)
    _to_csv(sample_b,sample_i, start_date, end_date, conn, outfile=f'pre_sales_orders_1.csv')