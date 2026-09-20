-- Fato Orders. Sem hash_diff (grão order_id x product_id já é chave natural
-- de MERGE; fato não precisa de detecção de mudança campo a campo como as
-- dimensões — se a linha mudou, ela é sobrescrita inteira).
-- Depende de: silver_orders, silver_order_details.
CREATE OR REPLACE PROCEDURE gold_fact_orders()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    MERGE INTO gold_fact_orders g
    USING (
        SELECT
            o.order_id,
            o.customer_id,
            d.product_id,
            TO_NUMBER(TO_CHAR(o.order_date, 'YYYYMMDD')) AS date_key,
            d.unit_price,
            d.quantity,
            d.discount,
            ROUND(d.unit_price * d.quantity, 2)               AS gross_amount,
            ROUND(d.unit_price * d.quantity * (1 - d.discount), 2) AS net_amount
        FROM silver_orders o
        JOIN silver_order_details d ON d.order_id = o.order_id
        WHERE o.order_date IS NOT NULL
    ) s
    ON g.order_id = s.order_id AND g.product_id = s.product_id
    WHEN MATCHED THEN
        UPDATE SET
            g.customer_id  = s.customer_id,
            g.date_key     = s.date_key,
            g.unit_price   = s.unit_price,
            g.quantity     = s.quantity,
            g.discount     = s.discount,
            g.gross_amount = s.gross_amount,
            g.net_amount   = s.net_amount
    WHEN NOT MATCHED THEN
        INSERT (order_id, customer_id, product_id, date_key, unit_price, quantity, discount, gross_amount, net_amount)
        VALUES (s.order_id, s.customer_id, s.product_id, s.date_key, s.unit_price, s.quantity, s.discount, s.gross_amount, s.net_amount);
    RETURN 'Load Gold Fact Orders table successfully';
END;
$$;
