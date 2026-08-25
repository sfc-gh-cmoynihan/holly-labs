-- Author: Colm Moynihan
-- Date: 25-Aug-2026

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
  COMMENT = 'S&P 500 daily stock prices on Interactive Table. Use VARIABLE_NAME = Post-Market Close for closing prices.'
  AI_VERIFIED_QUERIES (
    "Plot the share price of Microsoft, Amazon, Google, and Nvidia over the last 12 months" AS (
      QUESTION 'Plot the share price of Microsoft, Amazon, Google, and Nvidia over the last 12 months'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'SELECT DATE_TRUNC(''WEEK'', DATE) AS WEEK, TICKER, ROUND(AVG(VALUE), 2) AS SHARE_PRICE FROM HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES_IT WHERE TICKER IN (''MSFT'', ''AMZN'', ''GOOGL'', ''NVDA'') AND VARIABLE_NAME = ''Post-Market Close'' AND DATE >= DATEADD(MONTH, -12, CURRENT_DATE()) GROUP BY DATE_TRUNC(''WEEK'', DATE), TICKER ORDER BY WEEK, TICKER'
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
