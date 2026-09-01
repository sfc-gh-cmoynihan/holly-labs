-- Author: Colm Moynihan
-- Date: 26-Aug-2026
-- Version: 1.3

/*
================================================================================
  Step 7: Daily Data Refresh & Live Prices
  
  Incrementally refreshes FX rates from Marketplace.
  
  Schedule: Daily at 6:00 AM UTC
================================================================================
*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE HOLLY_WH;

-- ============================================================================
-- CREATE THE DAILY REFRESH TASK
-- ============================================================================

CREATE OR REPLACE TASK HOLLY_DB.STRUCTURED.DAILY_DATA_REFRESH
  WAREHOUSE = HOLLY_WH
  SCHEDULE = 'USING CRON 0 6 * * * UTC'
  COMMENT = 'Daily incremental refresh of FX rates at 6:00 AM UTC'
AS
BEGIN
  -- ========================================================================
  -- 1. MERGE new FX rates from marketplace
  -- ========================================================================
  MERGE INTO HOLLY_DB.STRUCTURED.FX_RATES AS target
  USING (
    SELECT 
      BASE_CURRENCY_ID, QUOTE_CURRENCY_ID,
      BASE_CURRENCY_NAME, QUOTE_CURRENCY_NAME,
      VARIABLE, VARIABLE_NAME, DATE, VALUE
    FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.FX_RATES_TIMESERIES
    WHERE BASE_CURRENCY_ID IN ('USD', 'EUR', 'GBP', 'JPY', 'CHF', 'CAD', 'AUD')
      AND QUOTE_CURRENCY_ID IN ('USD', 'EUR', 'GBP', 'JPY', 'CHF', 'CAD', 'AUD')
      AND BASE_CURRENCY_ID != QUOTE_CURRENCY_ID
      AND DATE >= DATEADD(DAY, -7, CURRENT_DATE())
  ) AS source
  ON target.BASE_CURRENCY_ID = source.BASE_CURRENCY_ID
     AND target.QUOTE_CURRENCY_ID = source.QUOTE_CURRENCY_ID
     AND target.DATE = source.DATE
  WHEN NOT MATCHED THEN
    INSERT (BASE_CURRENCY_ID, QUOTE_CURRENCY_ID, BASE_CURRENCY_NAME, QUOTE_CURRENCY_NAME, VARIABLE, VARIABLE_NAME, DATE, VALUE)
    VALUES (source.BASE_CURRENCY_ID, source.QUOTE_CURRENCY_ID, source.BASE_CURRENCY_NAME, source.QUOTE_CURRENCY_NAME, source.VARIABLE, source.VARIABLE_NAME, source.DATE, source.VALUE);
END;

-- ============================================================================
-- RESUME THE TASK (tasks are suspended by default)
-- ============================================================================

ALTER TASK HOLLY_DB.STRUCTURED.DAILY_DATA_REFRESH RESUME;

-- ============================================================================
-- VERIFY TASK
-- ============================================================================

SHOW TASKS IN SCHEMA HOLLY_DB.STRUCTURED;

-- ============================================================================
-- 7B. EXTERNAL API FOR LIVE STOCK PRICES
--     Add real-time quotes via Yahoo Finance using External Access Integration.
-- ============================================================================

-- Network Rule: Allow access to Yahoo Finance
CREATE OR REPLACE NETWORK RULE HOLLY_DB.STRUCTURED.YAHOO_FINANCE_NETWORK_RULE
    MODE = EGRESS
    TYPE = HOST_PORT
    VALUE_LIST = ('query1.finance.yahoo.com', 'query2.finance.yahoo.com');

-- External Access Integration
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION YAHOO_FINANCE_ACCESS
    ALLOWED_NETWORK_RULES = (HOLLY_DB.STRUCTURED.YAHOO_FINANCE_NETWORK_RULE)
    ENABLED = TRUE;

-- Python UDF: Fetch live stock price from Yahoo Finance
CREATE OR REPLACE FUNCTION HOLLY_DB.STRUCTURED.GET_LIVE_PRICE(TICKER_SYMBOL VARCHAR)
RETURNS TABLE (
    TICKER VARCHAR,
    PRICE FLOAT,
    CURRENCY VARCHAR,
    DAY_CHANGE FLOAT,
    DAY_CHANGE_PCT FLOAT,
    MARKET_STATE VARCHAR,
    EXCHANGE VARCHAR,
    TIMESTAMP VARCHAR
)
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
EXTERNAL_ACCESS_INTEGRATIONS = (YAHOO_FINANCE_ACCESS)
HANDLER = 'get_live_price'
AS $$
import requests
from datetime import datetime

class get_live_price:
    def process(self, ticker_symbol: str):
        url = f'https://query1.finance.yahoo.com/v8/finance/chart/{ticker_symbol}'
        params = {'interval': '1d', 'range': '1d'}
        headers = {'User-Agent': 'Snowflake-Holly-Labs/1.0'}
        
        try:
            response = requests.get(url, params=params, headers=headers, timeout=10)
            data = response.json()
            
            meta = data['chart']['result'][0]['meta']
            price = meta.get('regularMarketPrice', 0)
            prev_close = meta.get('previousClose', 0)
            change = round(price - prev_close, 2) if prev_close else 0
            change_pct = round((change / prev_close) * 100, 2) if prev_close else 0
            
            yield (
                ticker_symbol.upper(),
                float(price),
                meta.get('currency', 'USD'),
                float(change),
                float(change_pct),
                meta.get('marketState', 'UNKNOWN'),
                meta.get('exchangeName', 'UNKNOWN'),
                datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            )
        except Exception as e:
            yield (
                ticker_symbol.upper(),
                0.0,
                'USD',
                0.0,
                0.0,
                'ERROR',
                str(e)[:50],
                datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            )
$$;

-- Test live prices
SELECT * FROM TABLE(HOLLY_DB.STRUCTURED.GET_LIVE_PRICE('NVDA'));
SELECT * FROM TABLE(HOLLY_DB.STRUCTURED.GET_LIVE_PRICE('AAPL'));
SELECT * FROM TABLE(HOLLY_DB.STRUCTURED.GET_LIVE_PRICE('MSFT'));

-- ============================================================================
-- 7C. LIVE FX RATE UDF
--     Fetch real-time exchange rates via Yahoo Finance (e.g. EURUSD=X)
-- ============================================================================

CREATE OR REPLACE FUNCTION HOLLY_DB.STRUCTURED.GET_LIVE_FX_RATE(CURRENCY_PAIR VARCHAR)
RETURNS TABLE (
    PAIR VARCHAR,
    RATE FLOAT,
    DAY_CHANGE FLOAT,
    DAY_CHANGE_PCT FLOAT,
    MARKET_STATE VARCHAR,
    TIMESTAMP VARCHAR
)
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
EXTERNAL_ACCESS_INTEGRATIONS = (YAHOO_FINANCE_ACCESS)
HANDLER = 'get_live_fx_rate'
AS $$
import requests
from datetime import datetime

class get_live_fx_rate:
    def process(self, currency_pair: str):
        # Accept formats: "EURUSD", "EUR/USD", "EURUSD=X"
        pair = currency_pair.upper().replace('/', '').replace('=X', '')
        symbol = f'{pair}=X'
        
        url = f'https://query1.finance.yahoo.com/v8/finance/chart/{symbol}'
        params = {'interval': '1d', 'range': '1d'}
        headers = {'User-Agent': 'Snowflake-Holly-Labs/1.0'}
        
        try:
            response = requests.get(url, params=params, headers=headers, timeout=10)
            data = response.json()
            
            meta = data['chart']['result'][0]['meta']
            rate = meta.get('regularMarketPrice', 0)
            prev_close = meta.get('previousClose', 0)
            change = round(rate - prev_close, 4) if prev_close else 0
            change_pct = round((change / prev_close) * 100, 4) if prev_close else 0
            
            yield (
                pair[:3] + '/' + pair[3:],
                float(rate),
                float(change),
                float(change_pct),
                meta.get('marketState', 'UNKNOWN'),
                datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            )
        except Exception as e:
            yield (
                pair[:3] + '/' + pair[3:],
                0.0,
                0.0,
                0.0,
                'ERROR: ' + str(e)[:50],
                datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            )
$$;

-- Test live FX rates
SELECT * FROM TABLE(HOLLY_DB.STRUCTURED.GET_LIVE_FX_RATE('EURUSD'));
SELECT * FROM TABLE(HOLLY_DB.STRUCTURED.GET_LIVE_FX_RATE('GBPUSD'));
