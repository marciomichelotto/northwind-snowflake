CREATE OR REPLACE PROCEDURE load_bronze_products()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    TRUNCATE TABLE bronze_products;
    INSERT INTO bronze_products
        SELECT
            CAST($1 AS VARIANT)     AS raw,
            metadata$filename       AS filename,
            CURRENT_TIMESTAMP()     AS created_at
        FROM @POC.PUBLIC.NORTH/products (FILE_FORMAT => 'PARQUET_FORMAT');
    RETURN 'Load Bronze Products table successfully';
END;
$$;
