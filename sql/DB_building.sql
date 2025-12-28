/* ============================================================
   Sales Analytics Database Build
   This script creates dimension, staging, and fact tables,
   loads sales data from CSV files, and ensures clean inserts
   by deduplicating records for reliable BI reporting.
   ============================================================ */

DROP DATABASE IF EXISTS sales_db;
CREATE DATABASE sales_db;
USE sales_db;


/* ===================== DIMENSION TABLES ===================== */

CREATE TABLE dim_product (
    product_id VARCHAR(20) PRIMARY KEY,
    product_name VARCHAR(255),
    price_band VARCHAR(20)
);

CREATE TABLE dim_city (
    city_id INT PRIMARY KEY,
    city_name VARCHAR(100)
);

CREATE TABLE dim_date (
    date_id INT PRIMARY KEY,
    order_date DATE,
    order_year INT,
    order_month INT,
    order_hour INT,
    time_of_day VARCHAR(20)
);


/* ===================== FACT TABLE ===================== */

CREATE TABLE fact_sales (
    order_id INT,
    product_id VARCHAR(20),
    date_id INT,
    city_id INT,
    quantity INT,
    price DECIMAL(10,2),
    sales DECIMAL(12,2),
    is_valid_record TINYINT(1) NOT NULL,

    PRIMARY KEY (order_id, product_id)
);


/* ===================== STAGING ===================== */

CREATE TABLE stage_dim_product (
    product_id VARCHAR(20),
    product VARCHAR(255),
    price_band VARCHAR(20)
);

CREATE TABLE stage_dim_city (
    city VARCHAR(100),
    city_id INT
);

CREATE TABLE stage_dim_date (
    order_date DATE,
    order_year INT,
    order_month INT,
    order_hour INT,
    time_of_day VARCHAR(20),
    date_id INT
);

CREATE TABLE stage_fact_sales (
    order_id INT,
    product_id VARCHAR(20),
    date_id INT,
    city_id INT,
    quantity INT,
    price DECIMAL(10,2),
    sales DECIMAL(12,2),
    is_valid_record TINYINT(1)
);


/* ===================== LOAD CSV FILES ===================== */

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_product.csv'
INTO TABLE stage_dim_product
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_city.csv'
INTO TABLE stage_dim_city
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_date.csv'
INTO TABLE stage_dim_date
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/fact_sales.csv'
INTO TABLE stage_fact_sales
FIELDS TERMINATED BY ','
IGNORE 1 ROWS
(order_id, product_id, date_id, city_id, quantity, price, sales, @flag)
SET is_valid_record =
    CASE
        WHEN LOWER(TRIM(@flag)) = 'true'  THEN 1
        WHEN LOWER(TRIM(@flag)) = 'false' THEN 0
        ELSE 1
    END;


/* ===================== LOAD DIMENSIONS ===================== */

INSERT INTO dim_product
SELECT DISTINCT product_id, product, price_band
FROM stage_dim_product;

INSERT INTO dim_city
SELECT DISTINCT city_id, city
FROM stage_dim_city;

INSERT INTO dim_date
SELECT DISTINCT date_id, order_date, order_year, order_month, order_hour, time_of_day
FROM stage_dim_date;


/* ===================== LOAD FACT ===================== */
INSERT INTO fact_sales
SELECT
    order_id,
    product_id,
    date_id,
    city_id,
    quantity,
    price,
    sales,
    is_valid_record
FROM (
    SELECT
        order_id,
        product_id,
        date_id,
        city_id,
        quantity,
        price,
        sales,
        is_valid_record,
        ROW_NUMBER() OVER (PARTITION BY order_id, product_id ORDER BY order_id) AS rn
    FROM stage_fact_sales
) t
WHERE rn = 1;




