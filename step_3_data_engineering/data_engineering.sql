-- Author: Colm Moynihan
-- Date: 26-Aug-2026
-- Version: 1.1

/*
================================================================================
  Step 2: Data Engineering
  
  Create HOLLY_DB database and load data from Snowflake Marketplace.
  S&P 500 companies are fetched live from Wikipedia (always current).
  Runtime: ~5-8 minutes
================================================================================
*/

USE ROLE ACCOUNTADMIN;
CREATE WAREHOUSE IF NOT EXISTS HOLLY_AD_WH
    WAREHOUSE_TYPE = 'ADAPTIVE';
USE WAREHOUSE HOLLY_AD_WH;

-- ============================================================================
-- 1. CREATE DATABASE AND SCHEMAS
-- ============================================================================

CREATE DATABASE IF NOT EXISTS HOLLY_DB;
CREATE SCHEMA IF NOT EXISTS HOLLY_DB.STRUCTURED;
CREATE SCHEMA IF NOT EXISTS HOLLY_DB.SEMI_STRUCTURED;
CREATE SCHEMA IF NOT EXISTS HOLLY_DB.UNSTRUCTURED;

-- ============================================================================
-- 2. S&P 500 COMPANIES — FETCHED LIVE FROM WIKIPEDIA
--    This ensures you always have the current index constituents.
-- ============================================================================

-- 2.1 Create External Access Integration (allows Python to reach Wikipedia)
CREATE OR REPLACE NETWORK RULE HOLLY_DB.STRUCTURED.WIKIPEDIA_NETWORK_RULE
    MODE = EGRESS
    TYPE = HOST_PORT
    VALUE_LIST = ('en.wikipedia.org');

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION WIKIPEDIA_ACCESS
    ALLOWED_NETWORK_RULES = (HOLLY_DB.STRUCTURED.WIKIPEDIA_NETWORK_RULE)
    ENABLED = TRUE;

-- 2.2 Create Python UDF that scrapes S&P 500 table from Wikipedia
CREATE OR REPLACE FUNCTION HOLLY_DB.STRUCTURED.GET_SP500_COMPANIES()
RETURNS TABLE (
    SYMBOL VARCHAR,
    COMPANY_NAME VARCHAR,
    SECTOR VARCHAR,
    INDUSTRY VARCHAR,
    HEADQUARTERS VARCHAR,
    DATE_ADDED VARCHAR,
    CIK VARCHAR,
    FOUNDED VARCHAR
)
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('pandas', 'requests', 'html5lib', 'beautifulsoup4')
EXTERNAL_ACCESS_INTEGRATIONS = (WIKIPEDIA_ACCESS)
HANDLER = 'get_sp500'
AS $$
import pandas as pd
import requests
from io import StringIO

class get_sp500:
    def process(self):
        url = 'https://en.wikipedia.org/wiki/List_of_S%26P_500_companies'
        headers = {'User-Agent': 'Snowflake-Holly-Labs/1.0'}
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        tables = pd.read_html(StringIO(response.text), flavor='html5lib')
        df = tables[0]
        
        for _, row in df.iterrows():
            yield (
                str(row.get('Symbol', '')).strip(),
                str(row.get('Security', '')).strip(),
                str(row.get('GICS Sector', '')).strip(),
                str(row.get('GICS Sub-Industry', '')).strip(),
                str(row.get('Headquarters Location', '')).strip(),
                str(row.get('Date added', '')).strip(),
                str(row.get('CIK', '')).strip(),
                str(row.get('Founded', '')).strip()
            )
$$;

-- 2.3 Load S&P 500 companies from Wikipedia into table
CREATE OR REPLACE TABLE HOLLY_DB.STRUCTURED.SP500_COMPANIES AS
SELECT * FROM TABLE(HOLLY_DB.STRUCTURED.GET_SP500_COMPANIES());

-- Verify: should be ~503 companies
SELECT COUNT(*) AS SP500_COUNT FROM HOLLY_DB.STRUCTURED.SP500_COMPANIES;
SELECT * FROM HOLLY_DB.STRUCTURED.SP500_COMPANIES LIMIT 10;

-- ============================================================================
-- 3. STOCK PRICE DATA (S&P 500 companies from Marketplace)
-- ============================================================================

CREATE OR REPLACE TABLE HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES
    CLUSTER BY (TICKER, DATE)
AS
SELECT 
    TICKER, ASSET_CLASS, PRIMARY_EXCHANGE_CODE, PRIMARY_EXCHANGE_NAME,
    VARIABLE, VARIABLE_NAME, DATE, VALUE
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.STOCK_PRICE_TIMESERIES
WHERE TICKER IN (SELECT SYMBOL FROM HOLLY_DB.STRUCTURED.SP500_COMPANIES);

