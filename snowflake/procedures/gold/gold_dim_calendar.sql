-- Gerada, não sourced de silver — por isso TRUNCATE + INSERT, não MERGE com
-- hash_diff (não há "origem" pra comparar, o calendário é determinístico).
-- Cobre 1996-01-01 a 1998-12-31: janela real das ordens do Northwind
-- clássico (1996-07-04 a 1998-05-06), com folga de meio ano em cada ponta.
CREATE OR REPLACE PROCEDURE gold_dim_calendar()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    TRUNCATE TABLE gold_dim_calendar;
    INSERT INTO gold_dim_calendar
    WITH datas AS (
        SELECT DATEADD(day, SEQ4(), '1996-01-01'::DATE) AS full_date
        FROM TABLE(GENERATOR(ROWCOUNT => 1096))
    )
    SELECT
        TO_NUMBER(TO_CHAR(full_date, 'YYYYMMDD')) AS date_key,
        full_date,
        YEAR(full_date)                           AS year,
        QUARTER(full_date)                        AS quarter,
        MONTH(full_date)                          AS month,
        MONTHNAME(full_date)                      AS month_name,
        WEEKOFYEAR(full_date)                     AS week,
        DAY(full_date)                            AS day_of_month,
        DAYOFWEEK(full_date)                      AS day_of_week,
        DAYNAME(full_date)                        AS day_name,
        DAYOFWEEK(full_date) IN (0, 6)             AS is_weekend
    FROM datas
    WHERE full_date <= '1998-12-31'::DATE;
    RETURN 'Load Gold Dim Calendar table successfully';
END;
$$;
