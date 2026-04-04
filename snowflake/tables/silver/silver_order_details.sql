CREATE OR REPLACE TABLE silver_order_details (
    order_id    STRING,
    product_id  STRING,
    unit_price  FLOAT,
    quantity    INTEGER,
    discount    FLOAT,
    created_at  TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
