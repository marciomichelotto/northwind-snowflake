-- =============================================================================
-- TASKS — Orquestração do Pipeline Northwind
-- Estrutura em cadeia: cada task dispara a próxima ao concluir
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BRONZE — Ingestão paralela (todas dependem da task raiz)
-- -----------------------------------------------------------------------------

-- Task raiz: dispara toda a cadeia (agendada a cada hora)
CREATE OR REPLACE TASK task_root
    WAREHOUSE = POC_WH
    SCHEDULE  = '60 MINUTE'
AS
    SELECT 1;  -- Apenas gatilho — não executa lógica

-- Bronze Customers
CREATE OR REPLACE TASK task_bronze_customers
    WAREHOUSE = POC_WH
    AFTER     task_root
AS
    CALL load_bronze_customers();

-- Bronze Orders
CREATE OR REPLACE TASK task_bronze_orders
    WAREHOUSE = POC_WH
    AFTER     task_root
AS
    CALL load_bronze_orders();

-- Bronze Order Details
CREATE OR REPLACE TASK task_bronze_order_details
    WAREHOUSE = POC_WH
    AFTER     task_root
AS
    CALL load_bronze_order_details();

-- Bronze Products
CREATE OR REPLACE TASK task_bronze_products
    WAREHOUSE = POC_WH
    AFTER     task_root
AS
    CALL load_bronze_products();

-- -----------------------------------------------------------------------------
-- SILVER — Após cada Bronze respectiva
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TASK task_silver_customers
    WAREHOUSE = POC_WH
    AFTER     task_bronze_customers
AS
    CALL load_silver_customers();

CREATE OR REPLACE TASK task_silver_orders
    WAREHOUSE = POC_WH
    AFTER     task_bronze_orders
AS
    CALL load_silver_orders();

CREATE OR REPLACE TASK task_silver_order_details
    WAREHOUSE = POC_WH
    AFTER     task_bronze_order_details
AS
    CALL load_silver_order_details();

CREATE OR REPLACE TASK task_silver_products
    WAREHOUSE = POC_WH
    AFTER     task_bronze_products
AS
    CALL load_silver_products();

-- -----------------------------------------------------------------------------
-- GOLD — Dimensões (após Silvers correspondentes)
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TASK task_gold_dim_customers
    WAREHOUSE = POC_WH
    AFTER     task_silver_customers
AS
    CALL gold_dim_customers();

CREATE OR REPLACE TASK task_gold_dim_products
    WAREHOUSE = POC_WH
    AFTER     task_silver_products
AS
    CALL gold_dim_products();

-- -----------------------------------------------------------------------------
-- Ativar todas as tasks (ordem inversa — filhas antes da raiz)
-- -----------------------------------------------------------------------------

ALTER TASK task_gold_dim_products      RESUME;
ALTER TASK task_gold_dim_customers     RESUME;
ALTER TASK task_silver_products        RESUME;
ALTER TASK task_silver_order_details   RESUME;
ALTER TASK task_silver_orders          RESUME;
ALTER TASK task_silver_customers       RESUME;
ALTER TASK task_bronze_products        RESUME;
ALTER TASK task_bronze_order_details   RESUME;
ALTER TASK task_bronze_orders          RESUME;
ALTER TASK task_bronze_customers       RESUME;
ALTER TASK task_root                   RESUME;  -- Ativar a raiz por último

-- -----------------------------------------------------------------------------
-- Monitoramento
-- -----------------------------------------------------------------------------

-- Verificar status das tasks
-- SELECT name, state, schedule, last_committed_on
-- FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
-- ORDER BY scheduled_time DESC;
