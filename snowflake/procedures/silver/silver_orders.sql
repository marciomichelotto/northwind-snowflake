CREATE OR REPLACE PROCEDURE load_silver_orders()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    TRUNCATE TABLE silver_orders;
    INSERT INTO silver_orders
    SELECT
        COALESCE($1:"order_id"::STRING,          'N/A')  AS order_id,
        COALESCE($1:"customer_id"::STRING,       'N/A')  AS customer_id,
        COALESCE($1:"employee_id"::STRING,       'N/A')  AS employee_id,
        TRY_TO_DATE($1:"order_date"::STRING)             AS order_date,
        TRY_TO_DATE($1:"required_date"::STRING)          AS required_date,
        TRY_TO_DATE($1:"shipped_date"::STRING)           AS shipped_date,
        COALESCE($1:"ship_via"::STRING,          'N/A')  AS ship_via,
        COALESCE($1:"freight"::FLOAT,            0)      AS freight,
        COALESCE(UPPER($1:"ship_name"::STRING),  'N/A')  AS ship_name,
        COALESCE(UPPER($1:"ship_address"::STRING),'N/A') AS ship_address,
        COALESCE(UPPER($1:"ship_city"::STRING),  'N/A')  AS ship_city,
        COALESCE($1:"ship_postal_code"::STRING,  'N/A')  AS ship_postal_code,
        COALESCE(UPPER($1:"ship_country"::STRING),'N/A') AS ship_country,
        CURRENT_TIMESTAMP()                              AS created_at
    FROM bronze_orders;
    RETURN 'Load Silver Orders table successfully';
END;
$$;
