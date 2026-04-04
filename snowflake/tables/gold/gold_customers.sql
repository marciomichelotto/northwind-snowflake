-- Dimensão Customers (SCD Type 1)
CREATE OR REPLACE TABLE gold_dim_customers (
    customer_id   STRING PRIMARY KEY,
    company_name  STRING,
    contact_name  STRING,
    contact_title STRING,
    address       STRING,
    city          STRING,
    postal_code   STRING,
    country       STRING,
    phone         STRING,
    fax           STRING,
    hash_diff     STRING,
    updated_at    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
