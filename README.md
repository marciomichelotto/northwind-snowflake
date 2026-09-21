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
| Calendar | — | — | dim_calendar | ✅ |
| Orders (Fact) | — | — | fact_orders | ✅ |

`gold_dim_calendar`: 1.096 dias (1996-01-01 a 1998-12-31, cobrindo com folga a
janela real das ordens do Northwind clássico). `gold_fact_orders`: 2.155
linhas — grão `order_id x product_id`, 1:1 com `silver_order_details`, sem
órfão contra nenhuma dimensão (calendário, clientes, produtos).

## Achados

830 pedidos, 89 clientes ativos (de 91 cadastrados), 77 produtos, 1996–1998.

**A receita se concentra em poucos clientes por país.** Áustria é o 3º país
em receita com só 2 clientes — os outros dois do top 3 têm dezenas.

| País | Receita líquida | Clientes |
|---|---|---|
| USA | US$ 245.584,65 | 13 |
| Germany | US$ 230.284,68 | 11 |
| Austria | US$ 128.003,86 | 2 |

**Um produto sozinho responde por 11% da receita líquida total.** Côte de
Blaye (US$ 141.396,74) supera a soma dos dois próximos do ranking.

| Produto | Receita líquida |
|---|---|
| Côte de Blaye | US$ 141.396,74 |
| Thüringer Rostbratwurst | US$ 80.368,69 |
| Raclette Courdavault | US$ 71.155,70 |

**28,6% do catálogo (22 de 77 produtos) já está no ou abaixo do ponto de
reposição** — `units_in_stock <= reorder_level`, direto de `gold_dim_products`.
É a métrica que nenhum dos outros dois projetos do portfólio tem, porque
nenhum outro lida com estoque físico.

**Desconto médio de 6,55% sobre a receita bruta** (US$ 88.665,55 de
US$ 1.354.458,59) — a receita líquida (US$ 1.265.793,25) retém 94,4% do
valor de tabela. Ticket médio por pedido: US$ 1.525,05.

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
├── scripts/
│   ├── deploy_snowflake.py         # Aplica todo o DDL (setup, tabelas, procedures) — idempotente
│   └── carrega_bronze.py           # Carrega o Northwind clássico pro bronze sem stage S3 (ver nota abaixo)
│
├── powerbi/
│   └── medidas.dax                 # 6 medidas DAX prontas — ver seção Achados
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
- Acesso ao stage S3 configurado (`@NORTHWIND.PUBLIC.NORTH`) — **ou**, na ausência
  de um bucket S3 real, `scripts/carrega_bronze.py` carrega o Northwind clássico
  direto de um espelho público, sem precisar de stage nenhum (ver nota em
  Fluxo de Execução)

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
SNOWFLAKE_DATABASE=NORTHWIND
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

> **Sem stage S3 configurado:** o desenho original do projeto depende de um
> bucket real com Parquet do Northwind, que é infraestrutura externa e não
> faz parte deste repositório. `scripts/carrega_bronze.py` cobre esse mesmo
> papel — busca os 4 CSVs do Northwind clássico de um espelho público
> estável, normaliza os campos pro snake_case que as procedures `silver_*`
> já esperam, e insere direto na Bronze no mesmo formato (`raw` VARIANT +
> `filename` + `created_at`) que `CALL load_bronze_x()` produziria a partir
> do stage. Dali em diante, a cascata Silver → Gold é a mesma:
> ```bash
> python scripts/deploy_snowflake.py   # aplica todo o DDL (idempotente)
> python scripts/carrega_bronze.py     # carrega bronze e dispara silver -> gold
> ```

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
