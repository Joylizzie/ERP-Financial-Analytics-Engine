show search_path;

DROP SCHEMA IF EXISTS ocean_stream CASCADE;

CREATE SCHEMA IF NOT EXISTS ocean_stream
AUTHORIZATION CURRENT_USER; 

set search_path TO ocean_stream;


drop table if exists companies CASCADE;
drop table if exists coa_categories CASCADE;
drop table if exists fiscal_months CASCADE;
drop table if exists sub_coa_categories CASCADE;
drop table if exists bs_pl_idx CASCADE;
drop table if exists business_type CASCADE;
drop table if exists entry_type CASCADE;
drop table if exists general_ledger CASCADE;
drop table if exists general_ledger_item CASCADE;
drop table if exists currencies cascade;
drop table if exists tax CASCADE;
drop table if exists chart_of_accounts CASCADE;
drop table if exists profit_centres CASCADE;
drop table if exists cost_centres CASCADE;
drop table if exists wbs CASCADE;
drop table if exists area_code cascade;
drop table if exists vendors CASCADE;
drop table if exists vendors_addresses CASCADE;
drop table if exists customer_names CASCADE;
drop table if exists customer_addresses CASCADE;
drop table if exists product_categories cascade;
drop table if exists products CASCADE;
drop table if exists purchase_orders CASCADE;
drop table if exists purchase_orders_items;
drop table if exists sales_orders CASCADE;
drop table if exists sales_orders_items CASCADE;
drop table if exists sales_invoices CASCADE;
drop table if exists ap_invoice CASCADE;
drop table if exists ap_invoice_item CASCADE;
drop table if exists ap_payment CASCADE;
drop table if exists ap_payment_item CASCADE;
drop table if exists ar_invoice CASCADE;
drop table if exists ar_invoice_item CASCADE;
drop table if exists ar_receipt CASCADE;
drop table if exists ar_receipt_item CASCADE;
drop table if exists grades CASCADE;
drop table if exists employee_names CASCADE;
drop table if exists employee_salaries CASCADE;
drop table if exists employee_cost_centres CASCADE;

-- company_code should be country's name in two capital letters, plus three digits
-- company_name
create table if not exists companies (
    company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) primary key not null,
    company_name varchar(30) not null
    );

--Functional currency of Parent company is different than it's subsidaries when they run in differnet jurisdiction.
create table if not exists currencies(
    company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
    currency_id serial primary key,
    currency_name char(3) check(currency_name ~ '[A-Z]{3}') not null,
    description varchar(20),
    functional_currency boolean not null,
	CONSTRAINT fk_companyCode
      FOREIGN KEY(company_code) 
	  REFERENCES companies(company_code)	
    );

--balance sheet category: assets, liabilities, equity
--profit_loss category: revenue, cost_of_goods, gross_margin, operation_expenses
create table if not exists coa_categories(
	coacat_id integer primary key, 
	coa_category_name varchar(20) not null	
    );
    
create table if not exists sub_coa_categories(
    sub_coacat_id serial primary key,
    sub_coacat_name varchar(40),
    coacat_id integer not null, 
    CONSTRAINT fk_coa_catid
      FOREIGN KEY(coacat_id) 
	  REFERENCES coa_categories(coacat_id)
    );    

create table if not exists bs_pl_idx(
    bs_pl_index integer primary key not null,
    bs_pl_cat_name varchar(40),
    coacat_id integer not null,
    sub_coacat_id integer not null,
	CONSTRAINT fk_coacategory
      FOREIGN KEY(coacat_id) 
	  REFERENCES coa_categories(coacat_id),
	CONSTRAINT fk_subcoacat
      FOREIGN KEY(sub_coacat_id) 
	  REFERENCES sub_coa_categories(sub_coacat_id)
    );
    
create table if not exists fiscal_months(
    id serial PRIMARY key NOT NULL,
    year integer NOT NULL,
    month integer NOT NULL,
    start_date date unique NOT NULL,
    end_date date unique NOT NULL
    );    
    	
create table if not exists tax(
	company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
	tax_code serial primary key,
	tax_name varchar(15) unique,
	tax_rate numeric(4,4) not null,
	tax_area varchar(20) not null,
	tax_belongto varchar(15) check( tax_belongto in ('state','federal')),
    description varchar(30) not null,
	CONSTRAINT fk_companyCode
      FOREIGN KEY(company_code) 
	  REFERENCES companies(company_code)
    );

