CREATE OR REPLACE PROCEDURE gold_dim_customers()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    MERGE INTO gold_dim_customers g
    USING (
        SELECT
            customer_id,
            company_name,
            contact_name,
            contact_title,
            address,
            city,
            postal_code,
            country,
            phone,
            fax,
            MD5(
                NVL(company_name,'')  || '|' ||
                NVL(contact_name,'')  || '|' ||
                NVL(contact_title,'') || '|' ||
                NVL(address,'')       || '|' ||
                NVL(city,'')          || '|' ||
                NVL(postal_code,'')   || '|' ||
                NVL(country,'')       || '|' ||
                NVL(phone,'')         || '|' ||
                NVL(fax,'')
            ) AS hash_diff
        FROM silver_customers
    ) s
    ON g.customer_id = s.customer_id
    WHEN MATCHED AND g.hash_diff <> s.hash_diff THEN
        UPDATE SET
            g.company_name  = s.company_name,
            g.contact_name  = s.contact_name,
            g.contact_title = s.contact_title,
            g.address       = s.address,
            g.city          = s.city,
            g.postal_code   = s.postal_code,
            g.country       = s.country,
            g.phone         = s.phone,
            g.fax           = s.fax,
            g.hash_diff     = s.hash_diff,
            g.updated_at    = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN
        INSERT (customer_id, company_name, contact_name, contact_title,
                address, city, postal_code, country, phone, fax, hash_diff)
        VALUES (s.customer_id, s.company_name, s.contact_name, s.contact_title,
                s.address, s.city, s.postal_code, s.country, s.phone, s.fax, s.hash_diff);
    RETURN 'Load Gold Dim Customers table successfully';
END;
$$;
