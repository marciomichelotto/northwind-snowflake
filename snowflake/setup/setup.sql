-- =============================================================================
-- SETUP INICIAL — Northwind Snowflake Pipeline
-- Executar uma única vez antes de qualquer deploy
-- =============================================================================

-- Contexto
USE ROLE SYSADMIN;

-- Warehouse
CREATE WAREHOUSE IF NOT EXISTS POC_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND   = 60
    AUTO_RESUME    = TRUE
    COMMENT        = 'Warehouse do projeto Northwind';

-- Database e schemas
CREATE DATABASE IF NOT EXISTS NORTHWIND;
USE DATABASE NORTHWIND;

CREATE SCHEMA IF NOT EXISTS PUBLIC;
USE SCHEMA PUBLIC;

-- File Format para leitura de Parquet
CREATE OR REPLACE FILE FORMAT NORTHWIND.PUBLIC.PARQUET_FORMAT
    TYPE           = PARQUET
    SNAPPY_COMPRESSION = TRUE;

-- Stage externo (ajustar URL e credenciais conforme ambiente)
CREATE OR REPLACE STAGE NORTHWIND.PUBLIC.NORTH
    URL            = 's3://seu-bucket/northwind/'
    FILE_FORMAT    = NORTHWIND.PUBLIC.PARQUET_FORMAT
    COMMENT        = 'Stage S3 com os arquivos Parquet do Northwind';

-- Verificar conteúdo do stage
-- LIST @NORTHWIND.PUBLIC.NORTH;
