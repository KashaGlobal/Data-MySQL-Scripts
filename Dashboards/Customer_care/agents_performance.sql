#Agents
select dad.agent_id,
case when dad.last_name is null then dad.first_name else concat(dad.first_name,' ',dad.last_name) end as 'Agent_name',
dad.phone, left(dad.created_at,10) as 'RegistrationDate',agent_status,
case when dad.country ='254' then 'Kenya' else 'Rwanda' end as Agent_Country, dad.Gender,dad.agent_location_name,
totalAmountExcludingTax, totalAmountIncludingTax,Customers_Served,Orders
from dwh_agent_data dad
left join(select salesperson,sum(totalAmountIncludingTax)totalAmountIncludingTax,sum(dpsi.totalAmountExcludingTax)totalAmountExcludingTax,
count(DISTINCT dpsi.customerNumber) as 'Customers_Served',
count(DISTINCT `number`)Orders
from dynamics_posted_sales_invoices dpsi
where YEAR(dpsi.invoiceDate) = YEAR(CURRENT_DATE())
AND MONTH(dpsi.invoiceDate) = MONTH(CURRENT_DATE())
and dpsi.shortcutDimension1Code in ('AGENTCONSUMER','AGENTBULK')
group by dpsi.salesperson)a on a.salesperson = dad.agent_id
where dad.agent_status =1 and dad.country='254'
group by dad.agent_id
order by totalAmountIncludingTax desc