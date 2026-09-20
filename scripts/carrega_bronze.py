"""
carrega_bronze.py — carga do Northwind clássico pro bronze, sem stage S3.

O projeto foi desenhado em torno de um stage S3 (@POC.PUBLIC.NORTH) com
Parquet — mas isso é infraestrutura externa que precisa existir antes, e não
é o objeto deste repositório. Northwind é dataset de referência público (a
mesma distribuidora fictícia usada em incontáveis cursos de SQL); este
script busca os 4 CSVs de um espelho público estável (neo4j-graph-examples,
que mantém os arquivos originais do Northwind clássico), normaliza os nomes
de campo pro snake_case que as procedures silver_* já esperam dentro do
VARIANT, e insere direto — mesma forma final (raw VARIANT + filename +
created_at) que `CALL load_bronze_x()` produziria a partir do stage.

Depois da carga, dispara a cascata silver → gold via CALL, na ordem de
dependência (dim_calendar não depende de silver nenhum; fact_orders depende
de silver_orders + silver_order_details).

Uso:
    python carrega_bronze.py
    python carrega_bronze.py --entrada ./data/raw   # usa CSVs locais em vez de baixar
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

import pandas as pd
import snowflake.connector

ROOT = Path(__file__).resolve().parent.parent

FONTE = "https://raw.githubusercontent.com/neo4j-graph-examples/northwind/main/import"

# (arquivo, tabela bronze, mapa de coluna origem -> campo snake_case esperado pelo silver)
ENTIDADES = [
    (
        "customers.csv",
        "bronze_customers",
        {
            "customerID": "customer_id", "companyName": "company_name",
            "contactName": "contact_name", "contactTitle": "contact_title",
            "address": "address", "city": "city", "postalCode": "postal_code",
            "country": "country", "phone": "phone", "fax": "fax",
        },
    ),
    (
        "orders.csv",
        "bronze_orders",
        {
            "orderID": "order_id", "customerID": "customer_id", "employeeID": "employee_id",
            "orderDate": "order_date", "requiredDate": "required_date", "shippedDate": "shipped_date",
            "shipVia": "ship_via", "freight": "freight", "shipName": "ship_name",
            "shipAddress": "ship_address", "shipCity": "ship_city",
            "shipPostalCode": "ship_postal_code", "shipCountry": "ship_country",
        },
    ),
    (
        "order-details.csv",
        "bronze_order_details",
        {
            "orderID": "order_id", "productID": "product_id",
            "unitPrice": "unit_price", "quantity": "quantity", "discount": "discount",
        },
    ),
    (
        "products.csv",
        "bronze_products",
        {
            "productID": "product_id", "productName": "product_name",
            "supplierID": "supplier_id", "categoryID": "category_id",
            "quantityPerUnit": "quantity_per_unit", "unitPrice": "unit_price",
            "unitsInStock": "units_in_stock", "unitsOnOrder": "units_on_order",
            "reorderLevel": "reorder_level", "discontinued": "discontinued",
        },
    ),
]

DATE_COLS = {"order_date", "required_date", "shipped_date"}


def carrega_env(path: Path) -> None:
    for linha in path.read_text(encoding="utf-8").splitlines():
        linha = linha.strip()
        if not linha or linha.startswith("#") or "=" not in linha:
            continue
        chave, valor = linha.split("=", 1)
        if valor and chave not in os.environ:
            os.environ[chave] = valor


def carrega_csv(nome: str, mapa: dict, entrada: Path | None) -> pd.DataFrame:
    origem = str(entrada / nome) if entrada else f"{FONTE}/{nome}"
    df = pd.read_csv(origem, na_values=["NULL"])
    df = df[list(mapa.keys())].rename(columns=mapa)
    for col in DATE_COLS & set(df.columns):
        df[col] = pd.to_datetime(df[col]).dt.strftime("%Y-%m-%d")
    return df.where(pd.notna(df), None)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--entrada", type=Path, default=None,
                    help="pasta com os CSVs já baixados; sem isso, busca da fonte pública")
    args = ap.parse_args()

    carrega_env(ROOT / ".env")
    con = snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"],
        role=os.environ["SNOWFLAKE_ROLE"],
        warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
        database=os.environ["SNOWFLAKE_DATABASE"],
        schema=os.environ["SNOWFLAKE_SCHEMA"],
    )
    cur = con.cursor()

    for arquivo, tabela, mapa in ENTIDADES:
        df = carrega_csv(arquivo, mapa, args.entrada)
        linhas = [(json.dumps(r), arquivo) for r in df.to_dict(orient="records")]
        cur.execute(f"TRUNCATE TABLE {tabela}")
        # executemany faz rewrite pra multi-row VALUES, e Snowflake não aceita
        # PARSE_JSON() dentro desse rewrite — execute() linha a linha em vez
        # disso (volume pequeno, ~3 mil linhas no total, custo desprezível).
        for raw_json, filename in linhas:
            cur.execute(
                f"INSERT INTO {tabela} (raw, filename, created_at) "
                f"SELECT PARSE_JSON(%s), %s, CURRENT_TIMESTAMP()",
                (raw_json, filename),
            )
        print(f"  {tabela:<24} {len(linhas):>5} linhas")

    print("\n--- cascata silver -> gold ---")
    for proc in [
        "load_silver_customers", "load_silver_orders",
        "load_silver_order_details", "load_silver_products",
        "gold_dim_customers", "gold_dim_products",
        "gold_dim_calendar", "gold_fact_orders",
    ]:
        cur.execute(f"CALL {proc}()")
        print(" ", cur.fetchone()[0])

    con.close()


if __name__ == "__main__":
    main()
