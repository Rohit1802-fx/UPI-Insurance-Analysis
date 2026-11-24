Create database Upi_anlytics;
Use Upi_anlytics;

show tables;

describe customer_feedback_surveys;
describe customer_master;
describe device_info;
describe fraud_alert_history;
describe merchant_info;
describe upi_account_details;
describe upi_transaction_history;


-- customer_feedback_surveys:-

-- Convert TRUE/FALSE values into 1/0 for BOOLEAN data type compatibility 

ALTER TABLE customer_feedback_surveys
MODIFY resolved VARCHAR(10);

Set SQL_Safe_Updates = 0;
Update customer_feedback_surveys
Set resolved = Case
    When Lower(resolved) = 'true' Then '1'
    When Lower(resolved) = 'false' Then '0'
    Else null
End
where feedback_id is not null;

Alter table customer_feedback_surveys
   Modify feedback_id varchar(20) not null,
   Modify customer_id varchar(50) not null,
   Modify date_submitted date not null,
   Modify feedback_text text not null,
   Modify satisfaction_score int not null,
   Modify issue_type varchar(25) not null,
   Modify resolved  boolean not null,
   Add Primary key (feedback_id);
 
 select count(*) from customer_feedback_surveys;
 
 
 
-- customer_master

ALTER TABLE customer_master
MODIFY is_business_user varchar(10);

Update customer_master
Set is_business_user = Case
    When lower(is_business_user)= 'true' Then '1'
    when lower(is_business_user)= 'false' Then '0'
    Else null
End
where customer_id is not null;

Alter table customer_master
    Modify customer_id varchar(15) not null,
    Modify full_name varchar(30) not null,
    Modify mobile_number varchar(10) not null,
    Modify age tinyint not null,
    Modify gender varchar(15) not null,
    Modify region varchar(50) not null,
    Modify date_joined date not null,
    Modify is_business_user boolean not null,
    Modify risk_score decimal(3,3) not null,
    Add Primary key (customer_id);
    
    
 
-- device_info

Alter table device_info
Modify is_rooted varchar(10);

Update device_info
Set is_rooted = Case
    When lower(is_rooted) = 'True' then '1' 
    When lower(is_rooted) = 'False' then '0'
    Else null
End 
where device_id is not null;

ALTER TABLE device_info
    MODIFY device_id VARCHAR(15) NOT NULL,
    MODIFY customer_id VARCHAR(15) NOT NULL,
    MODIFY device_type VARCHAR(20) NOT NULL,
    MODIFY app_version VARCHAR(15) NOT NULL,
    MODIFY is_rooted BOOLEAN NOT NULL,
    MODIFY last_active DATETIME(6) NOT NULL,
    ADD PRIMARY KEY (device_id);   
 
 
 
 
-- fraud_alert_history

Alter table fraud_alert_history
Modify resolved varchar(10);
Set Sql_safe_updates=0;

Update fraud_alert_history
set resolved = Case
    when lower(resolved) = 'true' then '1'
    when lower(resolved) = 'false' then'0'
    Else null
End
where alert_id is not null;

-- resolution_date contains an empty string ('') that MySQL can’t convert to DATETIME. Convert empty strings to NULL before changing the column type.

ALTER TABLE fraud_alert_history
MODIFY alert_type VARCHAR(50);

UPDATE fraud_alert_history
SET resolution_date = NULL
WHERE resolution_date = '';
UPDATE fraud_alert_history
SET resolution_date = NULL
WHERE alert_id IS NOT NULL
  AND resolution_date = '';

Alter table fraud_alert_history
    Modify  alert_id varchar(20) not null,
    MOdify transaction_id varchar(20) not null,
    Modify alert_type varchar(20) not null,
    Modify alert_date datetime(6) not null,
    Modify resolved boolean not null,
    Modify resolution_date datetime(6),
    Modify remarks text not null;

