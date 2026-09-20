"""
deploy_snowflake.py — aplica todo o DDL do projeto (setup, tabelas,
procedures) na conta Snowflake configurada em .env.

Idempotente: todo objeto usa CREATE OR REPLACE / IF NOT EXISTS, então rodar
de novo não duplica nada — é o mesmo papel que o deploy.yml faria via CI/CD,
só que disparado manualmente.

SNOWFLAKE_PASSWORD não precisa estar no .env — se a variável já existir no
ambiente do processo (ex.: exportada antes de chamar o script), é usada
direto; .env só cobre o resto da conexão.

Uso:
    python deploy_snowflake.py
"""

from __future__ import annotations

import os
from pathlib import Path

import snowflake.connector

ROOT = Path(__file__).resolve().parent.parent

# ordem importa: setup cria o database/schema antes de tudo.
ARQUIVOS = [
    ROOT / "snowflake/setup/setup.sql",
    ROOT / "snowflake/tables/bronze/bronze_customers.sql",
    ROOT / "snowflake/tables/bronze/bronze_orders.sql",
    ROOT / "snowflake/tables/bronze/bronze_order_details.sql",
    ROOT / "snowflake/tables/bronze/bronze_products.sql",
    ROOT / "snowflake/tables/silver/silver_customers.sql",
    ROOT / "snowflake/tables/silver/silver_orders.sql",
    ROOT / "snowflake/tables/silver/silver_order_details.sql",
    ROOT / "snowflake/tables/silver/silver_products.sql",
    ROOT / "snowflake/tables/gold/gold_customers.sql",
    ROOT / "snowflake/tables/gold/gold_products.sql",
    ROOT / "snowflake/tables/gold/gold_dim_calendar.sql",
    ROOT / "snowflake/tables/gold/gold_fact_orders.sql",
    ROOT / "snowflake/procedures/bronze/bronze_customers.sql",
    ROOT / "snowflake/procedures/bronze/bronze_orders.sql",
    ROOT / "snowflake/procedures/bronze/bronze_order_details.sql",
    ROOT / "snowflake/procedures/bronze/bronze_products.sql",
    ROOT / "snowflake/procedures/silver/silver_customers.sql",
    ROOT / "snowflake/procedures/silver/silver_orders.sql",
    ROOT / "snowflake/procedures/silver/silver_order_details.sql",
    ROOT / "snowflake/procedures/silver/silver_products.sql",
    ROOT / "snowflake/procedures/gold/gold_customers.sql",
    ROOT / "snowflake/procedures/gold/gold_products.sql",
    ROOT / "snowflake/procedures/gold/gold_dim_calendar.sql",
    ROOT / "snowflake/procedures/gold/gold_fact_orders.sql",
]


def split_statements(sql_text: str) -> list[str]:
    # execute_string() do connector quebra em "Empty SQL statement" quando o
    # arquivo termina com ';' seguido só de espaço/quebra de linha — faz o
    # split manual aqui, respeitando blocos $$...$$ (corpo de procedure) pra
    # não cortar um ';' que é conteúdo do procedure no meio.
    partes: list[str] = []
    atual: list[str] = []
    dentro_dollar = False
    dentro_comentario = False
    i = 0
    while i < len(sql_text):
        if dentro_comentario:
            atual.append(sql_text[i])
            if sql_text[i] == "\n":
                dentro_comentario = False
            i += 1
            continue
        if not dentro_dollar and sql_text[i : i + 2] == "--":
            dentro_comentario = True
            atual.append("--")
            i += 2
            continue
        if sql_text[i : i + 2] == "$$":
            dentro_dollar = not dentro_dollar
            atual.append("$$")
            i += 2
            continue
        if sql_text[i] == ";" and not dentro_dollar:
            partes.append("".join(atual))
            atual = []
            i += 1
            continue
        atual.append(sql_text[i])
        i += 1
    partes.append("".join(atual))

    def tem_conteudo(stmt: str) -> bool:
        sem_comentarios = "\n".join(
            l for l in stmt.splitlines() if not l.strip().startswith("--")
        )
        return bool(sem_comentarios.strip())

    return [p.strip() for p in partes if tem_conteudo(p)]


def carrega_env(path: Path) -> None:
    for linha in path.read_text(encoding="utf-8").splitlines():
        linha = linha.strip()
        if not linha or linha.startswith("#") or "=" not in linha:
            continue
        chave, valor = linha.split("=", 1)
        if valor and chave not in os.environ:
            os.environ[chave] = valor


def main() -> None:
    carrega_env(ROOT / ".env")

    con = snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"],
        role=os.environ["SNOWFLAKE_ROLE"],
        warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
    )

    cur = con.cursor()
    for path in ARQUIVOS:
        for stmt in split_statements(path.read_text(encoding="utf-8")):
            try:
                cur.execute(stmt)
            except Exception:
                print(f"FALHOU em {path}:\n---\n{stmt}\n---")
                raise
        print(f"  ok  {path.relative_to(ROOT)}")

    con.close()
    print(f"\n{len(ARQUIVOS)} arquivos aplicados.")


if __name__ == "__main__":
    main()
