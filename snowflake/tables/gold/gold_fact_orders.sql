-- Fato Orders. Grão: order_id x product_id.
CREATE OR REPLACE TABLE gold_fact_orders (
    order_id      STRING,
    customer_id   STRING,
    product_id    STRING,
    date_key      INTEGER,
    unit_price    FLOAT,
    quantity      INTEGER,
    discount      FLOAT,
    gross_amount  FLOAT,
    net_amount    FLOAT,
    created_at    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
