CREATE OR REPLACE TABLE silver_customers (
    customer_id   STRING,
    company_name  STRING,
    contact_name  STRING,
    contact_title STRING,
    address       STRING,
    city          STRING,
    postal_code   STRING,
    country       STRING,
    phone         STRING,
    fax           STRING,
    created_at    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
