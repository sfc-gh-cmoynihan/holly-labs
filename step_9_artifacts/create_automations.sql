-- Author: Colm Moynihan
-- Date: 27-Aug-2026
-- Version: 1.0

/*
================================================================================
  Step 9: Automations
  
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
-- AUTOMATION 1: Daily Market Summary
-- 
-- Every weekday at 8:00 AM Dublin time, ask Holly for the top movers
-- and post a summary. Runs read-only (default).
-- ============================================================================

/*
Run in Cortex Code terminal:

cortex automation create \
  --name "daily-market-summary" \
  --schedule "weekdays at 8am" \
  --timezone "Europe/Dublin" \
  --prompt "You are running unattended in a Snowflake AGENT TASK; complete the task autonomously and do NOT ask clarifying questions.

Use the Holly agent (COWORK.AGENTS.HOLLY) to answer: What are the top 5 best performing S&P 500 stocks over the last 5 trading days, and what are the top 5 worst? Include percentage changes.

Format the result as a clean summary with two sections: TOP MOVERS and BOTTOM MOVERS.

End with: DAILY_MARKET_SUMMARY_OK date=$(date +%Y-%m-%d)"
*/

-- ============================================================================
-- AUTOMATION 2: Weekly Performance Report
-- 
-- Every Monday at 9:00 AM Dublin time, generate a chart of last week's
-- top performers and save as an artifact.
-- ============================================================================

/*
Run in Cortex Code terminal:

cortex automation create \
  --name "weekly-performance-report" \
  --schedule "every Monday at 9am" \
  --timezone "Europe/Dublin" \
  --prompt "You are running unattended in a Snowflake AGENT TASK; complete the task autonomously and do NOT ask clarifying questions.

Use the Holly agent (COWORK.AGENTS.HOLLY) to:
1. Get the top 10 best performing S&P 500 stocks over the last 7 trading days with their percentage returns.
2. Plot a bar chart of these top 10 performers (ticker on x-axis, % return on y-axis).
3. Also get the current EUR/USD and GBP/USD exchange rates.

Compile a weekly summary report with:
- Date range covered
- Top 10 performers table (ticker, company name, % return)
- Exchange rate snapshot

End with: WEEKLY_PERFORMANCE_REPORT_OK week_ending=$(date +%Y-%m-%d)"
*/

-- ============================================================================
-- AUTOMATION 3: FX Rate Alert
-- 
-- Every weekday at 7:00 AM Dublin time, check if EUR/USD moved more than
-- 1% in the previous trading day. If so, flag it.
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
cortex automation doctor daily-market-summary
cortex automation doctor weekly-performance-report
cortex automation doctor fx-rate-alert

-- Pause an automation
cortex automation suspend daily-market-summary

-- Resume an automation
cortex automation resume daily-market-summary

-- View what a fire actually did (get thread_id from doctor output)
cortex conversations transcript <thread_id>

-- Delete an automation
cortex automation drop fx-rate-alert
*/
