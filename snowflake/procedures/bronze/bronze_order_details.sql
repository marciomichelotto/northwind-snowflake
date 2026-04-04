CREATE OR REPLACE PROCEDURE load_bronze_order_details()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    TRUNCATE TABLE bronze_order_details;
    INSERT INTO bronze_order_details
        SELECT
            CAST($1 AS VARIANT)     AS raw,
            metadata$filename       AS filename,
            CURRENT_TIMESTAMP()     AS created_at
        FROM @POC.PUBLIC.NORTH/order_details (FILE_FORMAT => 'PARQUET_FORMAT');
    RETURN 'Load Bronze Order Details table successfully';
END;
$$;