-- The resolved column contains NULL values after data cleaning, which prevents conversion to a BOOLEAN NOT NULL field.
-- Replace NULL values with 0 before changing the data type.

Select Distinct resolved
from fraud_alert_history;

Select resolved, count(*)
from fraud_alert_history
group by resolved;

ALTER TABLE fraud_alert_history
MODIFY resolved BOOLEAN NOT NULL;

SELECT resolved, LENGTH(resolved)
FROM fraud_alert_history
LIMIT 20;

UPDATE fraud_alert_history
SET resolved = 0
WHERE resolved IS NULL;

SELECT resolved, COUNT(*)
FROM fraud_alert_history
GROUP BY resolved;

ALTER TABLE fraud_alert_history
MODIFY COLUMN resolved TINYINT(1) NOT NULL;

Describe fraud_alert_history;



-- merchant_info

Alter table merchant_info 
    Modify merchant_id varchar(12) not null,
    Modify merchant_name text not null,
    Modify merchant_type text not null,
    Modify region text not null,
    Modify onboard_date date not null,
    Modify risk_score decimal(3,2) not null,
    Add Primary key(merchant_id);
    
    
    
 -- upi_account_details:-
 
Alter table upi_account_details
    Modify upi_id varchar(20) not null,
    Modify customer_id varchar(10) not null,
    Modify bank_name text not null,
    Modify account_type varchar(20) not null,
    Modify date_added date not null,
    Modify status text not null,
    Add Primary Key(upi_id);



-- upi_transcation_details:-

Alter table upi_transaction_history
    Modify  transaction_id varchar(20) not null,
    Modify upi_id varchar(20) not null,
    Modify customer_id varchar(20) not null,
    Modify timestamp datetime(6) not null,
    Modify amount decimal(10,2) not null,
    Modify transaction_type varchar(25) not null,
    Modify merchant_id varchar(20),
    Modify counterparty_upi varchar(20) not null,
    Modify status text not null,
    Modify device_id varchar(20) not null,
    Modify device_type varchar(25) not null,
    Modify channel varchar(20) not null,
    Modify fraud_flag text not null,
    Modify reversal_flag text not null,
    Modify failure_reason varchar(25) not null,
    Add Primary key (transaction_id);
    
SELECT
    MIN(`timestamp`) AS first_transaction,
    MAX(`timestamp`) AS last_transaction,
    MIN(amount) AS smallest_amount,
    MAX(amount) AS largest_amount
FROM upi_transaction_history;


-- Duplicate transaction IDs
-- for upi_transaction_history
 
select transaction_id, count(*) as copies 
from upi_transaction_history
Group by transaction_id
having count(*) > 1;

-- Missing essential values

select
    sum(transaction_id is null or
transaction_id='') as
Missing_transaction_id,
    sum(timestamp is null) as 
missing_timestamp,
    sum(amount is null) as missing_amount
from upi_transaction_history;

-- Unexpected amounts

select *
from upi_transaction_history
where amount<0;

-- status and transaction type values to review

select status,count(*) as rows_found
from upi_transaction_history
group by status 
order by rows_found DESC;  

SELECT COUNT(*) AS unmatched_customers
FROM upi_transaction_history t
LEFT JOIN customer_master c
    ON t.customer_id = c.customer_id
WHERE c.customer_id IS NULL;



-- For Customer Master
-- Find duplicate customer files
Select customer_id, count(*) as copies
from customer_master
Group By customer_id
Having count(*) > 1;

-- Check for missing important customer details
Select
    sum(customer_id is null or customer_id='') as missing_customer_id,
    sum(date_joined is null) as missing_join_date,
    sum(age is null) as missing_age 
 from customer_master;   



--  Upi_account_details
-- Find deuplicate Upi IDs

Select upi_id, count(*) as copies
from upi_account_details
group by upi_id
having count(*) > 1;

-- check for missing account details
select
    sum(upi_id is null or upi_id = '') as missing_upi_id,
    sum(customer_id is null or customer_id = '') as missing_customer_id,
    sum(bank_name is null or bank_name = '') as missing_bank_name
