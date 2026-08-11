
set -e

python so_to_item/pre_sales_orders_items_i.py
python so_to_item/pre_sales_orders_items_b.py


file_b=$(ls data/intermediate_csv/pre_sales_orders_items_b_*.csv | tail -1)
ym_b=$(basename "$file_b" | sed 's/pre_sales_orders_items_b_//' | sed 's/.csv//')
echo "$ym_b"
cp data/intermediate_csv/pre_sales_orders_items_b_${ym_b}.csv /tmp
file_i=$(ls data/intermediate_csv/pre_sales_orders_items_i_*.csv | tail -1)
ym_i=$(basename "$file_i" | sed 's/pre_sales_orders_items_i_//' | sed 's/.csv//')
cp data/intermediate_csv/pre_sales_orders_items_i_${ym_i}.csv /tmp
# cp data/intermediate_csv/pre_sales_orders_items_i_2021-03.csv /tmp
# cp data/intermediate_csv/pre_sales_orders_items_b_2021-03.csv /tmp

psql --host=localhost -U ocean_user --dbname=ocean_stream -a -f so_to_item/insert_so_item.sql
