CREATE OR REPLACE TABLE bronze_order_details (
    raw        VARIANT,
    filename   STRING,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
