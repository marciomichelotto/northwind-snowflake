# Arquitetura Técnica — Northwind Snowflake Pipeline

## Visão Geral

Pipeline ELT baseado em arquitetura Medallion com três camadas de dados, orquestrado internamente pelo Snowflake via Tasks e versionado com CI/CD via GitHub Actions.

## Camadas

### Bronze — Raw
- **Fonte:** Stage S3 com arquivos Parquet
- **Estratégia:** TRUNCATE + INSERT (full refresh)
- **Transformação:** Nenhuma — dado fiel ao arquivo de origem
- **Tipo de coluna principal:** VARIANT (semi-estruturado)
- **Rastreabilidade:** `metadata$filename` registra o arquivo de origem de cada linha

### Silver — Cleaned
- **Fonte:** Tabelas Bronze
- **Estratégia:** TRUNCATE + INSERT (full refresh)
- **Transformações aplicadas:**
  - Extração de campos do VARIANT via `$1:"campo"::tipo`
  - Padronização com `UPPER()`
  - Tratamento de nulos com `COALESCE(..., 'N/A')`
  - Cast de tipos (STRING, FLOAT, INTEGER, DATE)

### Gold — Curated
- **Fonte:** Tabelas Silver
- **Estratégia:** MERGE com detecção de mudanças por `hash_diff`
- **Padrão SCD:** Type 1 (sobrescreve sem histórico)
- **Hash:** MD5 concatenando todos os campos de negócio com separador `|`

## Detecção de Mudanças (hash_diff)

```sql
MD5(campo1 || '|' || campo2 || '|' || ... || campoN)
```

Se qualquer campo mudar → hash muda → MERGE executa UPDATE.
Se nenhum campo mudar → hash igual → MERGE ignora o registro.

## Orquestração (Tasks)

```
task_root (agendada: 60min)
    ├── task_bronze_customers  → task_silver_customers  → task_gold_dim_customers
    ├── task_bronze_orders     → task_silver_orders
    ├── task_bronze_order_details → task_silver_order_details
    └── task_bronze_products   → task_silver_products   → task_gold_dim_products
```

## CI/CD (GitHub Actions)

Cada push na `main` dispara o workflow `deploy.yml` que:
1. Instala o Snowflake CLI
2. Configura conexão via Secrets do GitHub
3. Deploya tabelas → procedures → tasks (nessa ordem)

## Secrets necessários no GitHub

| Secret               | Descrição                  |
|----------------------|----------------------------|
| SNOWFLAKE_ACCOUNT    | Identificador da conta     |
| SNOWFLAKE_USER       | Usuário                    |
| SNOWFLAKE_PASSWORD   | Senha                      |
| SNOWFLAKE_ROLE       | Role com permissões        |
| SNOWFLAKE_WAREHOUSE  | Warehouse de execução      |
| SNOWFLAKE_DATABASE   | Database (ex: POC)         |
| SNOWFLAKE_SCHEMA     | Schema (ex: PUBLIC)        |
