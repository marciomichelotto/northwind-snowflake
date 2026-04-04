CREATE OR REPLACE TABLE silver_orders (
    order_id        STRING,
    customer_id     STRING,
    employee_id     STRING,
    order_date      DATE,
    required_date   DATE,
    shipped_date    DATE,
    ship_via        STRING,
    freight         FLOAT,
    ship_name       STRING,
    ship_address    STRING,
    ship_city       STRING,
    ship_postal_code STRING,
    ship_country    STRING,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
