/*
================================================================================
  Step 8: External API for Live Stock Prices
  
  Add real-time stock quotes via Yahoo Finance using External Access Integration.
================================================================================
*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE HOLLY_WH;

-- ============================================================================
-- 1. NETWORK RULE: Allow access to Yahoo Finance
-- ============================================================================

CREATE OR REPLACE NETWORK RULE HOLLY_DB.STRUCTURED.YAHOO_FINANCE_NETWORK_RULE
    MODE = EGRESS
    TYPE = HOST_PORT
    VALUE_LIST = ('query1.finance.yahoo.com', 'query2.finance.yahoo.com');

-- ============================================================================
-- 2. EXTERNAL ACCESS INTEGRATION
-- ============================================================================

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION YAHOO_FINANCE_ACCESS
    ALLOWED_NETWORK_RULES = (HOLLY_DB.STRUCTURED.YAHOO_FINANCE_NETWORK_RULE)
    ENABLED = TRUE;

-- ============================================================================
-- 3. PYTHON UDF: Fetch live stock price from Yahoo Finance
-- ============================================================================

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

-- ============================================================================
-- 4. TEST IT
-- ============================================================================

-- Get live NVIDIA price
SELECT * FROM TABLE(HOLLY_DB.STRUCTURED.GET_LIVE_PRICE('NVDA'));

-- Get live Apple price
SELECT * FROM TABLE(HOLLY_DB.STRUCTURED.GET_LIVE_PRICE('AAPL'));

-- Get live Microsoft price
SELECT * FROM TABLE(HOLLY_DB.STRUCTURED.GET_LIVE_PRICE('MSFT'));
