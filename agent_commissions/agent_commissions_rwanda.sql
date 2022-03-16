#All sales Query	
	with all_sales as (SELECT 	
	A.case_date,
	C.ship_at,
    LEFT(B.created_at,10) as 'Order_creation_date',
	A.order_country,	
	A.order_id,	
    A.order_number,
	RIGHT(TRIM(REPLACE(REPLACE(REPLACE(REPLACE(A.billing_phone,'+', ''),' ',''),'-',''),')','')), 9) as billing_phone,	
	A.billing_name,	
	A.order_business_grouping,	
	A.order_total,	
	A.order_usd_total,	
	A.order_business_program,	
	A.processing_total,	
	A.closed_revenue,	
	A.processing_usd_total,	
	A.closed_usd_revenue,	
	A.status,	
	CASE WHEN B.billing_email regexp 'customer' THEN 'Customer_Care' 
	ELSE created_via 		
	END AS 'created_via',		
	left(C.ship_at,7) as 'Revenue_month',	
	agent_customer_id,
    B.customer_lead
	    	
	FROM dwh_casedate_orders A	
	left join KASHA_DWH.woocommerce_orders B 	on  B.order_id=A.order_id AND A.order_country = B.country collate utf8mb4_unicode_ci
    left join KASHA_DWH.new_tradegecko_orders C ON C.order_number=A.order_number
	where left(C.ship_at,4) in ('2021', '2022')	
    and A.status  NOT REGEXP ('trash|cancel|duplicate|failed|refuse|refund|auto-draft|ghost|returned')
	and A.order_country in ('kenya','rwanda')
    )

    select b.agent_id as 'Agent ID', b.agent_location_name as Location,
    case when last_name is null then first_name else concat(first_name,' ',last_name) end as 'Agent Name', b.phone as 'Agent Phone', sum(a.closed_revenue) as 'Closed Revenue', 
    SUM(CASE WHEN  order_business_grouping = 'Agent_Delivered' THEN a.closed_revenue END) as 'Consumer Revenue', 
    SUM(CASE WHEN  order_business_grouping = 'Agent_Delivered_Institutional' THEN a.closed_revenue END) as 'Institutional Revenue', 
    round((sum(a.closed_revenue)/count(a.distinct order_id)), 2) as 'Average Basket Value', COUNT(distinct a.billing_phone) as 'Customers Served', count(distinct a.order_id) as 'Order Count',
    COUNT(case when order_business_grouping = 'Agent_Delivered' THEN a.order_id END) as 'Consumer Order',
    COUNT(case when order_business_grouping = 'Agent_Delivered_Institutional' THEN a.order_id END) as 'Institutional Order'
    from all_sales as a
    left join dwh_agent_data as b on b.agent_id = a.agent_customer_id
    where a.order_business_grouping in ("Agent_Delivered", "Agent_Delivered_Institutional", "Corporate_Institutional")
    and left(a.case_date, 7) in ("2022-03")
    and a.status in ("completed")
    and order_country = "rwanda"
    group by 1
