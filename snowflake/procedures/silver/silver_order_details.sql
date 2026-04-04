CREATE OR REPLACE PROCEDURE load_silver_order_details()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    TRUNCATE TABLE silver_order_details;
    INSERT INTO silver_order_details
    SELECT
        COALESCE($1:"order_id"::STRING,   'N/A') AS order_id,
        COALESCE($1:"product_id"::STRING, 'N/A') AS product_id,
        COALESCE($1:"unit_price"::FLOAT,  0)     AS unit_price,
        COALESCE($1:"quantity"::INTEGER,  0)     AS quantity,
        COALESCE($1:"discount"::FLOAT,    0)     AS discount,
        CURRENT_TIMESTAMP()                      AS created_at
    FROM bronze_order_details;
    RETURN 'Load Silver Order Details table successfully';
END;
$$;
