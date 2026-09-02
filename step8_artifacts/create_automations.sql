-- Author: Colm Moynihan
-- Date: 02-Sep-2026
-- Version: 1.1

/*
================================================================================
  Step 8: Automations
  
  Schedule recurring Cortex Code runs as Snowflake AGENT TASKs.
  These run unattended on a cron schedule — no warehouse needed.
  
  Prerequisites:
  - AGENT TASK must be enabled on the account (one-time ACCOUNTADMIN step)
  - Holly agent must be deployed (Step 6)
  
  Run these via the `cortex automation` CLI in Cortex Code Desktop,
  NOT as SQL worksheets. Each command below is a terminal command.
================================================================================
*/

-- ============================================================================
-- ENABLE AGENT TASKS (one-time, run as ACCOUNTADMIN in Snowsight)
-- ============================================================================

-- ALTER ACCOUNT SET ENABLE_CORTEX_AGENT_TASK = TRUE;

-- ============================================================================
-- AUTOMATION 1: Tech Stock Price Tracker
-- 
-- Every weekday at 8:00 AM Dublin time, plot closing prices for
-- MSFT, AMZN, GOOGL, NVDA and summarise notable trends.
-- Maps to sample question #1: "Plot the closing price of MSFT, AMZN,
-- GOOGL, NVDA over the last 6 months"
-- ============================================================================

/*
Run in Cortex Code terminal:

cortex automation create \
  --name "tech-stock-tracker" \
  --schedule "weekdays at 8am" \
  --timezone "Europe/Dublin" \
  --prompt "You are running unattended in a Snowflake AGENT TASK; complete the task autonomously and do NOT ask clarifying questions.

Use the Holly agent (COWORK.AGENTS.HOLLY) to answer: Plot the closing price of MSFT, AMZN, GOOGL, NVDA over the last 6 months.

Present the chart and include a brief commentary on any notable trends or divergences between the four stocks.

End with: TECH_STOCK_TRACKER_OK date=$(date +%Y-%m-%d)"
*/

-- ============================================================================
-- AUTOMATION 2: Top Performers Chart
-- 
-- Every Monday at 9:00 AM Dublin time, generate a bar chart of the
-- top 5 best performing S&P 500 stocks over the last 3 months.
-- Maps to sample question #2: "Show a bar chart of the top 5 best
-- performing stocks over the last 3 months"
-- ============================================================================

/*
Run in Cortex Code terminal:

cortex automation create \
  --name "top-performers-chart" \
  --schedule "every Monday at 9am" \
  --timezone "Europe/Dublin" \
  --prompt "You are running unattended in a Snowflake AGENT TASK; complete the task autonomously and do NOT ask clarifying questions.

Use the Holly agent (COWORK.AGENTS.HOLLY) to answer: Show a bar chart of the top 5 best performing stocks over the last 3 months.

Include each stock's percentage return and sector. Add a one-paragraph market commentary summarising the themes across the top performers.

End with: TOP_PERFORMERS_CHART_OK date=$(date +%Y-%m-%d)"
*/

-- ============================================================================
-- AUTOMATION 3: NVIDIA Price Check
-- 
-- Every weekday at 7:00 AM New York time (before market open),
-- check the latest NVIDIA closing price with 7-day and 30-day changes.
-- Maps to sample question #3: "What is the latest share price of NVIDIA?"
-- ============================================================================

/*
Run in Cortex Code terminal:

cortex automation create \
  --name "nvidia-price-check" \
  --schedule "weekdays at 7am" \
  --timezone "America/New_York" \
  --prompt "You are running unattended in a Snowflake AGENT TASK; complete the task autonomously and do NOT ask clarifying questions.

Use the Holly agent (COWORK.AGENTS.HOLLY) to answer: What is the latest share price of NVIDIA?

Also check: what was NVIDIA's share price 7 days ago and 30 days ago? Calculate the 7-day and 30-day percentage change.

Format as:
- Current price: \$X.XX (as of DATE)
- 7-day change: +/-X.X%
- 30-day change: +/-X.X%

End with: NVIDIA_PRICE_CHECK_OK date=$(date +%Y-%m-%d) price=[value]"
*/

