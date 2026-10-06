
set search_path TO ocean_stream;


\COPY vendors(company_code, vendor_id, vendor_name, general_ledger_number, currency_id) FROM '/tmp/vendors.csv' DELIMITER ',' CSV HEADER;
    
\COPY vendor_addresses(company_code, vendor_id, address_line1, address_line2, city, state, country, postcode, phone_number, email_address) FROM '/tmp/vendor_addresses.csv' DELIMITER ',' CSV HEADER;

\COPY ap_invoice(company_code, entry_type_id, pie_id, vendor_id, date, invoice_id) FROM '/tmp/ap_invoice_1.csv' DELIMITER ',' CSV HEADER;

\COPY ap_invoice_item(company_code, vendor_id, pie_id, description, general_ledger_number, cc_id, wbs_code, currency_id, debit_credit, amount) FROM    '/tmp/ap_invoice_item_debit.csv' DELIMITER ',' CSV HEADER
\COPY ap_invoice_item(company_code, vendor_id, pie_id, description, general_ledger_number, cc_id, wbs_code, currency_id, debit_credit, amount) FROM    '/tmp/ap_invoice_item_credit.csv' DELIMITER ',' CSV HEADER