from upi_account_details;
    
    
    
-- Device Table
-- Find duplicate device IDs
Select device_id, count(*) as copies
from device_info
Group by device_id
Having count(*) > 1;  
    
-- Check for missing device details
Select
    sum(device_id is null or device_id = '') as missing_device_id,
    sum(customer_id is null or customer_id = '') as missing_customer_id,
    sum(last_active is null) as missing_last_active
from device_info;
    
    
-- Merchant info
-- find duplicate merchants IDs
select merchant_id, count(*) as copies
from merchant_info
group by merchant_id
having count(*) > 1;  
    
-- Checks for missing merchant details
select
    sum(merchant_id is null or merchant_id = '') as missing_merchant_id,
    sum(merchant_name is null or merchant_name= '') as missing_merchant_name,
    sum(merchant_type is null or merchant_type = '') as missing_merchnat_type
from merchant_info;


-- Fraud alert history
-- find duplicate alert IDs

 select alert_id, count(*) as copies
 from fraud_alert_history
 group by alert_id
 having count(*) > 1;
 
 -- check for missing alert details
 select
     sum(alert_id is null or alert_id = '') as missing_alert_id,
     sum(transaction_id is null or transaction_id = '') as missing_transaction_id,
     sum(alert_date is null) as missing_alert_date
from fraud_alert_history;


-- Customer feedback surveys
-- duplicate feedback ids
select feedback_id, count(*) as copies
from customer_feedback_surveys
group by feedback_id
Having count(*) > 1;  
 
 -- missing feedback details
 select
     sum(feedback_id is null or feedback_id = '') as missing_feedback_id,
     sum(customer_id is null or customer_id = '') as customer_missing_id,
     sum(date_submitted is null) as missing_date_submitted,
     sum(satisfaction_score is null) as missing_satisfaction_score
from customer_feedback_surveys;
 
 
-- How many transaction records are in the table?
  SELECT count(*) AS total_transactions
FROM upi_transaction_history;
 
-- What is the total value and average value of transactions?
 Select
     sum(amount) as Total_amount,
     avg(amount) as Average_amount
from upi_transaction_history;

-- How many transactions succeeded, failed, or have another status?
Select status,
    count(*) as transaction_count
from upi_transaction_history
group by status
order by transaction_count DESC;

-- How many transactions happened in each month?
select
    date_format(`timestamp`, '%Y-%m') as transaction_month,
    count(*) as transaction_count,
    sum(amount) as total_transaction_amount
from upi_transaction_history
group by date_format(`timestamp`, '%Y-%m')
order by transaction_month;

-- Which transaction types are most common, and what is their total amount?
select transaction_type,
    count(*) as Total_transaction_count,
    sum(amount) as Total_transaction_amount
from upi_transaction_history
group by transaction_type
order by Total_transaction_count DESC;
 
-- Which channels are used most often?
select channel,
    count(*) as total_channel_count,
    sum(amount) as Total_channel
from upi_transaction_history
group by channel
order by total_channel_count DESC;
 
-- What reasons are recorded for failed transactions?
 select failure_reason,
     count(*) as Total_failed_count
from upi_transaction_history
where lower(status) = 'failed'
group by failure_reason
order by Total_failed_count DESC;
 
-- How many records have the fraud flag set? 
select fraud_flag,
    count(*) as total_fraud_flag
from upi_transaction_history
group by fraud_flag;
 
-- How many records have the reversal flag set?
Select reversal_flag,
    count(*) as total_reversal_flag
from upi_transaction_history
group by reversal_flag;
 
-- How many transactions and how much transaction value are associated with each customer region?
select m.region,
    count(*) as transcation_count,
    sum(t.amount) as Total_transaction_amount
from upi_transaction_history as t join
customer_master as m
    on t.customer_id = m.customer_id
Group by m.region
order by transcation_count DESC;
 
