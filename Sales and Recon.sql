
select 
max(tg.ship_at)ship_at, max(order_country)order_country,max(dco.order_id)order_id, 
max(dco.order_number)order_number, max(dco.billing_phone)billing_phone, max(dco.billing_name)billing_name,
max(dco.order_business_grouping)order_business_grouping,
avg(dco.order_total) as order_total,
avg(dco.order_usd_total) as order_usd_total,
avg(processing_total) as processing_total,
max(order_business_program)order_business_program,
case when tg.fulfillment_status='shipped' then avg(dco.order_total) else 0 end as ShippedRevenue,
avg(closed_revenue)closed_revenue,
avg(processing_usd_total)processing_usd_total,
avg(closed_usd_revenue)as closed_usd_revenue,
max(dco.status)Status
from dwh_casedate_orders dco 
left join woocommerce_order_line_items woli on dco.order_id = woli.order_id 
LEFT JOIN new_tradegecko_orders tg ON dco.order_number = tg.order_number
LEFT JOIN new_tradegecko_order_line_items tg_l ON tg.id = tg_l.tg_order_id
where left(tg.ship_at, 7)='2021-11' and order_country ='rwanda' ##and dco.order_number ='KE486733'
and dco.status  NOT REGEXP ('trash|cancel|duplicate|failed|refuse|refund|auto-draft|ghost|returned')
group by dco.order_id 





###Cohort Analysis
 select * from (          
 SELECT
 PERIOD_DIFF(DATE_FORMAT(max(dco.case_date), '%Y%m'), DATE_FORMAT(min(dco.case_date), '%Y%m')) AS Difference_In_Months,
 dco.order_business_grouping as Order_business_grouping,
 COUNT(DISTINCT dco.Order_ID) AS 'Count of Orders'
 FROM dwh_casedate_orders dco where left(case_date,4)='2021') as Orders
 GROUP BY Difference_In_Months, order_business_grouping
 
 
 select * from dwh_casedate_orders dco where order_id=5825969
 
 select * from woocommerce_order_line_items woli where order_id =5825969
 
 select * from new_dwh_KeyMetricQuantity_datasource ndkmqd 

 select * from woocommerce_coupons wc where order_id ='5831778'


