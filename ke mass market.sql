	/* 1. ONLY GET NOTES FOR ORDERS FROM USSD*/		
	DROP TABLE IF EXISTS TEMP_USSD_MASSMARKET_ORDERS ;		
	CREATE TEMPORARY TABLE TEMP_USSD_MASSMARKET_ORDERS		
	SELECT 		
	B.country,		
		B.order_id,	
	    B.order_number,		
		B.status,	
	    replace(date_created, 'T', ' ') as 'Order_Creation_date',		
	    left(date_created,10) as 'Cleaned_order_creation_date',		
	    replace(B.date_paid, 'T', ' ') as 'Date_Paid',		
	    B.payment_method,		
	    B.payment_method_title,		
		replace(B.date_completed, 'T', ' ') as 'Date_Completed',	
		CASE WHEN B.billing_email regexp 'customer' THEN 'Customer_Care' 	
        ELSE created_via 			
        END AS 'created_via',			
		B.billing_first_name,	
		B.billing_phone,	
		B.agent_customer_id,	
	    concat(E.first_name,' ',E.last_name) as 'Agent_name',		
	    E.phone as 'Agent_phone',		
	    E.agent_location_name as 'Agent_Location',		
		CASE WHEN B.meta_data REGEXP 'mpesa_callback_ip' THEN 1	
		ELSE 0	
		END AS 'Payment_push_trigger',	
        CASE WHEN B.meta_data REGEXP 'The service request is processed successfully' THEN 1			
        ELSE 0			
        END AS 'Sucessful_STK_Push',			
	    C.order_business_grouping, 		
	    D.fulfillment_status,		
	    D.invoice_status,		
	    D.issued_at,		
	    D.ship_at,		
	    D.packed_status,		
	    D.payment_status,		
	    return_status,		
	    returning_status,		
	    D.status as 'TG_Status',		
        Case when B.status regexp 'cancelledduplicat|ordercanceledt597|cancelled|completed' then '' else (			
			Case when (fulfillment_status='shipped' or B.status regexp 'delivered|dispatch') then 'Out on delivery' when (B.status regexp 'verified|verified846' or  fulfillment_status='unshipped') then 'Awaiting fulfillment' when B.status regexp ('hold|subscriptionca429') then 'Awaiting confirmation' else 'Awaiting order verification' end) end as 'Order_Process_status',
     processing_total			
	FROM  woocommerce_orders B		
	LEFT JOIN dwh_casedate_orders C on C.order_id=B.order_id and C.order_country=B.country   collate utf8mb4_unicode_ci		
	LEFT JOIN new_tradegecko_orders D on D.order_number=B.order_number		
	left join dwh_agent_data E on E.agent_id=B.agent_customer_id and  E.country=254		
	WHERE  (agent_customer_id>0 OR created_via='rest_api'or order_business_grouping in('Agent_Delivered_Institutional','Agent_Delivered','Non_Agent_Delivered'))		
	AND LEFT(date_created,10)>='2021-11-01'		
	AND B.country='kenya';		
			
	/* 2. ONLY GET NOTES FOR ORDERS FROM USSD*/		
	DROP TABLE IF EXISTS TEMP_order_notes2 ;		
	CREATE TEMPORARY TABLE TEMP_order_notes2 		
	(SELECT 	max(comment_date) as 'Verified_date',	
	    comment_post_ID as note_order_id,		
		comment_author as 'verified_by'	
	 FROM ke_wp_comments 		
	 WHERE comment_type = 'order_note' AND 		
		   comment_agent = 'WooCommerce' AND 	
	       comment_approved = 1 AND 		
	       comment_content LIKE '%to verified%' AND		
	       comment_post_ID IN (SELECT order_id from TEMP_USSD_MASSMARKET_ORDERS WHERE order_id IS NOT NULL AND order_id <> '')		
    GROUP BY comment_post_ID,comment_author			
    );			
			
			
	-- 4. PUTTING ALL THINGS TOGETHER		
	DROP TABLE IF EXISTS DWH_Order_status_table;		
	CREATE TABLE DWH_Order_status_table		
		SELECT DISTINCT	
			
		A.*,	
	    B.*		
			
	    FROM TEMP_USSD_MASSMARKET_ORDERS A 		
	    LEFT JOIN TEMP_order_notes2 B ON A.order_id = B.note_order_id; 		
	    		
	SELECT * FROM DWH_Order_status_table;		
			
	/*SELECT DISTINCT msisdn,session_id,Created_at,country,Code_Extension,Agent_customer_registration,order_id,order_number,status,Order_Creation_date,Date_Paid,payment_method,payment_method_title,Date_Completed,created_via,billing_first_name,billing_phone,agent_customer_id,Payment_push_trigger,order_business_grouping,fulfillment_status,invoice_status,issued_at,ship_at,packed_status,payment_status,return_status,returning_status,TG_Status,note_order_id,verified_by,Verified_date		
	FROM DWH_Order_status_table;*/		
	    		
