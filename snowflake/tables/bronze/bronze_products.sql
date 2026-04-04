CREATE OR REPLACE TABLE bronze_products (
    raw        VARIANT,
    filename   STRING,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
