CREATE OR REPLACE PROCEDURE load_bronze_customers()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    TRUNCATE TABLE bronze_customers;
    INSERT INTO bronze_customers
        SELECT
            CAST($1 AS VARIANT)     AS raw,
            metadata$filename       AS filename,
            CURRENT_TIMESTAMP()     AS created_at
        FROM @POC.PUBLIC.NORTH/customers (FILE_FORMAT => 'PARQUET_FORMAT');
    RETURN 'Load Bronze Customers table successfully';
END;
$$;
