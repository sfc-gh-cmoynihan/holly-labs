-- Author: Colm Moynihan
-- Date: 26-Aug-2026
-- Version: 1.3

/*
================================================================================
  Step 6: Create Interactive Tables and Interactive Warehouse
  
  Sub-second query response for stock price data in Holly.
================================================================================
*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE HOLLY_AD_WH;

-- ============================================================================
-- 1. CREATE INTERACTIVE TABLE (from existing stock price data)
-- ============================================================================

CREATE OR REPLACE INTERACTIVE TABLE HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES_IT
    CLUSTER BY (TICKER, DATE)
    COMMENT = 'Stock price data optimized for sub-second interactive queries'
AS
SELECT * FROM HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES;

-- ============================================================================
-- 2. CREATE INTERACTIVE WAREHOUSE + FALLBACK
-- ============================================================================

CREATE OR REPLACE INTERACTIVE WAREHOUSE HOLLY_IW WAREHOUSE_SIZE = 'MEDIUM';
CREATE OR REPLACE WAREHOUSE HOLLY_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 60;

-- Set fallback: non-interactive queries route to standard warehouse
ALTER WAREHOUSE HOLLY_IW SET FALLBACK_WAREHOUSE = HOLLY_WH;

-- ============================================================================
-- 3. ATTACH INTERACTIVE TABLE TO WAREHOUSE
-- ============================================================================

ALTER WAREHOUSE HOLLY_IW ADD TABLES (HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES_IT);

-- ============================================================================
-- 4. FX RATES INTERACTIVE TABLE
-- ============================================================================

CREATE OR REPLACE INTERACTIVE TABLE HOLLY_DB.STRUCTURED.FX_RATES_IT
    CLUSTER BY (BASE_CURRENCY_ID, QUOTE_CURRENCY_ID, DATE)
    COMMENT = 'FX rates optimized for sub-second interactive queries'
AS
SELECT * FROM HOLLY_DB.STRUCTURED.FX_RATES;

ALTER WAREHOUSE HOLLY_IW ADD TABLES (HOLLY_DB.STRUCTURED.FX_RATES_IT);

-- ============================================================================
-- 4. UPDATE AGENT TO USE INTERACTIVE TABLE + WAREHOUSE
-- ============================================================================

-- Update the semantic view to point to the Interactive Table
CREATE OR REPLACE SEMANTIC VIEW HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES_SV
  TABLES (
    HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES_IT
  )
  FACTS (
    STOCK_PRICE_TIMESERIES_IT.VALUE AS VALUE
      comment='Value reported for the variable (price in USD or volume count).'
  )
  DIMENSIONS (
    STOCK_PRICE_TIMESERIES_IT.TICKER AS TICKER
      comment='Stock ticker symbol e.g. AAPL, MSFT, NVDA, AMZN, GOOGL.',
    STOCK_PRICE_TIMESERIES_IT.VARIABLE_NAME AS VARIABLE_NAME
      comment='Human-readable variable name. ALWAYS filter WHERE VARIABLE_NAME = Post-Market Close for any share price or closing price query.',
    STOCK_PRICE_TIMESERIES_IT.DATE AS DATE
      comment='Trading date. Use ORDER BY DATE, TICKER for time series queries.'
  )
  COMMENT = 'S&P 500 daily stock prices on Interactive Table. Use VARIABLE_NAME = Post-Market Close for closing prices. For charts, return daily data (DATE, TICKER, VALUE) — do NOT use DATE_TRUNC or weekly averaging.'
  AI_VERIFIED_QUERIES (
    "Plot the share price of Microsoft, Amazon, Google, and Nvidia over the last 12 months" AS (
      QUESTION 'Plot the share price of Microsoft, Amazon, Google, and Nvidia over the last 12 months'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'SELECT DATE, TICKER, VALUE AS SHARE_PRICE FROM HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES_IT WHERE TICKER IN (''MSFT'', ''AMZN'', ''GOOGL'', ''NVDA'') AND VARIABLE_NAME = ''Post-Market Close'' AND DATE >= DATEADD(MONTH, -12, CURRENT_DATE()) ORDER BY DATE, TICKER'
    ),
    "Plot the closing price of MSFT, AMZN, GOOGL, NVDA over the last 6 months" AS (
      QUESTION 'Plot the closing price of MSFT, AMZN, GOOGL, NVDA over the last 6 months'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'SELECT DATE, TICKER, VALUE AS SHARE_PRICE FROM HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES_IT WHERE TICKER IN (''MSFT'', ''AMZN'', ''GOOGL'', ''NVDA'') AND VARIABLE_NAME = ''Post-Market Close'' AND DATE >= DATEADD(MONTH, -6, CURRENT_DATE()) ORDER BY DATE, TICKER'
    ),
    "What is the latest share price of NVIDIA?" AS (
      QUESTION 'What is the latest share price of NVIDIA?'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'SELECT TICKER, DATE, VALUE AS SHARE_PRICE FROM HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES_IT WHERE TICKER = ''NVDA'' AND VARIABLE_NAME = ''Post-Market Close'' ORDER BY DATE DESC LIMIT 1'
    )
  );

-- ============================================================================
-- VERIFY: Test query speed
-- ============================================================================

-- This should return in <500ms once the IW is loaded
SELECT TICKER, DATE, VALUE AS CLOSING_PRICE
FROM HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES_IT
WHERE TICKER = 'NVDA' AND VARIABLE_NAME = 'Post-Market Close'
ORDER BY DATE DESC
LIMIT 5;

-- ============================================================================
-- 6. UPDATE FX SEMANTIC VIEW TO USE INTERACTIVE TABLE
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW HOLLY_DB.STRUCTURED.FX_RATES_SV
  TABLES (
    HOLLY_DB.STRUCTURED.FX_RATES_IT
  )
  FACTS (
    FX_RATES_IT.VALUE AS VALUE
      comment='Exchange rate value. E.g., EUR/USD = 1.08 means 1 EUR buys 1.08 USD.'
  )
  DIMENSIONS (
    FX_RATES_IT.BASE_CURRENCY_ID AS BASE_CURRENCY_ID
      comment='3-letter ISO code of the base currency (the one being priced). E.g. EUR in EUR/USD.',
    FX_RATES_IT.QUOTE_CURRENCY_ID AS QUOTE_CURRENCY_ID
      comment='3-letter ISO code of the quote currency. E.g. USD in EUR/USD.',
    FX_RATES_IT.VARIABLE_NAME AS VARIABLE_NAME
      comment='Human-readable pair name, e.g. EUR/USD Exchange Rate.',
    FX_RATES_IT.DATE AS DATE
      comment='Date of the exchange rate observation.'
  )
  COMMENT = 'Foreign exchange rates on Interactive Table. Use BASE_CURRENCY_ID and QUOTE_CURRENCY_ID to filter pairs.'
  AI_VERIFIED_QUERIES (
    "What is the current EUR/USD exchange rate?" AS (
      QUESTION 'What is the current EUR/USD exchange rate?'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'SELECT DATE, BASE_CURRENCY_ID, QUOTE_CURRENCY_ID, VALUE AS EXCHANGE_RATE FROM HOLLY_DB.STRUCTURED.FX_RATES_IT WHERE BASE_CURRENCY_ID = ''EUR'' AND QUOTE_CURRENCY_ID = ''USD'' ORDER BY DATE DESC LIMIT 1'
    ),
    "Plot the EUR/USD exchange rate over the last 6 months" AS (
      QUESTION 'Plot the EUR/USD exchange rate over the last 6 months'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'SELECT DATE, VALUE AS EXCHANGE_RATE FROM HOLLY_DB.STRUCTURED.FX_RATES_IT WHERE BASE_CURRENCY_ID = ''EUR'' AND QUOTE_CURRENCY_ID = ''USD'' AND DATE >= DATEADD(MONTH, -6, CURRENT_DATE()) ORDER BY DATE'
    ),
    "Chart the USD to EUR exchange rate over the last 12 months" AS (
      QUESTION 'Chart the USD to EUR exchange rate over the last 12 months'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'SELECT DATE, VALUE AS EXCHANGE_RATE FROM HOLLY_DB.STRUCTURED.FX_RATES_IT WHERE BASE_CURRENCY_ID = ''USD'' AND QUOTE_CURRENCY_ID = ''EUR'' AND DATE >= DATEADD(MONTH, -12, CURRENT_DATE()) ORDER BY DATE'
    ),
    "Chart the USD to GBP exchange rate over the last 12 months" AS (
      QUESTION 'Chart the USD to GBP exchange rate over the last 12 months'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'SELECT DATE, VALUE AS EXCHANGE_RATE FROM HOLLY_DB.STRUCTURED.FX_RATES_IT WHERE BASE_CURRENCY_ID = ''USD'' AND QUOTE_CURRENCY_ID = ''GBP'' AND DATE >= DATEADD(MONTH, -12, CURRENT_DATE()) ORDER BY DATE'
    ),
    "What is the USD to GBP exchange rate over the last 3 months" AS (
      QUESTION 'What is the USD to GBP exchange rate over the last 3 months'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'SELECT DATE, VALUE AS EXCHANGE_RATE FROM HOLLY_DB.STRUCTURED.FX_RATES_IT WHERE BASE_CURRENCY_ID = ''USD'' AND QUOTE_CURRENCY_ID = ''GBP'' AND DATE >= DATEADD(MONTH, -3, CURRENT_DATE()) ORDER BY DATE'
    )
  );

-- Test FX query speed
SELECT DATE, VALUE AS EXCHANGE_RATE
FROM HOLLY_DB.STRUCTURED.FX_RATES_IT
WHERE BASE_CURRENCY_ID = 'EUR' AND QUOTE_CURRENCY_ID = 'USD'
ORDER BY DATE DESC
LIMIT 5;