create table if not exists chart_of_accounts(
	company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
	general_ledger_number integer check(general_ledger_number between 100000 and 999999) unique not null,
	general_ledger_name varchar(30) unique not null,
	coacat_id integer references coa_categories(coacat_id) not null,
    sub_coacat_id integer references sub_coa_categories(sub_coacat_id) not null,	
	bs_pl_index integer not null,
	currency_id integer references currencies(currency_id),
	CONSTRAINT fk_companyCode
      FOREIGN KEY(company_code) 
	  REFERENCES companies(company_code),
	CONSTRAINT fk_coacategory
      FOREIGN KEY(coacat_id) 
	  REFERENCES coa_categories(coacat_id),
	CONSTRAINT fk_subcoacat
      FOREIGN KEY(sub_coacat_id) 
	  REFERENCES sub_coa_categories(sub_coacat_id),
	CONSTRAINT fk_bs_plcat
      FOREIGN KEY(bs_pl_index) 
	  REFERENCES bs_pl_idx(bs_pl_index),		  	  
	constraint fk_currency
		foreign key(currency_id)
			references currencies(currency_id)
	); 

--A profit centre is for arregating revenue and cost for a company.
--A profit centre can have mulitple cost centres and wbs codes.
create table if not exists profit_centres(
	company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
	pc_id char(6) check(pc_id ~ '[A-Z]{3}[0-9]{3}') primary key, 
	pc_name varchar(30) not null,
	CONSTRAINT fk_companyCode
      FOREIGN KEY(company_code) 
	  	REFERENCES companies(company_code)
    );

--A cost is for accumulating cost for a group.
create table if not exists cost_centres(
	company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
	cc_id char(5) check(cc_id ~ '[A-Z]{3}[0-9]{2}') primary key, 
	name varchar(30) not null,
	pc_id char(6),
	CONSTRAINT fk_companyCode
      FOREIGN KEY(company_code) 
	    REFERENCES companies(company_code),
	constraint fk_profitcentre
		foreign key (pc_id)
			references profit_centres(pc_id)
);

--A wbs code is for accumulating cost for a product is in developing.
create table if not exists wbs(
	company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
	wbs_code char(5) check(wbs_code ~ '[A-Z]{2}[0-9]{3}') primary key, 
	name varchar(20),
	pc_id char(6),
	CONSTRAINT fk_companyCode
      FOREIGN KEY(company_code) 
	    REFERENCES companies(company_code),
	constraint fk_profitcentre
		foreign key (pc_id)
			references profit_centres(pc_id)
);

--A vendor sells goods, or provides services or both to the company.
--In accounting operations, an invoice from a vendor will be booked against this vendor as accounts payable.
create table if not exists vendors (
	company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
	vendor_id char(5) primary key check (vendor_id ~ '[A-Z]{2}[0-9]{3}' ),
	vendor_name varchar(60) not null,
    general_ledger_number integer default 200001,
	currency_id integer references currencies not null,
	CONSTRAINT fk_companyCode
      FOREIGN KEY(company_code) 
	  REFERENCES companies(company_code),
	CONSTRAINT fk_currencyid
      FOREIGN KEY(currency_id) 
	  REFERENCES currencies(currency_id)
	);

create table if not exists vendor_addresses(
	company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
	vendor_id char(5) not null,
	address_line1 varchar(250) not null,
	address_line2 varchar(20),
	city          varchar(30) not null,
	state         varchar(15),
	country       varchar(20),
	postcode       varchar(10),
	phone_number  varchar(20),
	email_address varchar(100),
	CONSTRAINT fk_companyCode
      FOREIGN KEY(company_code) 
	  REFERENCES companies(company_code),
	CONSTRAINT fk_vendorid
      FOREIGN KEY(vendor_id) 
	  REFERENCES vendors(vendor_id)
    );

create table if not exists business_type(
    company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
    business_type_id serial primary key,
    business_type_name varchar(15) check(business_type_name in ('organization', 'individual')),
    CONSTRAINT fk_companyCode
      FOREIGN KEY(company_code) 
	   REFERENCES companies(company_code)
    );


create table if not exists area_code(
  	zip varchar(10) not null,
	zipcode_name varchar(30),
	city varchar(30),
	state char(2),
	county_name varchar(40),
	area char(2)	
	);

