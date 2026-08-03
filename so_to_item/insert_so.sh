
set -e

python so_to_item/pre_sales_orders_1.py
cp data/intermediate_csv/pre_sales_orders_1.csv /tmp


psql --host=localhost -U ocean_user --dbname=ocean_stream -a -f so_to_item/insert_so.sql


