set - e

python ar_in_to_receipt/received_customer_id.py

cp ar_in_to_receipt/pre_ar_receipt_id.csv /tmp

# set search_path TO ocean_stream;

# \COPY ar_receipt(company_code, date,rie_id,customer_id) FROM '/tmp/pre_ar_receipt_id.csv' DELIMITER ',' CSV HEADER;

psql --host=localhost -U ocean_user --dbname=ocean_stream -a -f ar_in_to_receipt/pre_ar_receipt_id.sql