create table if not exists customer_names (
	company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
	customer_id char(6) primary key check (customer_id ~ '[A-Z]{3}[0-9]{3}' ),
    business_type_id integer not null,
	customer_name varchar(250),
	general_ledger_number integer default 102001,
    currency_id integer not null,    
	CONSTRAINT fk_companyCode
      FOREIGN KEY(company_code) 
	  REFERENCES companies(company_code)
	);

create table if not exists customer_addresses (
	company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
	customer_id char(6) not null,
	address_line1 varchar(250) not null,
	city          varchar(30) not null,
	state         varchar(15),
	country       varchar(20),
	postcode       varchar(10),
    phone_number   varchar(20),
	email_address  varchar(60),
	CONSTRAINT fk_companyCode
      FOREIGN KEY(company_code) 
	  REFERENCES companies(company_code),
	CONSTRAINT fk_customer_id
      FOREIGN KEY(customer_id) 
	  REFERENCES customer_names(customer_id)
	);

create table if not exists product_categories(
	company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
	cat_id char(1) primary key,
	cat_name varchar(20) not null,
	subcat_id integer,
	subcat_name varchar(20),
	CONSTRAINT fk_companyCode
      FOREIGN KEY(company_code) 
	  REFERENCES companies(company_code)
    );

create table if not exists products (
	company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
	product_id serial primary key not null,
	cat_id char(1) references product_categories(cat_id) not null,
	product_name varchar(60) not null,
	product_unit_name varchar(30),
	product_units integer,
	product_unit_price numeric check (product_unit_price > 0) not null,
	currency_id integer references currencies not null,
	CONSTRAINT fk_companyCode
      FOREIGN KEY(company_code) 
	  REFERENCES companies(company_code),
	CONSTRAINT fk_productcat
      	FOREIGN KEY(cat_id) 
	  		REFERENCES product_categories(cat_id),
	CONSTRAINT fk_currencyid
      	FOREIGN KEY(currency_id) 
	  		REFERENCES currencies(currency_id)
    );

create table if not exists purchase_orders (
	company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
	p_order_id serial primary key,
	p_order_date DATE NOT NULL,
	vendor_id char(6) not null,
	CONSTRAINT fk_companyCode
      FOREIGN KEY(company_code) 
	  REFERENCES companies(company_code),
	CONSTRAINT fk_vendor
      FOREIGN KEY(vendor_id) 
	  REFERENCES vendors(vendor_id)
    );

create table if not exists purchase_orders_items (
	company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
	p_order_id integer references purchase_orders(p_order_id) not null,
	product_id integer references products(product_id),
	item_id serial not null,
	cc_id char(5) references cost_centres(cc_id),
	general_ledger_number integer check(general_ledger_number in(502001, 600001)),
	wbs_code char(5) references wbs(wbs_code), 
	tax_code integer references tax(tax_code) not null,
	CONSTRAINT fk_companyCode
      FOREIGN KEY(company_code) 
	  REFERENCES companies(company_code),
	CONSTRAINT fk_po
      FOREIGN KEY(p_order_id) 
	  REFERENCES purchase_orders(p_order_id),
	CONSTRAINT fk_products
      FOREIGN KEY(product_id) 
	  REFERENCES products(product_id),
	CONSTRAINT fk_tax
      FOREIGN KEY(tax_code) 
	    REFERENCES tax(tax_code),
     CONSTRAINT fk_costcentre
       FOREIGN KEY(cc_id) 
	    REFERENCES cost_centres(cc_id),	
	 CONSTRAINT fk_wbs
       FOREIGN KEY(wbs_code) 
	    REFERENCES wbs(wbs_code)	
    );

create table if not exists sales_orders(
	company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
	sales_order_id serial primary key not null,
	s_order_date DATE NOT NULL,
	customer_id char(6) references customer_names(customer_id) not null,
	CONSTRAINT fk_companyCode
      FOREIGN KEY(company_code) 
	  REFERENCES companies(company_code),
	 CONSTRAINT fk_customer
      	FOREIGN KEY(customer_id) 
	  		REFERENCES customer_names(customer_id)
    );

