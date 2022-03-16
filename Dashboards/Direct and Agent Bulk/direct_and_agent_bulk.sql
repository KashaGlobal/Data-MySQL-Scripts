with mashup as (select A.* ,Ax.New_Repeat ,left(case_date,7) as 'Created_Month',left(case_date,10) as 'date_created',
		date_paid, agent_customer_id,		
		case when A.order_business_grouping = 'Corporate Institutional' and (A.status<>'completed' or A.status<>'fulfilled') then closed_revenue else processing_total end as 'Revenue_in_processing',		
		D.fulfillment_status, E.name, D.invoice_status,	D.issued_at, D.ship_at,	D.packed_status, D.payment_status, return_status, returning_status, E.quantity, E.total,
		ROW_NUMBER() OVER (PARTITION by A.order_id ORDER BY A.order_id) AS 'order_ind', D.status as 'TG_Status', D.sales_agent, D.payment_plan,
	        CONCAT(B.first_name,' ',B.last_name) as 'Agent_name', agent_location_name ,		
	        Case when date_paid is null then 'Not paid' else 'paid' end as 'WC Payment status',		
	        Case when A.status regexp 'cancelledduplicat|ordercanceledt597|cancelled|completed' then '' else (		
			Case when (fulfillment_status='shipped' or A.status regexp 'delivered|dispatch') then 'Out on delivery' when (A.status regexp 'verified|verified846' or  fulfillment_status='unshipped') then 'Awaiting fulfillment' when A.status regexp 'hold' then 'Awaiting confirmation' else 'Awaiting order verification' end) end as 'Order_Process_status',
		case when A.billing_name like "%chandarana%" then "Chandarana" else A.order_business_program end as "new_order_business_program"
		FROM dwh_casedate_orders A		
		LEFT JOIN  KASHA_DWH.woocommerce_orders C on C.order_id=A.order_id and A.order_country=C.country collate utf8mb4_unicode_ci		
		LEFT JOIN KASHA_DWH.new_tradegecko_orders D ON D.order_number=A.order_number		
		LEFT JOIN  dwh_agent_data B on B.agent_id=C.agent_customer_id	
    		LEFT JOIN woocommerce_order_line_items E on E.order_id = A.order_id
		LEFT JOIN 
		(
			select distinct order_country ,billing_phone, count(order_id),
			case when count(order_id)>1 then 'Repeat' else 'New' end as  'New_Repeat'
			from dwh_casedate_orders
			where closed_revenue>0
			group by 1,2
		) as Ax on Ax.billing_phone=A.billing_phone and Ax.order_country=A.order_country
		where left(case_date,4)>='2020'
		and processing_total = 0
		-- and A.status NOT REGEXP ('trash|cancel|duplicate|failed|refuse|refund|auto-draft|returned|ghost-order')		
		and A.order_country in ('kenya','rwanda','Kenya')	
		and order_business_grouping regexp 'institutional'
	       ),
    
    mashup2 as (select *,
		case when payment_status = 'paid' then 'NULL' else (
			case when new_order_business_program = "Commercial" then DATE_ADD(ship_at, INTERVAL 14 DAY)
    			when new_order_business_program = "Chandarana" then DATE_ADD(ship_at, INTERVAL 60 DAY)
			when new_order_business_program = "Jaza Duka" then DATE_ADD(ship_at, INTERVAL 1 DAY)
			else DATE_ADD(ship_at, INTERVAL 24 HOUR) end) end as 'due_date'
		from mashup
		where new_order_business_program in ("Commercial", "Jaza Duka", "Chandarana")
	       ),
    
    partial_payment as (select a.order_number, a.payment_status, max(left(b.paid_at, 10)) as 'bulk_date_paid', sum(b.amount) as 'partial'
			from new_tradegecko_orders a
			left join tradegecko_payments b on b.invoice_id = a.invoice_ids COLLATE utf8mb4_0900_ai_ci
			group by 1
			)
    
    select *, STR_TO_DATE(due_date, '%Y-%m-%d') as due_dates, 
    case when A.name is null then G.product_name else A.name end as 'products_name',
    case when A.sales_agent is null then A.agent_name else F.sales_agent end as 'final_agent',
    case when A.quantity is null then G.quantity else A.quantity end as 'total_quantity',
    case when A.total is null then F.total else A.total end as 'totals', H.partial, H.payment_status,
    case when A.date_paid is null then H.bulk_date_paid else A.date_paid end as 'new_date_paid'
    from mashup2 A
    LEFT JOIN new_tradegecko_orders F on F.order_number = A.order_number
    LEFT JOIN new_tradegecko_order_line_items G on G.tg_order_id = F.id
    LEFT JOIN partial_payment H on H.order_number = A.order_id
    group by order_ind, order_id
    
    
    
    
    
