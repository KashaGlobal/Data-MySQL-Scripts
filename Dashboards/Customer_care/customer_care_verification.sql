/*  This code checks the status of orders and their creation date and their verification dates
    It takes the difference between creation and verification
    Additionally, it classifies an order as either overnight or not overnight
*/
with mashup as (
    select wo.status, replace(wo.date_created, 'T', ' ') as 'order_creation_date', max(kwc.comment_date) as 'verified_date', 
    kwc.comment_author as 'verified_by', HOUR(replace(wo.date_created, 'T', ' ')) as creation_hour,
    case when HOUR(replace(wo.date_created, 'T', ' ')) between 8 and 19 then "not overnight" else "overnight" end as 'order_hour', 
    timestampdiff(SECOND, replace(wo.date_created, 'T', ' '), max(kwc.comment_date)) as time_seconds,
    round((timestampdiff(SECOND, replace(wo.date_created, 'T', ' '), max(kwc.comment_date)))/60, 2) as timelapse
    from woocommerce_orders wo
    left join ke_wp_comments kwc on wo.order_id = kwc.comment_post_ID
    where left(wo.date_created , 4) > '2021'
    and kwc.comment_author != "WooCommerce"
    and kwc.comment_type = 'order_note'
    group by comment_post_ID
    )
select status, order_creation_date, verified_date, verified_by, creation_hour, order_hour, timelapse,
case when order_hour = 'overnight' then 'overnight' else (
case when timelapse < 1.00 then 'Less than 1 min'
when timelapse between 1.00 and 3.00 then 'Less than 3 mins'
when timelapse between 3.01 and 5.00 then 'Less than 5 mins'
when timelapse between 5.01 and 15.00 then 'Less than 15 mins'
when timelapse between 15.01 and 30.00 then 'Less than 30 mins'
when timelapse between 30.01 and 60.00 then 'Less than 1 hour'
when timelapse between 60.01 and 240.00 then 'Less than 4 hours'
else 'More than 4 hours' end) end as 'ageing'
from mashup