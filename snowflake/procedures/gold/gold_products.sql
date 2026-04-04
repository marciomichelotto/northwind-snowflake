CREATE OR REPLACE PROCEDURE gold_dim_products()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    MERGE INTO gold_dim_products g
    USING (
        SELECT
            product_id,
            product_name,
            supplier_id,
            category_id,
            quantity_per_unit,
            unit_price,
            units_in_stock,
            units_on_order,
            reorder_level,
            discontinued,
            MD5(
                NVL(product_name,'')      || '|' ||
                NVL(supplier_id,'')       || '|' ||
                NVL(category_id,'')       || '|' ||
                NVL(unit_price::STRING,'')|| '|' ||
                NVL(discontinued,'')
            ) AS hash_diff
        FROM silver_products
    ) s
    ON g.product_id = s.product_id
    WHEN MATCHED AND g.hash_diff <> s.hash_diff THEN
        UPDATE SET
            g.product_name      = s.product_name,
            g.supplier_id       = s.supplier_id,
            g.category_id       = s.category_id,
            g.quantity_per_unit = s.quantity_per_unit,
            g.unit_price        = s.unit_price,
            g.units_in_stock    = s.units_in_stock,
            g.units_on_order    = s.units_on_order,
            g.reorder_level     = s.reorder_level,
            g.discontinued      = s.discontinued,
            g.hash_diff         = s.hash_diff,
            g.updated_at        = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN
        INSERT (product_id, product_name, supplier_id, category_id,
                quantity_per_unit, unit_price, units_in_stock, units_on_order,
                reorder_level, discontinued, hash_diff)
        VALUES (s.product_id, s.product_name, s.supplier_id, s.category_id,
                s.quantity_per_unit, s.unit_price, s.units_in_stock, s.units_on_order,
                s.reorder_level, s.discontinued, s.hash_diff);
    RETURN 'Load Gold Dim Products table successfully';
END;
$$;
