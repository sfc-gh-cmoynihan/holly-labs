-- Author: Colm Moynihan
-- Date: 25-Aug-2026

/*
================================================================================
  Step 1: Explore Snowflake Public Data
  
  Run these queries to verify your marketplace subscription is working
  and explore the available financial datasets.
================================================================================
*/

USE ROLE ACCOUNTADMIN;
CREATE WAREHOUSE IF NOT EXISTS HOLLY_AD_WH
    WAREHOUSE_TYPE = 'ADAPTIVE';
USE WAREHOUSE HOLLY_AD_WH;

-- See what schemas are available
SHOW SCHEMAS IN DATABASE SNOWFLAKE_PUBLIC_DATA_PAID;

-- ============================================================================
-- STOCK PRICES: Daily OHLC for all US-listed stocks
-- ============================================================================

-- Total row count (~90M+ rows)
SELECT COUNT(*) AS total_rows FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.STOCK_PRICE_TIMESERIES;

-- Preview: NVIDIA closing prices
SELECT TICKER, DATE, VARIABLE_NAME, VALUE
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.STOCK_PRICE_TIMESERIES
WHERE TICKER = 'NVDA' AND VARIABLE_NAME = 'Post-Market Close'
ORDER BY DATE DESC
LIMIT 10;

-- Available variables per ticker per day
SELECT DISTINCT VARIABLE_NAME
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.STOCK_PRICE_TIMESERIES
WHERE TICKER = 'AAPL' AND DATE = '2026-01-02';

-- ============================================================================
-- SEC FILINGS: 10-K, 10-Q, 8-K from EDGAR
-- ============================================================================

-- Total filings count
SELECT COUNT(*) AS total_filing_items
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_CORPORATE_REPORT_ITEM_ATTRIBUTES;

-- Preview: Recent NVIDIA filings
SELECT r.COMPANY_NAME, r.FORM_TYPE, r.FILED_DATE, a.ITEM_TITLE
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_CORPORATE_REPORT_ITEM_ATTRIBUTES a
JOIN SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.SEC_CORPORATE_REPORT_INDEX r ON a.ADSH = r.ADSH
WHERE r.COMPANY_NAME ILIKE '%NVIDIA%'
ORDER BY r.FILED_DATE DESC
LIMIT 10;

-- ============================================================================
-- EARNINGS TRANSCRIPTS: S&P 500 companies
-- ============================================================================

-- Total transcripts count
SELECT COUNT(*) AS total_transcripts
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.COMPANY_EVENT_TRANSCRIPT_ATTRIBUTES;

-- Preview: Recent transcripts
SELECT COMPANY_NAME, PRIMARY_TICKER, EVENT_TYPE, FISCAL_PERIOD, FISCAL_YEAR, EVENT_TIMESTAMP
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.COMPANY_EVENT_TRANSCRIPT_ATTRIBUTES
ORDER BY EVENT_TIMESTAMP DESC
LIMIT 10;
