-- Dimensão Products (SCD Type 1)
CREATE OR REPLACE TABLE gold_dim_products (
    product_id        STRING PRIMARY KEY,
    product_name      STRING,
    supplier_id       STRING,
    category_id       STRING,
    quantity_per_unit STRING,
    unit_price        FLOAT,
    units_in_stock    INTEGER,
    units_on_order    INTEGER,
    reorder_level     INTEGER,
    discontinued      STRING,
    hash_diff         STRING,
    updated_at        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