create table if not exists sales_orders_items (
	company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
	sales_order_id integer not null,
	product_id integer not null,
	unit_name varchar(6),
	units integer,
	unit_selling_price numeric not null,
   	currency_id integer references currencies not null,
   	tax_code integer references tax(tax_code) not null,
    shipped boolean not null,
	CONSTRAINT fk_companyCode
      FOREIGN KEY(company_code) 
	  REFERENCES companies(company_code),
	CONSTRAINT fk_productid
      FOREIGN KEY(product_id) 
	  REFERENCES products(product_id),
	CONSTRAINT fk_currencyid
      FOREIGN KEY(currency_id) 
	  REFERENCES currencies(currency_id),
	CONSTRAINT fk_tax
      FOREIGN KEY(tax_code) 
	    REFERENCES tax(tax_code),
    CONSTRAINT fk_salesorders
      	FOREIGN KEY(sales_order_id) 
	  		REFERENCES sales_orders(sales_order_id)
	);

-- sales invoice will be issued to customers with shipped sales order items
create table if not exists sales_invoices (
	company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
	invoice_date DATE NOT NULL,
	invoice_id serial primary key not null,
    sales_order_id integer not null,
	customer_id char(6) references customer_names(customer_id) not null,
	amount numeric(12,2),
	CONSTRAINT fk_companyCode
      	FOREIGN KEY(company_code) 
	  		REFERENCES companies(company_code),
    CONSTRAINT fk_salesorders
      	FOREIGN KEY(sales_order_id) 
	  		REFERENCES sales_orders(sales_order_id),
	 CONSTRAINT fk_customer
      	FOREIGN KEY(customer_id) 
	  		REFERENCES customer_names(customer_id)
    );

create table if not exists entry_type(
    entry_type_id varchar(3) primary key,
    entry_type_name varchar(20) not null,
    description varchar(100)
    );

create table if not exists journal_entry(
        company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
        entry_type_id varchar(3) default 'JE',
        je_id serial primary key,
        CONSTRAINT fk_companyCode
      	    FOREIGN KEY(company_code) 
	  		    REFERENCES companies(company_code),
        CONSTRAINT fk_entrytype
            FOREIGN KEY(entry_type_id) 
	            REFERENCES entry_type(entry_type_id)
        );
 


create table if not exists journal_entry_item(
        company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
        je_id integer not null,
        transaction_date DATE NOT NULL,
        description varchar(80),
        general_ledger_number integer not null,
        cc_id char(6) references cost_centres(cc_id), 
        wbs_code char(5) references wbs(wbs_code),
        currency_id integer references currencies not null,
        debit_credit varchar(6) check(debit_credit in ('debit', 'credit')) NOT NULL,
        amount numeric(12,2),
        CONSTRAINT fk_companyCode
      	    FOREIGN KEY(company_code) 
	  		    REFERENCES companies(company_code),
        CONSTRAINT fk_journalentryid
            FOREIGN KEY(je_id) 
	            REFERENCES  journal_entry( je_id),
        CONSTRAINT coasgln
            FOREIGN KEY(general_ledger_number) 
	            REFERENCES  chart_of_accounts(general_ledger_number),
        CONSTRAINT fk_costcentre
            FOREIGN KEY(cc_id) 
	            REFERENCES cost_centres(cc_id),
	    CONSTRAINT fk_wbs
            FOREIGN KEY(wbs_code) 
	            REFERENCES wbs(wbs_code),
	    CONSTRAINT fk_currencyid
            FOREIGN KEY(currency_id) 
	            REFERENCES currencies(currency_id)	
       );

-- sales invoices booked to Financial statements via ar_invoice double entry
create table if not exists ar_invoice(
        company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
        entry_type_id varchar(3) default 'RIE',
        rie_id serial primary key not null,
		date DATE NOT NULL,
		invoice_id integer not null,
        CONSTRAINT fk_companyCode
      	    FOREIGN KEY(company_code) 
	  		    REFERENCES companies(company_code),
         CONSTRAINT fk_salesinvoice
      	    FOREIGN KEY(invoice_id) 
	  		    REFERENCES sales_invoices(invoice_id)	
		);


create table if not exists ar_invoice_item(
        company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
        rie_id integer not null,
		description varchar(80),
        customer_id char(6) check (customer_id ~ '[A-Z]{3}[0-9]{3}' ),
        general_ledger_number integer default 102001,
	 	cc_id char(6) references cost_centres(cc_id),
        currency_id integer references currencies not null,
        debit_credit varchar(6) default 'debit',
        amount numeric(12,2),
        CONSTRAINT fk_companyCode
      	    FOREIGN KEY(company_code) 
	  		    REFERENCES companies(company_code),	    
         CONSTRAINT fk_arinvoice
      	    FOREIGN KEY(rie_id) 
	  		    REFERENCES ar_invoice(rie_id),
         CONSTRAINT fk_coano
      	    FOREIGN KEY(general_ledger_number) 
	  		    REFERENCES chart_of_accounts(general_ledger_number),
	     CONSTRAINT fk_customer
          	FOREIGN KEY(customer_id) 
	      		REFERENCES customer_names(customer_id),	  	
	     CONSTRAINT fk_currencyid
            FOREIGN KEY(currency_id) 
	            REFERENCES currencies(currency_id),
		 CONSTRAINT fk_costcentre
		   FOREIGN KEY(cc_id) 
			REFERENCES cost_centres(cc_id)	
       );
	   

