#!/bin/sh
set -e


cp data/vendors.csv /tmp
cp data/vendor_addresses.csv /tmp
cp po_in_py/ap_invoice_1.csv /tmp
cp po_in_py/ap_invoice_item_debit.csv /tmp
cp po_in_py/ap_invoice_item_credit.csv /tmp

psql --host=localhost -U ocean_user --dbname=ocean_stream -a -f po_in_py/insert_po_in_ap.sql