ALTER TABLE HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES SET CHANGE_TRACKING = TRUE;

-- ============================================================================
-- 4. SEC EDGAR FILINGS (10-K, 10-Q, 8-K since 2025)
-- ============================================================================

CREATE OR REPLACE TABLE HOLLY_DB.SEMI_STRUCTURED.EDGAR_FILINGS
AS
SELECT 
    r.COMPANY_NAME AS COMPANY_NAME,
    r.FORM_TYPE AS ANNOUNCEMENT_TYPE,
    r.FILED_DATE,
    r.FISCAL_PERIOD,
    r.FISCAL_YEAR,
    a.ITEM_NUMBER,
    a.ITEM_TITLE,
    a.PLAINTEXT_CONTENT AS ANNOUNCEMENT_TEXT
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_CORPORATE_REPORT_INDEX r
INNER JOIN SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_CORPORATE_REPORT_ITEM_ATTRIBUTES a
    ON a.ADSH = r.ADSH 
INNER JOIN HOLLY_DB.STRUCTURED.SP500_COMPANIES s
    ON LPAD(r.CIK, 10, '0') = LPAD(s.CIK, 10, '0')
WHERE r.FILED_DATE >= '2025-01-01'
  AND r.FORM_TYPE IN ('8-K', '10-K', '10-Q');

ALTER TABLE HOLLY_DB.SEMI_STRUCTURED.EDGAR_FILINGS CLUSTER BY (COMPANY_NAME, FILED_DATE);

ALTER TABLE HOLLY_DB.SEMI_STRUCTURED.EDGAR_FILINGS SET CHANGE_TRACKING = TRUE;

-- ============================================================================
-- 5. EARNINGS TRANSCRIPTS (S&P 500 companies)
-- ============================================================================

CREATE OR REPLACE TABLE HOLLY_DB.UNSTRUCTURED.PUBLIC_TRANSCRIPTS AS
SELECT 
    t.COMPANY_ID,
    t.CIK,
    t.COMPANY_NAME AS COMPANY_NAME,
    t.PRIMARY_TICKER,
    t.FISCAL_PERIOD,
    t.FISCAL_YEAR,
    t.EVENT_TYPE,
    t.TRANSCRIPT,
    t.EVENT_TIMESTAMP
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.COMPANY_EVENT_TRANSCRIPT_ATTRIBUTES t
INNER JOIN HOLLY_DB.STRUCTURED.SP500_COMPANIES s ON t.PRIMARY_TICKER = s.SYMBOL;

ALTER TABLE HOLLY_DB.UNSTRUCTURED.PUBLIC_TRANSCRIPTS SET CHANGE_TRACKING = TRUE;

-- ============================================================================
-- 6. FX RATES (Major currency pairs from Marketplace)
-- ============================================================================

CREATE OR REPLACE TABLE HOLLY_DB.STRUCTURED.FX_RATES
    CLUSTER BY (BASE_CURRENCY_ID, QUOTE_CURRENCY_ID, DATE)
AS
SELECT 
    BASE_CURRENCY_ID, QUOTE_CURRENCY_ID,
    BASE_CURRENCY_NAME, QUOTE_CURRENCY_NAME,
    VARIABLE, VARIABLE_NAME, DATE, VALUE
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.FX_RATES_TIMESERIES
WHERE BASE_CURRENCY_ID IN ('USD', 'EUR', 'GBP', 'JPY', 'CHF', 'CAD', 'AUD')
  AND QUOTE_CURRENCY_ID IN ('USD', 'EUR', 'GBP', 'JPY', 'CHF', 'CAD', 'AUD')
  AND BASE_CURRENCY_ID != QUOTE_CURRENCY_ID;

ALTER TABLE HOLLY_DB.STRUCTURED.FX_RATES SET CHANGE_TRACKING = TRUE;

-- ============================================================================
-- VERIFY
-- ============================================================================

SELECT 'SP500_COMPANIES' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM HOLLY_DB.STRUCTURED.SP500_COMPANIES
UNION ALL
SELECT 'STOCK_PRICE_TIMESERIES', COUNT(*) FROM HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES
UNION ALL
SELECT 'EDGAR_FILINGS', COUNT(*) FROM HOLLY_DB.SEMI_STRUCTURED.EDGAR_FILINGS
UNION ALL
SELECT 'PUBLIC_TRANSCRIPTS', COUNT(*) FROM HOLLY_DB.UNSTRUCTURED.PUBLIC_TRANSCRIPTS
UNION ALL
SELECT 'FX_RATES', COUNT(*) FROM HOLLY_DB.STRUCTURED.FX_RATES;