create table if not exists ar_receipt(
        company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
        entry_type_id varchar(3) default 'RRE',
        rre_id serial primary key not null,
		date DATE NOT NULL,		
		rie_id integer not null,
		customer_id char(6) check (customer_id ~ '[A-Z]{3}[0-9]{3}' ),
        CONSTRAINT fk_companyCode	
      	    FOREIGN KEY(company_code) 
	  		    REFERENCES companies(company_code),
	     CONSTRAINT fk_customer
          	FOREIGN KEY(customer_id) 
	      		REFERENCES customer_names(customer_id),	  		    
        CONSTRAINT fk_arinvoice
      	    FOREIGN KEY(rie_id) 
	  		    REFERENCES ar_invoice(rie_id)	
   );

create table if not exists ar_receipt_item(
        company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
        rre_id integer references ar_receipt(rre_id) not null,
        description varchar(80),
        general_ledger_number integer default 102001,
        currency_id integer references currencies not null,
        debit_credit varchar(6) default 'credit' NOT NULL,
        amount numeric(12,2),
        CONSTRAINT fk_companyCode
      	    FOREIGN KEY(company_code) 
	  		    REFERENCES companies(company_code),
        CONSTRAINT fk_arreceipt
      	    FOREIGN KEY(rre_id) 
	  		    REFERENCES ar_receipt(rre_id),
         CONSTRAINT fk_coano
      	    FOREIGN KEY(general_ledger_number) 
	  		    REFERENCES chart_of_accounts(general_ledger_number),
	    CONSTRAINT fk_currencyid
            FOREIGN KEY(currency_id) 
	            REFERENCES currencies(currency_id)        
     );
	 
create table if not exists ap_invoice(
        company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
        entry_type_id varchar(3) default 'PIE',
	    pie_id serial primary key not null,
        vendor_id char(5) check (vendor_id ~ '[A-Z]{2}[0-9]{3}' ) not null,
		date DATE NOT NULL,
        -- p_order_id integer references purchase_orders(p_order_id),
        invoice_id varchar(10) not null,
        -- general_ledger_number integer default 200001,
        -- currency_id integer references currencies not null,
       	-- debit_credit varchar(6) default 'debit' NOT NULL,
		-- amount numeric,
        CONSTRAINT fk_companyCode
      	    FOREIGN KEY(company_code) 
	  		    REFERENCES companies(company_code),
	    -- CONSTRAINT fk_po
        --     FOREIGN KEY(p_order_id) 
	    --         REFERENCES purchase_orders(p_order_id),
	    CONSTRAINT fk_vendor
          FOREIGN KEY(vendor_id) 
	      REFERENCES vendors(vendor_id)
		  );

create table if not exists ap_invoice_item(
        company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
        vendor_id char(5) check (vendor_id ~ '[A-Z]{2}[0-9]{3}' ) not null,
		pie_id integer not null,
        description varchar(80),
        general_ledger_number integer,
	 	cc_id char(6) references cost_centres(cc_id),
		wbs_code char(5) references wbs(wbs_code),
        currency_id integer references currencies not null,
       	debit_credit varchar(6) not null check(debit_credit in ('debit', 'credit')),
        amount numeric(12,2),
        CONSTRAINT fk_companyCode
      	    FOREIGN KEY(company_code) 
	  		    REFERENCES companies(company_code),
        -- CONSTRAINT fk_apinvoicepieid
      	--     FOREIGN KEY(pie_id) 
	  	-- 	    REFERENCES ap_invoice(pie_id),	
		-- CONSTRAINT fk_apinvoicevendorid
      	--     FOREIGN KEY(vendor_id) 
	  	-- 	    REFERENCES ap_invoice(vendor_id),			
		 CONSTRAINT fk_costcentre
		   FOREIGN KEY(cc_id) 
			REFERENCES cost_centres(cc_id),
	    CONSTRAINT fk_wbs
            FOREIGN KEY(wbs_code) 
	            REFERENCES wbs(wbs_code),
         CONSTRAINT fk_coano
      	    FOREIGN KEY(general_ledger_number) 
	  		    REFERENCES chart_of_accounts(general_ledger_number),	
	    CONSTRAINT fk_currencyid
            FOREIGN KEY(currency_id) 
	            REFERENCES currencies(currency_id)
      );