-- Which merchant types have the most transaction activity?
select 
    i.merchant_type,
    count(*) as transaction_count,
    sum(t.amount) as transaction_amount
from upi_transaction_history as t join
merchant_info as i
    on t.merchant_id = i.merchant_id
group by i.merchant_type
order by transaction_count DESC;
 
-- What alert types are recorded, and how many are resolved?
select
    alert_type,
    resolved,
    count(*) as recorded
from fraud_alert_history
group by alert_type, resolved
order by recorded DESC;
 
-- What is the average satisfaction score for each issue type?
select
    issue_type,
    count(*) as total_issue,
    avg(satisfaction_score) as Avg_satisfaction
from customer_feedback_surveys
group by issue_type
order by Avg_satisfaction;
 
 
 
-- Month over month transaction growth 
WITH monthly_totals AS (
    SELECT
        DATE_FORMAT(`timestamp`, '%Y-%m') AS transaction_month,
        COUNT(*) AS transaction_count,
        SUM(amount) AS transaction_amount
    FROM upi_transaction_history
    GROUP BY DATE_FORMAT(`timestamp`, '%Y-%m')
),
monthly_comparison AS (
    SELECT
        transaction_month,
        transaction_count,
        transaction_amount,
        LAG(transaction_amount) OVER (
            ORDER BY transaction_month
        ) AS previous_month_amount
    FROM monthly_totals
)
SELECT
    transaction_month,
    transaction_count,
    transaction_amount,
    previous_month_amount,
    ROUND(
        100 * (transaction_amount - previous_month_amount)
        / NULLIF(previous_month_amount, 0),
        2
    ) AS amount_change_percent
FROM monthly_comparison
ORDER BY transaction_month;

-- Compare channel failure rates
WITH channel_totals AS (
    SELECT
        channel,
        COUNT(*) AS transaction_count,
        SUM(CASE WHEN LOWER(status) = 'failed' THEN 1 ELSE 0 END)
            AS failed_count
    FROM upi_transaction_history
    GROUP BY channel
),
channel_rates AS (
    SELECT
        channel,
        transaction_count,
        failed_count,
        ROUND(100 * failed_count / transaction_count, 2)
            AS failure_rate_percent
    FROM channel_totals
)
SELECT
    channel,
    transaction_count,
    failed_count,
    failure_rate_percent,
    RANK() OVER (ORDER BY failure_rate_percent DESC) AS failure_rate_rank
FROM channel_rates
ORDER BY failure_rate_rank;

-- Rank customers by transaction value and flagged rate

WITH customer_totals AS (
    SELECT
        customer_id,
        COUNT(*) AS transaction_count,
        SUM(amount) AS total_transaction_amount,
        SUM(CASE WHEN fraud_flag = 1 THEN 1 ELSE 0 END) AS flagged_count
    FROM upi_transaction_history
    GROUP BY customer_id
),
customer_metrics AS (
    SELECT
        customer_id,
        transaction_count,
        total_transaction_amount,
        flagged_count,
        ROUND(100 * flagged_count / transaction_count, 2)
            AS flagged_rate_percent
    FROM customer_totals
)
SELECT
    customer_id,
    transaction_count,
    total_transaction_amount,
    flagged_count,
    flagged_rate_percent,
    DENSE_RANK() OVER (
        ORDER BY total_transaction_amount DESC
    ) AS transaction_value_rank
FROM customer_metrics
ORDER BY transaction_value_rank
LIMIT 20;


-- the hours with the most failed transactions
SELECT
    HOUR(`timestamp`) AS transaction_hour,
    COUNT(*) AS transaction_count,
    SUM(CASE WHEN LOWER(status) = 'failed' THEN 1 ELSE 0 END) AS failed_count,
    ROUND(
        100 * SUM(CASE WHEN LOWER(status) = 'failed' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS failure_rate_percent
FROM upi_transaction_history
GROUP BY HOUR(`timestamp`)
ORDER BY failure_rate_percent DESC;

