CREATE DATABASE pr;

ALTER TABLE pr.credit_tr ADD COLUMN Purchase_date date;
ALTER TABLE pr.credit_tr ADD COLUMN Retu_rn_date date;
UPDATE pr.credit_tr
SET Purchase_date = STR_TO_DATE(Date, '%d-%m-%Y');
UPDATE pr.credit_tr
SET  Retu_rn_date = CASE WHEN Return_date = '' THEN NULL ELSE STR_TO_DATE(Return_date, '%d-%m-%Y') END;

ALTER TABLE pr.credit_tr DROP COLUMN Date;
ALTER TABLE pr.credit_tr DROP COLUMN Return_date;

INSERT INTO pr.credit_tr 
VALUES (NULL,266,	'COMPUTERS'	,'Used'	,'GCVNE',2143.08,	2098.08,'MS262','17:23:52',8417362,243355173,'REI','EI6774','Credit card',	74588	,0,'2014-07-03',NULL),
(NULL,710,'KITCHEN & DINING',	'New',	'RGMIK'	,663.82	,650.82,'ZG209'	,'17:41:01',	8042908,	596308320	,'Road Runner Sports','MS6579','Mobile carrier Billing'	,15559,0,'2014-04-26',NULL),
(NULL,956,'SHOES','Used','DYHNA',2800.18,2751.18,'GP301','22:07:02',6805351,352232665,'Gymboree','ZF8986',	'Prepaid card'	,16647,	0,'2014-01-25',NULL),
(NUll,539,'ELECTRONICS','New',	'OULOW',668.11,	621.11,	'VE748','00:19:14',3482483,494669159,'DFLOWERS','ZG2587'	,'Credit card',6175,0,'2014-01-28',NULL),
(NULL,300,	'COMPUTERS',	'Used','YXQFM',	2455.58,	2435.58,	'YM653','03:59:31',6302431,244787369,	'LOccitane'	,'GN4124',	'Credit card',	78902,	0,'2014-08-31',NULL);

UPDATE pr.credit_tr
SET Credit_card=99999 
WHERE Credit_card IS NULL;

-- selling price= price for those having no Coupon
UPDATE pr.credit_tr 
SET Selling_price=Price 
WHERE Coupon_ID ='';

UPDATE pr.credit_tr 
SET Coupon_ID =NULL 
WHERE Coupon_ID ='';

-- return_date should be after purchase_Date
SELECT * FROM pr.credit_tr WHERE Retu_rn_Date<Purchase_date; 
-- the records we get have purchase_date in december 2014 but return_date in january 2014, we simply make it jan 2015
UPDATE pr.credit_tr
SET Retu_rn_date= DATE_ADD(Retu_rn_date,INTERVAL 1 YEAR)
WHERE Retu_rn_date <Purchase_date;

-- discount of 5% where price=selling_price despite of presence of a coupon
UPDATE pr.credit_tr 
SET Selling_price= Selling_price*0.95
WHERE Price=Selling_price AND Coupon_ID is not null;


-- age<18 to be replaced
CREATE TEMPORARY TABLE temp_average_age
SELECT AVG(Age) AS average_age
FROM pr.customer_info
WHERE Age >= 18;

UPDATE pr.customer_info
SET Age=(SELECT average_age FROM temp_average_age )
WHERE Age<18;

	
CREATE TABLE combined AS 
SELECT* FROM pr.credit_tr  AS c  JOIN  pr.customer_info  AS i ON  c.Credit_card=i.C_ID;     

SELECT * FROM combined;
ALTER TABLE combined CHANGE COLUMN `Payment Method`Payment_method text;


-- spend in terms of product,state and payment method
SELECT P_CATEGORY, SUM(Selling_price) AS spend
FROM combined 
GROUP BY  P_CATEGORY
ORDER BY spend DESC;

SELECT State, SUM(Selling_price) AS spend
FROM combined
GROUP BY State
ORDER BY spend DESC;

SELECT Payment_method, SUM(Selling_price) AS spend
FROM combined
GROUP BY Payment_method
ORDER BY spend DESC;

-- highest 5 spending in these categories
SELECT P_CATEGORY, SUM(Selling_price) AS spend
FROM combined 
GROUP BY  P_CATEGORY
ORDER BY spend DESC
LIMIT 5;

SELECT State, SUM(Selling_price) AS spend
FROM combined
GROUP BY State
ORDER BY spend DESC
LIMIT 5;

SELECT Payment_method, SUM(Selling_price) AS spend
FROM combined
GROUP BY Payment_method
ORDER BY spend DESC 
LIMIT 5;

-- segmentation of customers based on their ages and gender
ALTER TABLE combined 
ADD  customer_segment varchar(50);