create table if not exists ap_payment(
		company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
        entry_type_id varchar(3) default 'PPE',
		ppe_id serial primary key,
		date DATE NOT NULL,
		pie_id integer not null,
        vendor_id char(5) check (vendor_id ~ '[A-Z]{2}[0-9]{3}' ) not null,
        CONSTRAINT fk_companyCode
      	    FOREIGN KEY(company_code) 
	  		    REFERENCES companies(company_code),
	    CONSTRAINT fk_vendor
          FOREIGN KEY(vendor_id) 
	      REFERENCES vendors(vendor_id),	  		    
	    CONSTRAINT fk_apinvoice
            FOREIGN KEY(pie_id) 
	            REFERENCES ap_invoice(pie_id)   
	);
	
	
create table if not exists ap_payment_item(
		company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
		ppe_id integer not null,
		description varchar(80),
        general_ledger_number integer default 200001,
        currency_id integer references currencies not null,
        debit_credit varchar(6) default 'debit' NOT NULL,
        amount numeric(12,2),
        CONSTRAINT fk_companyCode
      	    FOREIGN KEY(company_code) 
	  		    REFERENCES companies(company_code),
         CONSTRAINT fk_coano
      	    FOREIGN KEY(general_ledger_number) 
	  		    REFERENCES chart_of_accounts(general_ledger_number),
	    CONSTRAINT fk_appayment
            FOREIGN KEY(ppe_id) 
	            REFERENCES ap_payment(ppe_id)       
        );
        
create table if not exists grades(
      company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
      grade_code integer check(grade_code in (1,2,3)) primary key,
      grade_name varchar(20),
      CONSTRAINT fk_companyCode
        FOREIGN KEY(company_code) 
	        REFERENCES companies(company_code)
	  );               
                        
create table if not exists employee_names(
    company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
    employee_id char(5) primary key check (employee_id ~ '[A-Z]{2}[0-9]{3}'),
    employee_name varchar(50) not null,
    grade_code integer check(grade_code between 1 and 3)  not null,
    CONSTRAINT fk_companyCode
  	    FOREIGN KEY(company_code) 
  		    REFERENCES companies(company_code), 
    CONSTRAINT fk_gradecode
  	    FOREIGN KEY(grade_code) 
  		    REFERENCES grades(grade_code) 
  	);	     		       
    
create table if not exists employee_salaries(
    company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
    employee_id char(5) primary key check (employee_id ~ '[A-Z]{2}[0-9]{3}'),
    grade_code integer check(grade_code between 1 and 3) not null,
    currency_id integer references currencies not null,
    salary numeric(12,2),
    CONSTRAINT fk_companyCode
  	    FOREIGN KEY(company_code) 
  		    REFERENCES companies(company_code),
    CONSTRAINT fk_currencyid
        FOREIGN KEY(currency_id) 
            REFERENCES currencies(currency_id),  		     
    CONSTRAINT fk_gradecode
  	    FOREIGN KEY(grade_code) 
  		    REFERENCES grades(grade_code),  		     
    CONSTRAINT fk_employid
  	    FOREIGN KEY(employee_id) 
  		    REFERENCES employee_names(employee_id)
    );
    
create table if not exists employee_cost_centres(
    company_code char(5) check (company_code ~ '[A-Z]{2}[0-9]{3}' ) not null,
    employee_id char(5) primary key check (employee_id ~ '[A-Z]{2}[0-9]{3}'),
    cc_id char(5) check(cc_id ~ '[A-Z]{3}[0-9]{2}'), 
    CONSTRAINT fk_companyCode
  	    FOREIGN KEY(company_code) 
  		    REFERENCES companies(company_code), 
     CONSTRAINT fk_costcentre
       FOREIGN KEY(cc_id) 
	    REFERENCES cost_centres(cc_id),
    CONSTRAINT fk_employid
  	    FOREIGN KEY(employee_id) 
  		    REFERENCES employee_names(employee_id)
    );    
