
# je double entry postings
# get a je_id

python je_double_entries/pre_je_id_se.py
cp je_double_entries/je_item_4.csv /tmp
psql --host=localhost -U ocean_user --dbname=ocean_stream -a -f je_double_entries/insert_je_4.sql
