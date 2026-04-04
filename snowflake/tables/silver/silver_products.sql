CREATE OR REPLACE TABLE silver_products (
    product_id        STRING,
    product_name      STRING,
    supplier_id       STRING,
    category_id       STRING,
    quantity_per_unit STRING,
    unit_price        FLOAT,
    units_in_stock    INTEGER,
    units_on_order    INTEGER,
    reorder_level     INTEGER,
    discontinued      STRING,
    created_at        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
