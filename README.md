# Northwind Snowflake Pipeline

Pipeline ELT baseado no dataset Northwind, construído com arquitetura Medallion (Bronze → Silver → Gold) sobre Snowflake — com Stored Procedures, Tasks de orquestração e CI/CD via GitHub Actions.

> **Northwind** é um dataset clássico de uma distribuidora fictícia de alimentos, amplamente usado para modelagem dimensional. Aqui ele serve como base para uma pipeline completa de engenharia de dados.

## Arquitetura

```
Stage S3 (Parquet)
        │
        ▼
  ┌─────────────┐
  │   BRONZE    │  Raw — dado bruto, sem transformação
  └──────┬──────┘
         │
         ▼
  ┌─────────────┐
  │   SILVER    │  Cleaned — tipagem, padronização, tratamento de nulos
  └──────┬──────┘
         │
         ▼
  ┌─────────────┐
  │    GOLD     │  Curated — dimensões e fatos prontos para consumo analítico
  └─────────────┘
```

Cada camada é carregada por Stored Procedures e orquestrada por Tasks dentro do Snowflake.

## Entidades

| Entidade | Bronze | Silver | Gold | Status |
|---|---|---|---|---|
| Customers | ✅ | ✅ | dim_customers | ✅ |
| Products | ✅ | ✅ | dim_products | ✅ |
| Orders | ✅ | ✅ | — | ✅ |
| Order Details | ✅ | ✅ | — | ✅ |
| Calendar | — | — | dim_calendar | 🔜 |
| Orders (Fact) | — | — | fact_orders | 🔜 |

## Estrutura do Repositório

```
northwind-snowflake/
│
├── .github/
│   └── workflows/
│       └── deploy.yml.disabled     # CI/CD temporariamente desabilitado
│
├── snowflake/
│   ├── setup/
│   │   └── setup.sql               # Criação de database, schema, warehouse, stage
│   │
│   ├── tables/
│   │   ├── bronze/                 # DDL das tabelas Bronze
│   │   ├── silver/                 # DDL das tabelas Silver
│   │   └── gold/                   # DDL das tabelas Gold (dims e facts)
│   │
│   ├── procedures/
│   │   ├── bronze/                 # Procedures de ingestão (stage → bronze)
│   │   ├── silver/                 # Procedures de limpeza (bronze → silver)
│   │   └── gold/                   # Procedures de carga (silver → gold, MERGE)
│   │
│   └── tasks/
│       └── tasks_pipeline.sql      # Orquestração via Snowflake Tasks
│
├── docs/
│   └── architecture.md             # Documentação técnica detalhada
│
├── .env.example                    # Variáveis de ambiente (sem valores reais)
├── .gitignore
└── README.md
```

## Configuração do Ambiente

### Pré-requisitos

- Conta Snowflake ativa
- [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/index) instalado
- Acesso ao stage S3 configurado (`@POC.PUBLIC.NORTH`)

### Variáveis necessárias

Copie o `.env.example` e configure suas credenciais:

```bash
cp .env.example .env
```

```env
SNOWFLAKE_ACCOUNT=seu_account
SNOWFLAKE_USER=seu_user
SNOWFLAKE_PASSWORD=sua_senha
SNOWFLAKE_ROLE=seu_role
SNOWFLAKE_WAREHOUSE=seu_warehouse
SNOWFLAKE_DATABASE=POC
SNOWFLAKE_SCHEMA=PUBLIC
```

> Nunca commite o arquivo `.env` — ele está no `.gitignore`.

## Deploy

### Manual (via Snowflake CLI)

```bash
# 1. Setup inicial (database, schema, warehouse, stage, file format)
snow sql -f snowflake/setup/setup.sql

# 2. Criar tabelas
snow sql -f snowflake/tables/bronze/bronze_customers.sql
snow sql -f snowflake/tables/silver/silver_customers.sql
snow sql -f snowflake/tables/gold/gold_customers.sql
# ... demais entidades

# 3. Criar procedures
snow sql -f snowflake/procedures/bronze/bronze_customers.sql
snow sql -f snowflake/procedures/silver/silver_customers.sql
snow sql -f snowflake/procedures/gold/gold_customers.sql
# ... demais entidades

# 4. Criar tasks de orquestração
snow sql -f snowflake/tasks/tasks_pipeline.sql
```

### Automático (CI/CD)

> 🚧 CI/CD em desenvolvimento: o GitHub Actions está temporariamente desabilitado neste repositório.

O workflow foi mantido como referência em `.github/workflows/deploy.yml.disabled`.

Quando reativado, o fluxo previsto é:
- Push em `dev` → deploy no ambiente de desenvolvimento
- Push em `qa` → deploy no ambiente de homologação
- Push em `main` → deploy em produção

## Fluxo de Execução

```sql
CALL load_bronze_customers();   -- Lê Parquet do stage → insere raw na Bronze
CALL load_silver_customers();   -- Limpa e tipifica → insere na Silver
CALL gold_dim_customers();      -- MERGE com hash_diff → upsert na Gold
```

As Tasks automatizam essa sequência inteira via agendamento no Snowflake.

## Stack

| Ferramenta | Uso |
|---|---|
| Snowflake | Data warehouse principal |
| AWS S3 | Stage externo — fonte dos arquivos Parquet |
| Snowflake Tasks | Orquestração interna do pipeline |
| GitHub Actions | CI/CD — deploy automático por ambiente |
| Snowflake CLI | Deploy via linha de comando |
| Python / SQL | Desenvolvimento e transformações |

## Licença

MIT © [Márcio Michelotto](https://github.com/marciomichelotto)
