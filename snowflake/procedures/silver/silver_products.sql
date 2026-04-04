CREATE OR REPLACE PROCEDURE load_silver_products()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    TRUNCATE TABLE silver_products;
    INSERT INTO silver_products
    SELECT
        COALESCE($1:"product_id"::STRING,           'N/A') AS product_id,
        COALESCE(UPPER($1:"product_name"::STRING),  'N/A') AS product_name,
        COALESCE($1:"supplier_id"::STRING,          'N/A') AS supplier_id,
        COALESCE($1:"category_id"::STRING,          'N/A') AS category_id,
        COALESCE($1:"quantity_per_unit"::STRING,    'N/A') AS quantity_per_unit,
        COALESCE($1:"unit_price"::FLOAT,            0)     AS unit_price,
        COALESCE($1:"units_in_stock"::INTEGER,      0)     AS units_in_stock,
        COALESCE($1:"units_on_order"::INTEGER,      0)     AS units_on_order,
        COALESCE($1:"reorder_level"::INTEGER,       0)     AS reorder_level,
        COALESCE(UPPER($1:"discontinued"::STRING),  'N/A') AS discontinued,
        CURRENT_TIMESTAMP()                                AS created_at
    FROM bronze_products;
    RETURN 'Load Silver Products table successfully';
END;
$$;
