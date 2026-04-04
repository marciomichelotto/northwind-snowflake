-- Dimensão Calendário (gerada via procedure)
-- 🔜 Em desenvolvimento
CREATE OR REPLACE TABLE gold_dim_calendar (
    date_key      INTEGER PRIMARY KEY,  -- YYYYMMDD
    full_date     DATE,
    year          INTEGER,
    quarter       INTEGER,
    month         INTEGER,
    month_name    STRING,
    week          INTEGER,
    day_of_month  INTEGER,
    day_of_week   INTEGER,
    day_name      STRING,
    is_weekend    BOOLEAN
);
