CREATE OR REPLACE PROCEDURE load_silver_customers()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    TRUNCATE TABLE silver_customers;
    INSERT INTO silver_customers
    SELECT
        COALESCE(UPPER($1:"customer_id"::STRING),   'N/A') AS customer_id,
        COALESCE(UPPER($1:"company_name"::STRING),  'N/A') AS company_name,
        COALESCE(UPPER($1:"contact_name"::STRING),  'N/A') AS contact_name,
        COALESCE(UPPER($1:"contact_title"::STRING), 'N/A') AS contact_title,
        COALESCE(UPPER($1:"address"::STRING),       'N/A') AS address,
        COALESCE(UPPER($1:"city"::STRING),          'N/A') AS city,
        COALESCE(UPPER($1:"postal_code"::STRING),   'N/A') AS postal_code,
        COALESCE(UPPER($1:"country"::STRING),       'N/A') AS country,
        COALESCE(UPPER($1:"phone"::STRING),         'N/A') AS phone,
        COALESCE(UPPER($1:"fax"::STRING),           'N/A') AS fax,
        CURRENT_TIMESTAMP()                                 AS created_at
    FROM bronze_customers;
    RETURN 'Load Silver Customers table successfully';
END;
$$;
