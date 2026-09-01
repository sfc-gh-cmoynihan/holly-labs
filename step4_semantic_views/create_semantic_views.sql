-- Author: Colm Moynihan
-- Date: 26-Aug-2026
-- Version: 1.6

/*
================================================================================
  Step 4: Create Semantic Views
  
  Semantic views tell Cortex Analyst how to translate natural language into SQL.
  Verified queries (VQRs) guarantee correct SQL for common question patterns.
================================================================================
*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE HOLLY_WH;

-- ============================================================================
-- 1. STOCK PRICE SEMANTIC VIEW
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES_SV
  TABLES (
    HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES
  )
  FACTS (
    STOCK_PRICE_TIMESERIES.VALUE AS VALUE
      comment='Value reported for the variable (price in USD or volume count).'
  )
  DIMENSIONS (
    STOCK_PRICE_TIMESERIES.TICKER AS TICKER
      comment='Stock ticker symbol e.g. AAPL, MSFT, NVDA, AMZN, GOOGL.',
    STOCK_PRICE_TIMESERIES.VARIABLE_NAME AS VARIABLE_NAME
      comment='Human-readable variable name. Valid values: Post-Market Close, Pre-Market Open, All-Day High, All-Day Low, Nasdaq Volume. ALWAYS filter WHERE VARIABLE_NAME = Post-Market Close for any share price or closing price query.',
    STOCK_PRICE_TIMESERIES.DATE AS DATE
      comment='Trading date. Use ORDER BY DATE, TICKER for time series queries.'
  )
  COMMENT = 'S&P 500 daily stock prices. Use VARIABLE_NAME = Post-Market Close for closing prices. For charts, return daily data (DATE, TICKER, VALUE) — do NOT use DATE_TRUNC or weekly averaging.'
  AI_VERIFIED_QUERIES (
    "Plot the share price of Microsoft, Amazon, Google, and Nvidia over the last 12 months" AS (
      QUESTION 'Plot the share price of Microsoft, Amazon, Google, and Nvidia over the last 12 months'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'SELECT DATE, TICKER, VALUE AS SHARE_PRICE FROM HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES WHERE TICKER IN (''MSFT'', ''AMZN'', ''GOOGL'', ''NVDA'') AND VARIABLE_NAME = ''Post-Market Close'' AND DATE >= DATEADD(MONTH, -12, CURRENT_DATE()) ORDER BY DATE, TICKER'
    ),
    "Plot the closing price of MSFT, AMZN, GOOGL, NVDA over the last 6 months" AS (
      QUESTION 'Plot the closing price of MSFT, AMZN, GOOGL, NVDA over the last 6 months'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'SELECT DATE, TICKER, VALUE AS SHARE_PRICE FROM HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES WHERE TICKER IN (''MSFT'', ''AMZN'', ''GOOGL'', ''NVDA'') AND VARIABLE_NAME = ''Post-Market Close'' AND DATE >= DATEADD(MONTH, -6, CURRENT_DATE()) ORDER BY DATE, TICKER'
    ),
    "What is the latest share price of NVIDIA?" AS (
      QUESTION 'What is the latest share price of NVIDIA?'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'SELECT TICKER, DATE, VALUE AS SHARE_PRICE FROM HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES WHERE TICKER = ''NVDA'' AND VARIABLE_NAME = ''Post-Market Close'' ORDER BY DATE DESC LIMIT 1'
    ),
    "Compare the stock price of Microsoft and Google over the last 6 months" AS (
      QUESTION 'Compare the stock price of Microsoft and Google over the last 6 months'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'SELECT DATE, TICKER, VALUE AS SHARE_PRICE FROM HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES WHERE TICKER IN (''MSFT'', ''GOOGL'') AND VARIABLE_NAME = ''Post-Market Close'' AND DATE >= DATEADD(MONTH, -6, CURRENT_DATE()) ORDER BY DATE, TICKER'
    ),
    "What is the closing price of NVDA for the last 30 days?" AS (
      QUESTION 'What is the closing price of NVDA for the last 30 days?'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION false
      SQL 'SELECT DATE, TICKER, VALUE AS CLOSING_PRICE FROM HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES WHERE TICKER = ''NVDA'' AND VARIABLE_NAME = ''Post-Market Close'' AND DATE >= DATEADD(DAY, -30, CURRENT_DATE()) ORDER BY DATE'
    ),
    "What are the top 5 best performing S&P 500 stocks over the last 3 months?" AS (
      QUESTION 'What are the top 5 best performing S&P 500 stocks over the last 3 months?'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'WITH latest AS (SELECT TICKER, VALUE AS LATEST_PRICE FROM HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES WHERE VARIABLE_NAME = ''Post-Market Close'' AND DATE = (SELECT MAX(DATE) FROM HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES)), baseline AS (SELECT TICKER, VALUE AS BASE_PRICE FROM HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES WHERE VARIABLE_NAME = ''Post-Market Close'' AND DATE = (SELECT MIN(DATE) FROM HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES WHERE DATE >= DATEADD(MONTH, -3, CURRENT_DATE()))) SELECT l.TICKER, ROUND(((l.LATEST_PRICE - b.BASE_PRICE) / b.BASE_PRICE) * 100, 1) AS RETURN_PCT FROM latest l JOIN baseline b ON l.TICKER = b.TICKER ORDER BY RETURN_PCT DESC LIMIT 5'
    )
  );

-- ============================================================================
-- 2. S&P 500 COMPANIES SEMANTIC VIEW
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW HOLLY_DB.STRUCTURED.SP500_SV
  TABLES (
    HOLLY_DB.STRUCTURED.SP500_COMPANIES
  )
  DIMENSIONS (
    SP500_COMPANIES.SYMBOL AS SYMBOL
      comment='Stock ticker symbol e.g. AAPL, MSFT.',
    SP500_COMPANIES.COMPANY_NAME AS COMPANY_NAME
      comment='Full company name.',
    SP500_COMPANIES.SECTOR AS SECTOR
      comment='GICS sector e.g. Information Technology, Health Care, Financials.',
    SP500_COMPANIES.INDUSTRY AS INDUSTRY
      comment='GICS industry e.g. Semiconductors, Pharmaceuticals.',
    SP500_COMPANIES.HEADQUARTERS AS HEADQUARTERS
      comment='Company headquarters location.',
    SP500_COMPANIES.DATE_ADDED AS DATE_ADDED
      comment='Date the company was added to the S&P 500 index.',
    SP500_COMPANIES.CIK AS CIK
      comment='SEC Central Index Key for linking to EDGAR filings.'
  )
  COMMENT = 'S&P 500 index constituents with sector, industry, and fundamentals. Use for membership checks and company metadata queries.'
  AI_VERIFIED_QUERIES (
    "Which oil and gas companies are in the S&P 500?" AS (
      QUESTION 'Which oil and gas companies are in the S&P 500?'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'SELECT SYMBOL, COMPANY_NAME, INDUSTRY, HEADQUARTERS FROM HOLLY_DB.STRUCTURED.SP500_COMPANIES WHERE SECTOR = ''Energy'' ORDER BY COMPANY_NAME'
    ),
    "Is Palantir in the S&P 500?" AS (
      QUESTION 'Is Palantir in the S&P 500?'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'SELECT SYMBOL, COMPANY_NAME, SECTOR, INDUSTRY, DATE_ADDED FROM HOLLY_DB.STRUCTURED.SP500_COMPANIES WHERE COMPANY_NAME ILIKE ''%Palantir%'' OR SYMBOL = ''PLTR'''
    )
  );

-- ============================================================================
-- 3. FX RATES SEMANTIC VIEW
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW HOLLY_DB.STRUCTURED.FX_RATES_SV
  TABLES (
    HOLLY_DB.STRUCTURED.FX_RATES
  )
  FACTS (
    FX_RATES.VALUE AS VALUE
      comment='Exchange rate value. E.g., EUR/USD = 1.08 means 1 EUR buys 1.08 USD.'
  )
  DIMENSIONS (
    FX_RATES.BASE_CURRENCY_ID AS BASE_CURRENCY_ID
      comment='3-letter ISO code of the base currency (the one being priced). E.g. EUR in EUR/USD.',
    FX_RATES.QUOTE_CURRENCY_ID AS QUOTE_CURRENCY_ID
      comment='3-letter ISO code of the quote currency. E.g. USD in EUR/USD.',
    FX_RATES.VARIABLE_NAME AS VARIABLE_NAME
      comment='Human-readable pair name, e.g. EUR/USD Exchange Rate.',
    FX_RATES.DATE AS DATE
      comment='Date of the exchange rate observation.'
  )
  COMMENT = 'Foreign exchange rates for major currency pairs (EUR, GBP, JPY, CHF, CAD, AUD vs USD). Use BASE_CURRENCY_ID and QUOTE_CURRENCY_ID to filter pairs.'
  AI_VERIFIED_QUERIES (
    "What is the current EUR/USD exchange rate?" AS (
      QUESTION 'What is the current EUR/USD exchange rate?'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'SELECT DATE, BASE_CURRENCY_ID, QUOTE_CURRENCY_ID, VALUE AS EXCHANGE_RATE FROM HOLLY_DB.STRUCTURED.FX_RATES WHERE BASE_CURRENCY_ID = ''EUR'' AND QUOTE_CURRENCY_ID = ''USD'' ORDER BY DATE DESC LIMIT 1'
    ),
    "Plot the EUR/USD exchange rate over the last 6 months" AS (
      QUESTION 'Plot the EUR/USD exchange rate over the last 6 months'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'SELECT DATE, VALUE AS EXCHANGE_RATE FROM HOLLY_DB.STRUCTURED.FX_RATES WHERE BASE_CURRENCY_ID = ''EUR'' AND QUOTE_CURRENCY_ID = ''USD'' AND DATE >= DATEADD(MONTH, -6, CURRENT_DATE()) ORDER BY DATE'
    ),
    "Chart the USD to EUR exchange rate over the last 12 months" AS (
      QUESTION 'Chart the USD to EUR exchange rate over the last 12 months'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'SELECT DATE, VALUE AS EXCHANGE_RATE FROM HOLLY_DB.STRUCTURED.FX_RATES WHERE BASE_CURRENCY_ID = ''USD'' AND QUOTE_CURRENCY_ID = ''EUR'' AND DATE >= DATEADD(MONTH, -12, CURRENT_DATE()) ORDER BY DATE'
    ),
    "Chart the USD to GBP exchange rate over the last 12 months" AS (
      QUESTION 'Chart the USD to GBP exchange rate over the last 12 months'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'SELECT DATE, VALUE AS EXCHANGE_RATE FROM HOLLY_DB.STRUCTURED.FX_RATES WHERE BASE_CURRENCY_ID = ''USD'' AND QUOTE_CURRENCY_ID = ''GBP'' AND DATE >= DATEADD(MONTH, -12, CURRENT_DATE()) ORDER BY DATE'
    ),
    "What is the USD to GBP exchange rate over the last 3 months" AS (
      QUESTION 'What is the USD to GBP exchange rate over the last 3 months'
      VERIFIED_AT 1743552000
      VERIFIED_BY 'ADMIN'
      ONBOARDING_QUESTION true
      SQL 'SELECT DATE, VALUE AS EXCHANGE_RATE FROM HOLLY_DB.STRUCTURED.FX_RATES WHERE BASE_CURRENCY_ID = ''USD'' AND QUOTE_CURRENCY_ID = ''GBP'' AND DATE >= DATEADD(MONTH, -3, CURRENT_DATE()) ORDER BY DATE'
    )
  );

-- ============================================================================
-- VERIFY
-- ============================================================================

SHOW SEMANTIC VIEWS IN SCHEMA HOLLY_DB.STRUCTURED;