UPDATE combined
SET customer_segment = 
  CASE
    WHEN Gender = 'F' AND Age >= 18 AND Age <= 35 THEN 'Young Females'
    WHEN Gender = 'F' AND Age >= 36 AND Age <= 55 THEN 'Mid age Females'
    WHEN Gender = 'F' AND Age >= 56 AND Age <= 100 THEN 'Old Females'
    WHEN Gender = 'M' AND Age >= 18 AND Age <= 35 THEN 'Young Males'
    WHEN Gender = 'M' AND Age >= 36 AND Age <= 55 THEN 'Mid age Males'
    WHEN Gender = 'M' AND Age >= 56 AND Age <= 100 THEN 'Old Males'
    ELSE 'Other'
  END;

-- calculating discount
ALTER TABLE combined 
ADD discount float;
UPDATE combined
SET discount= Price-Selling_price;


-- customer_segment_expenditure
SELECT * FROM combined;
SELECT customer_segment,AVG(Selling_price) AS spend
FROM combined
GROUP BY customer_segment
ORDER BY spend DESC;

-- discount based on customer_segment
SELECT customer_segment,AVG(discount) as discount_given
FROM combined
GROUP BY customer_segment
ORDER BY discount_given DESC;

SELECT Payment_method , AVG(discount) AS disc_ount FROM combined
GROUP BY Payment_Method
ORDER BY disc_ount DESC;


-- return analysis

SELECT state, COUNT(*) as return_count
FROM combined 
WHERE Return_ind=1
GROUP BY state
ORDER BY return_count; 

SELECT customer_segment, COUNT(*) as return_count
FROM combined 
WHERE Return_ind=1
GROUP BY customer_segment
ORDER BY return_count;



SELECT discount FROM combined ORDER BY discount DESC;

SELECT
  CASE
    WHEN discount >= 0 AND discount <= 50 THEN '0-50'
    WHEN discount >= 51 AND discount <= 100 THEN '51-100'
    WHEN discount >= 101 AND discount <= 150 THEN '101-150'
    WHEN discount >= 151 AND discount <= 200 THEN '151-200'
    WHEN discount >= 201 AND discount <= 250 THEN '201-250'
    ELSE 'Unknown'
  END AS discount_range,
  COUNT(*) AS discount_count
FROM combined
WHERE Return_ind=1
GROUP BY discount_range; 

SELECT P_CATEGORY,COUNT(*) as return_count
FROM combined 
WHERE Return_ind=1
GROUP BY P_CATEGORY
ORDER BY return_count;

SELECT CONDTION ,COUNT(*) as return_count
FROM combined 
WHERE Return_ind=1
GROUP BY CONDTION
ORDER BY return_count;

-- to see that does more discount imply more purchases?
SELECT 
CASE WHEN discount>=0 AND discount<=50 THEN '0-50'
WHEN discount>=51 AND discount<=100 THEN '51-100'
WHEN discount>=101 AND discount<=150 THEN '101-150'
WHEN discount>=151 AND discount<=200 THEN '151-200'
WHEN discount>=201 AND discount<=250 THEN '201-250'
else 'other'
END as discount_range,
COUNT(*) AS nonreturn FROM combined 
WHERE Return_ind=0
GROUP BY discount_range;

-- to identify time period when purchases are maximum
ALTER TABLE combined CHANGE COLUMN `Time` Transaction_time TEXT;
SELECT 
CASE  
WHEN
STR_TO_DATE(Transaction_time, '%H:%i:%s') >= STR_TO_DATE('06:00:00', '%H:%i:%s')
         AND STR_TO_DATE(Transaction_time, '%H:%i:%s') <= STR_TO_DATE('13:00:00', '%H:%i:%s') THEN 'Daytime'
    WHEN STR_TO_DATE(Transaction_time, '%H:%i:%s') > STR_TO_DATE('13:00:00', '%H:%i:%s')
         AND STR_TO_DATE(Transaction_time, '%H:%i:%s') <= STR_TO_DATE('20:00:00', '%H:%i:%s') THEN 'Evening'
    WHEN STR_TO_DATE(Transaction_time, '%H:%i:%s') > STR_TO_DATE('20:00:00', '%H:%i:%s')
         AND STR_TO_DATE(Transaction_time, '%H:%i:%s') <= STR_TO_DATE('23:59:59', '%H:%i:%s') THEN 'Night'
    WHEN STR_TO_DATE(Transaction_time, '%H:%i:%s') >= STR_TO_DATE('00:00:00', '%H:%i:%s')
         AND STR_TO_DATE(Transaction_time, '%H:%i:%s') <= STR_TO_DATE('04:00:00', '%H:%i:%s') THEN 'Mid Night'
    WHEN STR_TO_DATE(Transaction_time, '%H:%i:%s') > STR_TO_DATE('04:00:00', '%H:%i:%s')
         AND STR_TO_DATE(Transaction_time, '%H:%i:%s') < STR_TO_DATE('06:00:00', '%H:%i:%s') THEN 'Early Morning'
    ELSE 'Unknown'
  END AS time_interval,
  COUNT(*) AS purchase_count
FROM combined
GROUP BY time_interval
ORDER BY purchase_count DESC;