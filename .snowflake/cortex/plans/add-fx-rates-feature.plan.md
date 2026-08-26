# Plan: Add FX Rates (USD/EUR) to Holly

## Context

The existing `SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.FX_RATES_TIMESERIES` view (from the same Cybersyn Marketplace dataset already installed) contains daily FX rates including EUR/USD with data from 1999 to present. No additional Marketplace install is needed.

## Changes by File

### 1. `step_3_data_engineering/data_engineering.sql` — Add FX table

Add a new section (after section 3) that creates a structured FX rates table for major USD currency pairs:

```sql
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
```

### 2. `step_4_semantic_views/create_semantic_views.sql` — Add FX semantic view

```sql
CREATE OR REPLACE SEMANTIC VIEW HOLLY_DB.STRUCTURED.FX_RATES_SV
  TABLES (HOLLY_DB.STRUCTURED.FX_RATES)
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
  COMMENT = 'Foreign exchange rates for major currency pairs vs USD. Use BASE_CURRENCY_ID = EUR AND QUOTE_CURRENCY_ID = USD for EUR/USD rate.'
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
    )
  );
```

### 3. `step_7_interactive_tables/create_interactive.sql` — Add FX interactive table

Add after the existing stock price IT section:

```sql
-- FX RATES INTERACTIVE TABLE
CREATE OR REPLACE INTERACTIVE TABLE HOLLY_DB.STRUCTURED.FX_RATES_IT
    CLUSTER BY (BASE_CURRENCY_ID, QUOTE_CURRENCY_ID, DATE)
AS
SELECT * FROM HOLLY_DB.STRUCTURED.FX_RATES;

ALTER WAREHOUSE HOLLY_IW ADD TABLES (HOLLY_DB.STRUCTURED.FX_RATES_IT);

-- Update FX semantic view to use Interactive Table
CREATE OR REPLACE SEMANTIC VIEW HOLLY_DB.STRUCTURED.FX_RATES_SV
  TABLES (HOLLY_DB.STRUCTURED.FX_RATES_IT)
  -- (same facts/dimensions/VQRs but pointing to FX_RATES_IT)
```

### 4. `step_6_holly_agent/create_agent.sql` — Add FX_RATES tool

Add to the agent specification:
- **Instructions**: Add `- Exchange rate / FX / currency → FX_RATES` to the decision tree
- **Sample questions** (2 new):
  - `"What is the current EUR/USD exchange rate?"`
  - `"Plot the EUR/USD exchange rate over the last 6 months"`
- **Tool**: New `cortex_analyst_text_to_sql` tool named `FX_RATES`
- **Tool resource**: Points to `HOLLY_DB.STRUCTURED.FX_RATES_SV`

### 5. `step_8_daily_refresh/create_task.sql` — Live FX rate UDF + refresh

Add a `GET_LIVE_FX_RATE` Python UDF (using Yahoo Finance `EURUSD=X` symbol) for real-time rate queries, plus add an FX MERGE to the daily refresh task to pick up new daily rates from the Marketplace source.

## Notes

- The FX data is already in the same Marketplace dataset (`SNOWFLAKE_PUBLIC_DATA_PAID`) that Step 1 installs — no additional Marketplace subscription required.
- Including major pairs (EUR, GBP, JPY, CHF, CAD, AUD vs USD) not just EUR/USD so the agent can handle follow-up questions about other currencies.
- The live UDF covers "what is the rate right now" questions; the semantic view handles historical analysis.
