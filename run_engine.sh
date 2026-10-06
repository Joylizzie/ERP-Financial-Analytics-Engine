set -e
#!/bin/sh

# This script is for creating db, tables then inserting values

# create db
bash database/create_db_local.sh
#create user ocean_user 
bash database/create_ocean_user.sh
# create tables
bash database/create_ocean_stream_table.sh
# create values for tables
bash database/create_ocean_stream_table_values.sh
#insert customer names and addresses
bash customers/insert_customer_n_a.sh
# insert sales_order_id
bash so_to_item/insert_so.sh
# insert sales orders items
bash so_to_item/insert_so_item.sh
# insert sales invoice ids
bash sales_invoice/insert_sales_invoices.sh
# insert ar invoice ids
psql --host=localhost -U ocean_user --dbname=ocean_stream -a -f ar_in_to_receipt/pre_ar_invoice_id.sql
# insert ar invoice items - debit side
psql --host=localhost -U ocean_user --dbname=ocean_stream -a -f ar_in_to_receipt/insert_ar_invoice_items_debit.sql
# insert ar invoice items - credit side
psql --host=localhost -U ocean_user --dbname=ocean_stream -a -f ar_in_to_receipt/insert_ar_invoice_items_credit.sql
# copy ar_in_to_receipt_id to tmp
bash ar_in_to_receipt/create_pre_ar_receipt_id.sh
# ar_receipt_item ids
psql --host=localhost -U ocean_user --dbname=ocean_stream -a -f ar_in_to_receipt/pre_ar_receipt_id.sql
# ar_receipt_item double entries for both debit and credit side  
psql --host=localhost -U ocean_user --dbname=ocean_stream -a -f ar_in_to_receipt/pre_ar_receipt_item.sql

# Post employee labour cost
bash employee/insert_employee.sh
psql --host=localhost -U ocean_user --dbname=ocean_stream -a -f employee/insert_employee.sql

# je double entry postings(insert je_id, then journal_entry_item)
bash je_double_entries/insert_je_capital.sh
bash je_double_entries/insert_je_2.sh
bash je_double_entries/insert_je_4.sh

# insert ap invoice ids and its double entry postings
# bash po_in_py/insert_po_in_ap.sh

# Insert ar_aging function into Postgres
psql --host=localhost -U ocean_user --dbname=ocean_stream -a -f reports/function_ar_aging.sql
# Insert transaction_list function into Postgres
psql --host=localhost -U ocean_user --dbname=ocean_stream -a -f reports/function_transaction_list.sql
# Insert transaction_list_in_detail function into Postgres
psql --host=localhost -U ocean_user --dbname=ocean_stream -a -f reports/function_transaction_list_detail.sql
# Retrieve transaction_list 
psql --host=localhost -U ocean_user --dbname=ocean_stream -c "SET search_path TO ocean_stream;\
              SELECT * FROM transaction_list( 'US001'::char(5), 100001::integer, 999999::integer, '2021-03-01'::date, '2021-03-31'::date);"
# Retrieve transaction_list_in_detail 
psql --host=localhost -U ocean_user --dbname=ocean_stream -c "SET search_path TO ocean_stream;\
              SELECT * FROM transaction_list_detail('US001'::char(5), 100000::integer, 999999::integer, 1::integer, '2021-03-01'::date, '2021-03-31'::date);"
# Insert trial_balance function into Postgres
psql --host=localhost -U ocean_user --dbname=ocean_stream -a -f reports/function_trial_balance_bspl.sql
psql --host=localhost -U ocean_user --dbname=ocean_stream -a -f reports/function_trial_balance_gl.sql
psql --host=localhost -U ocean_user --dbname=ocean_stream -c "SET search_path TO ocean_stream; SELECT * FROM trial_balance_gl( 'US001'::char(6), '2021-03-01'::date, '2021-03-31'::date);"
psql --host=localhost -U ocean_user --dbname=ocean_stream -a -f reports/function_trial_balance_pl_whole.sql
psql --host=localhost -U ocean_user --dbname=ocean_stream -c "SET search_path TO ocean_stream; SELECT * FROM trial_balance_bspl_full( 'US001'::char(6),1::integer, 70::integer, '2021-03-01'::date, '2021-03-31'::date);"

# generate financial statement

# profit and loss 
python reports/profit_loss.py
# python reports/profit_loss_whole.py
# profit and loss by pc 
python reports/profit_loss_by_pc_3.py
# balance sheets progressively achieved desired results
# v1 -v3 results inserted into desired places with different coa, subcoa and bs_pl_idx
# python reports/1_balance_sheet.py
# python reports/2_balance_sheet.py
# python reports/3_balance_sheet.py
# final results with total for different categories and balance sheet is balanced if plus the total amount of profit_loss
python reports/4_balance_sheet.py

# ar aging report
python reports/ar_aging.py
# run django to generate Financial reports and visualizations
python run finweb/manage.py