-- ============================================================================
-- AUTOMATION 4: Microsoft vs Google Comparison
-- 
-- Every Monday at 8:00 AM Dublin time, compare MSFT and GOOGL stock
-- prices over the last 6 months with performance analysis.
-- Maps to sample question #4: "Compare the stock price of Microsoft
-- and Google over the last 6 months"
-- ============================================================================

/*
Run in Cortex Code terminal:

cortex automation create \
  --name "msft-vs-googl-weekly" \
  --schedule "every Monday at 8am" \
  --timezone "Europe/Dublin" \
  --prompt "You are running unattended in a Snowflake AGENT TASK; complete the task autonomously and do NOT ask clarifying questions.

Use the Holly agent (COWORK.AGENTS.HOLLY) to answer: Compare the stock price of Microsoft and Google over the last 6 months.

Present the comparison chart. Then calculate:
1. Which stock performed better over the 6-month period (% return)
2. The current price spread between the two
3. Any period where one significantly outperformed the other

Format the numerical summary as a clean table.

End with: MSFT_VS_GOOGL_OK date=$(date +%Y-%m-%d)"
*/

-- ============================================================================
-- AUTOMATION 5: FX Rate Alert
-- 
-- Every weekday at 7:00 AM Dublin time, check if EUR/USD moved more
-- than 1% in the previous trading day. If so, flag it.
-- ============================================================================

/*
Run in Cortex Code terminal:

cortex automation create \
  --name "fx-rate-alert" \
  --schedule "weekdays at 7am" \
  --timezone "Europe/Dublin" \
  --prompt "You are running unattended in a Snowflake AGENT TASK; complete the task autonomously and do NOT ask clarifying questions.

Run this SQL to check EUR/USD movement:

SELECT 
    a.DATE AS today_date,
    a.VALUE AS today_rate,
    b.VALUE AS prev_rate,
    ROUND((a.VALUE - b.VALUE) / b.VALUE * 100, 3) AS pct_change
FROM HOLLY_DB.STRUCTURED.FX_RATES a
JOIN HOLLY_DB.STRUCTURED.FX_RATES b 
    ON b.BASE_CURRENCY_ID = a.BASE_CURRENCY_ID 
    AND b.QUOTE_CURRENCY_ID = a.QUOTE_CURRENCY_ID
    AND b.DATE = (SELECT MAX(DATE) FROM HOLLY_DB.STRUCTURED.FX_RATES WHERE DATE < a.DATE AND BASE_CURRENCY_ID = 'EUR' AND QUOTE_CURRENCY_ID = 'USD')
WHERE a.BASE_CURRENCY_ID = 'EUR' 
  AND a.QUOTE_CURRENCY_ID = 'USD'
  AND a.DATE = (SELECT MAX(DATE) FROM HOLLY_DB.STRUCTURED.FX_RATES WHERE BASE_CURRENCY_ID = 'EUR' AND QUOTE_CURRENCY_ID = 'USD')

If ABS(pct_change) > 1.0, report: FX ALERT - EUR/USD moved [pct_change]% on [date]. Current rate: [today_rate].
If ABS(pct_change) <= 1.0, report: EUR/USD stable. Change: [pct_change]% on [date]. Rate: [today_rate].

End with: FX_RATE_ALERT_OK date=$(date +%Y-%m-%d) pct_change=[value]"
*/

-- ============================================================================
-- MANAGEMENT COMMANDS (run in Cortex Code terminal)
-- ============================================================================

/*
-- List all automations
cortex automation list

-- Check recent run history and errors
cortex automation doctor tech-stock-tracker
cortex automation doctor top-performers-chart
cortex automation doctor nvidia-price-check
cortex automation doctor msft-vs-googl-weekly
cortex automation doctor fx-rate-alert

-- Pause an automation
cortex automation suspend tech-stock-tracker

-- Resume an automation
cortex automation resume tech-stock-tracker

-- View what a run actually did (get thread_id from doctor output)
cortex conversations transcript <thread_id>

-- Delete an automation
cortex automation drop fx-rate-alert
*/
