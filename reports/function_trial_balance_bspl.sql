/* 1.This function retrieve all transanctions from je, ar_invoice_item, ar_receipt_item,ap_invoice_item, ap_payment_item
   2.The amount is grouped by bs_pl_index
   3.Filtered by company_code
  
*/

set search_path to ocean_stream;
--drop function trial_balance_bspl(char(6),date, date);

create or replace function trial_balance_bspl(company_code_p char(6), 
                                start_date_p date, end_date_p date) 
   returns table(bs_pl_cat_name varchar(30),
                  amount numeric)
as
 $$
  
    select  bpi.bs_pl_cat_name,
	        --tmp.general_ledger_number,
	        sum(tmp.amount)
    from(
     --je db list
        (select general_ledger_number, 
	        sum(case when debit_credit = 'credit' then -amount else amount end) as amount
        from journal_entry_item je
        where je.company_code = company_code_p and 
               je.transaction_date between start_date_p and end_date_p 
        group by general_ledger_number
        ) 
    union
    -- ar invoice item db list
        (select general_ledger_number, 
	        sum(case when debit_credit = 'credit' then -amount else amount end) as amount
        from ar_invoice_item ar
        inner join ar_invoice ari
        on ar.rie_id = ari.rie_id
        where ar.company_code = company_code_p 
        and ari.date between start_date_p and end_date_p
        group by ar.general_ledger_number
        ) 
    union 
    -- ar receipt item db list
        (select general_ledger_number, 
	        sum(case when debit_credit = 'credit' then -amount else amount end) as amount
        from ar_receipt_item arr
        inner join ar_receipt art
        on arr.rre_id = art.rre_id     
        where arr.company_code = company_code_p
        and art.date between start_date_p and end_date_p         
        group by general_ledger_number
        ) 
    union 
        (select general_ledger_number, 
	        sum(case when debit_credit = 'credit' then -amount else amount end) as amount
        from ap_invoice_item api
        inner join ap_invoice ap
        on api.pie_id = ap.pie_id
        where api.company_code = company_code_p 
         and ap.date between start_date_p and end_date_p        
        group by general_ledger_number
        )
    union
        (select general_ledger_number, 
	        sum(case when debit_credit = 'credit' then -amount else amount end) as amount
        from ap_payment_item app
        inner join ap_payment apt
        on app.ppe_id = apt.pie_id
        where app.company_code = company_code_p
        and apt.date between start_date_p and end_date_p            
        group by general_ledger_number
        )
    )tmp
    inner join chart_of_accounts coa
    on coa.general_ledger_number = tmp.general_ledger_number
    inner join bs_pl_idx bpi -- trying get name of bs_pl_index
    on bpi.bs_pl_index = coa.bs_pl_index
   --where bpi.bs_pl_index in %(bs_pl_index_tup)s -- sign as variable, Python code can change it and get different result	 
    group by bpi.bs_pl_cat_name,bpi.bs_pl_index
    order by bpi.bs_pl_index;
 
 $$ language sql;


/* 
-- not part of the function, if you want to call the function
  -- check if sum of amount if is 0, if not, find out error(s)
 select sum(amount) from trial_balance_bspl('US001', '2021-03-01', '2021-03-31');
  -- If the sum(amount) is 0, below query will return a list of general_ledger with its amount 
 select * from trial_balance_bspl('US001', '2021-03-01', '2021-03-31');
 
*/
