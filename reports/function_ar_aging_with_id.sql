set search_path to ocean_stream;

create or replace function ar_aging_report_with_id(
	            company_code_p char(6), customer_id_p char(6), query_date_p date)
  returns table(customer_name varchar(100),
  				customer_id char(6),
				phone_number char(12),
			   total_current_ar numeric,
               age_in_days integer,
			  within_10_days varchar(20),
			  within_20_days varchar(20),
			  within_30_days  varchar(20),
			  over_30_days varchar(20)
			  )
as
 $$
	
select 
		 cn.customer_name,
		 tmp3.customer_id,
		 ca.phone_number,
		 tmp3.current_ar as total_current_ar,
         max(age_in_days) as age_in_days,
		 sum(case when tmp3.age_in_days <10 then tmp3.current_ar else 0 end) as within_10_days,
		 sum(case when tmp3.age_in_days between 10 and 19 then tmp3.current_ar else 0 end) as within_20_days,
		 sum(case when tmp3.age_in_days between 20 and 29 then tmp3.current_ar else 0 end) as within_30_days, 
		 sum(case when tmp3.age_in_days >=30 then tmp3.current_ar else 0 end) as over_30_days
	from 
	 ( select tmp1.rie_id,
				tmp2.rre_id,
				tmp1.customer_id,
				query_date_p - tmp1.invoice_date as age_in_days,
				tmp2.receiving_date,
				sum(tmp1.invoice_amount+coalesce(tmp2.received_amount,0)) as current_ar
		from 
		  (select ai.rie_id,
					ai.date as invoice_date,
					ari.customer_id,
					ari.amount as invoice_amount
				 from ar_invoice ai
							inner join ar_invoice_item ari
							on ai.rie_id = ari.rie_id
							where ari.company_code = 'US001'
								and ari.general_ledger_number = 102001
							order by  ai.rie_id) tmp1
			left join 
				 (select  ar.rie_id,
									ar.rre_id,
									ar.date as receiving_date,
									ar.customer_id,
									-arit.amount as received_amount
							  from ar_receipt ar
							  inner join ar_receipt_item arit
							  on ar.rre_id = arit.rre_id
							  where arit.company_code = 'US001'
										and arit.general_ledger_number = 102001
								  order by  arit.rre_id
				  ) tmp2
			 on tmp1.rie_id = tmp2.rie_id
		group by tmp1.rie_id,
				tmp2.rre_id,
				tmp1.customer_id,
				tmp1.invoice_date,
				tmp2.receiving_date
	 ) tmp3
	 inner join customer_names cn
	 on cn.customer_id=tmp3.customer_id
	 inner join customer_addresses ca
	 on ca.customer_id = tmp3.customer_id
	 where tmp3.current_ar <> 0
group by  cn.customer_name, tmp3.customer_id,
ca.phone_number,  tmp3.current_ar 
 
$$ language sql;