/*
================================================================================
  Step 2: Data Engineering
  
  Create HOLLY_DB database and load data from Snowflake Marketplace.
  Runtime: ~5-8 minutes (depending on data volume)
================================================================================
*/

USE ROLE ACCOUNTADMIN;
CREATE WAREHOUSE IF NOT EXISTS HOLLY_WH WITH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 60;
USE WAREHOUSE HOLLY_WH;

-- ============================================================================
-- 1. CREATE DATABASE AND SCHEMAS
-- ============================================================================

CREATE DATABASE IF NOT EXISTS HOLLY_DB;
CREATE SCHEMA IF NOT EXISTS HOLLY_DB.STRUCTURED;
CREATE SCHEMA IF NOT EXISTS HOLLY_DB.SEMI_STRUCTURED;
CREATE SCHEMA IF NOT EXISTS HOLLY_DB.UNSTRUCTURED;

-- ============================================================================
-- 2. S&P 500 COMPANIES REFERENCE TABLE
-- ============================================================================

CREATE OR REPLACE TABLE HOLLY_DB.STRUCTURED.SP500_COMPANIES (
    SYMBOL VARCHAR,
    COMPANY_NAME VARCHAR,
    SECTOR VARCHAR,
    INDUSTRY VARCHAR,
    HEADQUARTERS VARCHAR,
    DATE_ADDED DATE,
    CIK VARCHAR,
    FOUNDED VARCHAR
);

-- Load top 20 S&P 500 companies by market cap (for the quickstart)
-- Full list: see the main holly repo INSTALL.sql for all 503 companies
INSERT INTO HOLLY_DB.STRUCTURED.SP500_COMPANIES VALUES
    ('AAPL', 'Apple Inc.', 'Information Technology', 'Technology Hardware, Storage & Peripherals', 'Cupertino, California', '1982-11-30', '320193', '1977'),
    ('MSFT', 'Microsoft', 'Information Technology', 'Systems Software', 'Redmond, Washington', '1994-06-01', '789019', '1975'),
    ('NVDA', 'Nvidia', 'Information Technology', 'Semiconductors', 'Santa Clara, California', '2001-11-30', '1045810', '1993'),
    ('AMZN', 'Amazon', 'Consumer Discretionary', 'Broadline Retail', 'Seattle, Washington', '2005-11-18', '1018724', '1994'),
    ('GOOGL', 'Alphabet Inc. (Class A)', 'Communication Services', 'Interactive Media & Services', 'Mountain View, California', '2014-04-03', '1652044', '1998'),
    ('META', 'Meta Platforms', 'Communication Services', 'Interactive Media & Services', 'Menlo Park, California', '2013-12-23', '1326801', '2004'),
    ('TSLA', 'Tesla, Inc.', 'Consumer Discretionary', 'Automobile Manufacturers', 'Austin, Texas', '2020-12-21', '1318605', '2003'),
    ('AVGO', 'Broadcom', 'Information Technology', 'Semiconductors', 'Palo Alto, California', '2014-05-08', '1730168', '1961'),
    ('JPM', 'JPMorgan Chase', 'Financials', 'Diversified Banks', 'New York City, New York', '1975-06-30', '19617', '2000'),
    ('LLY', 'Lilly (Eli)', 'Health Care', 'Pharmaceuticals', 'Indianapolis, Indiana', '1970-12-31', '59478', '1876'),
    ('V', 'Visa Inc.', 'Financials', 'Transaction & Payment Processing Services', 'San Francisco, California', '2009-12-21', '1403161', '1958'),
    ('UNH', 'UnitedHealth Group', 'Health Care', 'Managed Health Care', 'Minnetonka, Minnesota', '1994-07-01', '731766', '1977'),
    ('XOM', 'ExxonMobil', 'Energy', 'Integrated Oil & Gas', 'Irving, Texas', '1957-03-04', '34088', '1999'),
    ('MA', 'Mastercard', 'Financials', 'Transaction & Payment Processing Services', 'Harrison, New York', '2008-07-18', '1141391', '1966'),
    ('JNJ', 'Johnson & Johnson', 'Health Care', 'Pharmaceuticals', 'New Brunswick, New Jersey', '1973-06-30', '200406', '1886'),
    ('COST', 'Costco', 'Consumer Staples', 'Consumer Staples Merchandise Retail', 'Issaquah, Washington', '1993-10-01', '909832', '1976'),
    ('HD', 'Home Depot (The)', 'Consumer Discretionary', 'Home Improvement Retail', 'Atlanta, Georgia', '1988-03-31', '354950', '1978'),
    ('PG', 'Procter & Gamble', 'Consumer Staples', 'Personal Care Products', 'Cincinnati, Ohio', '1957-03-04', '80424', '1837'),
    ('NFLX', 'Netflix', 'Communication Services', 'Movies & Entertainment', 'Los Gatos, California', '2010-12-20', '1065280', '1997'),
    ('CRM', 'Salesforce', 'Information Technology', 'Application Software', 'San Francisco, California', '2008-09-15', '1108524', '1999');

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
    CLUSTER BY (COMPANY_NAME, FILED_DATE)
AS
SELECT 
    r.COMPANY_NAME,
    r.FORM_TYPE AS ANNOUNCEMENT_TYPE,
    r.FILED_DATE,
    r.FISCAL_PERIOD,
    r.FISCAL_YEAR,
    a.ITEM_NUMBER,
    a.ITEM_TITLE,
    a.PLAINTEXT_CONTENT AS ANNOUNCEMENT_TEXT
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_CORPORATE_REPORT_ITEM_ATTRIBUTES a
INNER JOIN SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_CORPORATE_REPORT_INDEX r
    ON a.ADSH = r.ADSH 
INNER JOIN HOLLY_DB.STRUCTURED.SP500_COMPANIES s
    ON LPAD(r.CIK, 10, '0') = LPAD(s.CIK, 10, '0')
WHERE r.FILED_DATE >= '2025-01-01'
  AND r.FORM_TYPE IN ('8-K', '10-K', '10-Q');

ALTER TABLE HOLLY_DB.SEMI_STRUCTURED.EDGAR_FILINGS SET CHANGE_TRACKING = TRUE;

-- ============================================================================
-- 5. EARNINGS TRANSCRIPTS (S&P 500 companies)
-- ============================================================================

CREATE OR REPLACE TABLE HOLLY_DB.UNSTRUCTURED.PUBLIC_TRANSCRIPTS AS
SELECT 
    t.COMPANY_ID,
    t.CIK,
    t.COMPANY_NAME,
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
-- VERIFY
-- ============================================================================

SELECT 'SP500_COMPANIES' AS TABLE_NAME, COUNT(*) AS ROWS FROM HOLLY_DB.STRUCTURED.SP500_COMPANIES
UNION ALL
SELECT 'STOCK_PRICE_TIMESERIES', COUNT(*) FROM HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES
UNION ALL
SELECT 'EDGAR_FILINGS', COUNT(*) FROM HOLLY_DB.SEMI_STRUCTURED.EDGAR_FILINGS
UNION ALL
SELECT 'PUBLIC_TRANSCRIPTS', COUNT(*) FROM HOLLY_DB.UNSTRUCTURED.PUBLIC_TRANSCRIPTS;
