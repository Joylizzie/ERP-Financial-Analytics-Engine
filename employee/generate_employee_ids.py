import os
import string
import random
import csv

random.seed(5)

# generate 3 random uppercase letters
def random_uc(d):
    return ''.join([random.choice(string.ascii_uppercase) for _ in range(d)])

# generate 2 random digits
def random_dg(d):
    return ''.join([random.choice(string.digits) for _ in range(d)])

# generate random employee id, with length=5, first 2 uppercase letters, followed by 3 digits
def employee_id():
    return random_uc(2) + random_dg(3)

# generate given number of employee ids
def employee_ids(n):
    count = 0
    employee_ids_set = set()
    while count < n:
        new_employee_id = employee_id()
        if new_employee_id in employee_ids_set:
            continue
        else:
            employee_ids_set.add(new_employee_id)
            count += 1 
   
    return employee_ids_set 
    

def to_csv(n, out_file):
    company_code = 'US001'
    with open(os.path.join('data', out_file), 'w') as employee_ids:
        csv_writer = csv.writer(employee_ids)
        csv_writer.writerow(header)
        for employee_id in employee_ids_lst:
            csv_writer.writerow([company_code, employee_id]) # [] must be around employee_id, otherwise it will be each character separated by coma. 
    print('Done writing') 

    
if __name__ == '__main__':

    n = 2000
    out_file = '/home/lizhi/projects/joylizzie/Financial_reports/data/employee_ids.csv'
    header = ['company_code', 'employee_id']
    employee_ids(n)
    employee_ids_lst = list(employee_ids(n))
    to_csv(n, out_file)
    

