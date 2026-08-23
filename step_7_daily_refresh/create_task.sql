/*
================================================================================
  Step 7: Daily Data Refresh Task
  
  Incrementally refreshes EDGAR filings and transcripts from Marketplace.
  Cortex Search services auto-refresh via change tracking.
  
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
  COMMENT = 'Daily incremental refresh of EDGAR filings and transcripts at 6:00 AM UTC'
AS
BEGIN
  -- ========================================================================
  -- 1. MERGE new SEC filings from marketplace
  -- ========================================================================
  MERGE INTO HOLLY_DB.SEMI_STRUCTURED.EDGAR_FILINGS AS target
  USING (
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
    WHERE r.FILED_DATE >= DATEADD(DAY, -7, CURRENT_DATE())
      AND r.FORM_TYPE IN ('8-K', '10-K', '10-Q')
      AND a.PLAINTEXT_CONTENT IS NOT NULL
  ) AS source
  ON target.COMPANY_NAME = source.COMPANY_NAME 
     AND target.FILED_DATE = source.FILED_DATE 
     AND target.ITEM_NUMBER = source.ITEM_NUMBER
  WHEN NOT MATCHED THEN
    INSERT (COMPANY_NAME, ANNOUNCEMENT_TYPE, FILED_DATE, FISCAL_PERIOD, FISCAL_YEAR, ITEM_NUMBER, ITEM_TITLE, ANNOUNCEMENT_TEXT)
    VALUES (source.COMPANY_NAME, source.ANNOUNCEMENT_TYPE, source.FILED_DATE, source.FISCAL_PERIOD, source.FISCAL_YEAR, source.ITEM_NUMBER, source.ITEM_TITLE, source.ANNOUNCEMENT_TEXT);

  -- ========================================================================
  -- 2. MERGE new transcripts from marketplace
  -- ========================================================================
  MERGE INTO HOLLY_DB.UNSTRUCTURED.PUBLIC_TRANSCRIPTS AS target
  USING (
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
    INNER JOIN HOLLY_DB.STRUCTURED.SP500_COMPANIES s ON t.PRIMARY_TICKER = s.SYMBOL
    WHERE t.EVENT_TIMESTAMP >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
      AND t.TRANSCRIPT IS NOT NULL
  ) AS source
  ON target.COMPANY_ID = source.COMPANY_ID 
     AND target.EVENT_TIMESTAMP = source.EVENT_TIMESTAMP
     AND target.FISCAL_PERIOD = source.FISCAL_PERIOD
     AND target.FISCAL_YEAR = source.FISCAL_YEAR
  WHEN NOT MATCHED THEN
    INSERT (COMPANY_ID, CIK, COMPANY_NAME, PRIMARY_TICKER, FISCAL_PERIOD, FISCAL_YEAR, EVENT_TYPE, TRANSCRIPT, EVENT_TIMESTAMP)
    VALUES (source.COMPANY_ID, source.CIK, source.COMPANY_NAME, source.PRIMARY_TICKER, source.FISCAL_PERIOD, source.FISCAL_YEAR, source.EVENT_TYPE, source.TRANSCRIPT, source.EVENT_TIMESTAMP);
END;

-- ============================================================================
-- RESUME THE TASK (tasks are suspended by default)
-- ============================================================================

ALTER TASK HOLLY_DB.STRUCTURED.DAILY_DATA_REFRESH RESUME;

-- ============================================================================
-- VERIFY
-- ============================================================================

SHOW TASKS IN SCHEMA HOLLY_DB.STRUCTURED;
