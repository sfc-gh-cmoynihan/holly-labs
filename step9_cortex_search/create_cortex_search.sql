-- Author: Colm Moynihan
-- Date: 08-Sep-2026
-- Version: 1.0

/*
================================================================================
  Step 9: Cortex Search
  
  Create public transcripts table from Cybersyn S&P 500 earnings calls and
  build Cortex Search Services for SEC filings and transcripts.
  Runtime: ~15-20 minutes (indexing is the bottleneck)
================================================================================
*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE HOLLY_WH;

CREATE SCHEMA IF NOT EXISTS HOLLY_DB.UNSTRUCTURED;
CREATE SCHEMA IF NOT EXISTS HOLLY_DB.SEMI_STRUCTURED;

-- ============================================================================
-- 1. CREATE PUBLIC TRANSCRIPTS DATA (All S&P 500 transcripts from Cybersyn)
-- ============================================================================

CREATE OR REPLACE TABLE HOLLY_DB.UNSTRUCTURED.PUBLIC_TRANSCRIPTS AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY t.EVENT_TIMESTAMP DESC) AS TRANSCRIPT_ID,
    t.COMPANY_ID,
    t.CIK,
    t.COMPANY_NAME,
    t.PRIMARY_TICKER,
    t.FISCAL_PERIOD,
    t.FISCAL_YEAR,
    t.EVENT_TYPE,
    t.TRANSCRIPT_TYPE,
    t.TRANSCRIPT,
    t.EVENT_TIMESTAMP,
    t.CREATED_AT,
    t.UPDATED_AT
FROM SNOWFLAKE_PUBLIC_DATA_PAID.PUBLIC_DATA.COMPANY_EVENT_TRANSCRIPT_ATTRIBUTES t
INNER JOIN HOLLY_DB.STRUCTURED.SP500_COMPANIES s ON t.PRIMARY_TICKER = s.SYMBOL;

ALTER TABLE HOLLY_DB.UNSTRUCTURED.PUBLIC_TRANSCRIPTS SET CHANGE_TRACKING = TRUE;

-- ============================================================================
-- 2. CREATE CORTEX SEARCH SERVICES
-- ============================================================================

-- Scale up for Cortex Search indexing (most time-consuming step)
ALTER WAREHOUSE HOLLY_WH SET WAREHOUSE_SIZE = '4X-LARGE';

-- 2.1 SEC Filings Search
CREATE OR REPLACE CORTEX SEARCH SERVICE HOLLY_DB.SEMI_STRUCTURED.EDGAR_FILINGS_SEARCH
    ON ANNOUNCEMENT_TEXT
    ATTRIBUTES COMPANY_NAME, ANNOUNCEMENT_TYPE, FILED_DATE, FISCAL_PERIOD, FISCAL_YEAR, ITEM_NUMBER, ITEM_TITLE
    WAREHOUSE = HOLLY_WH
    TARGET_LAG = '1 day'
AS (
    SELECT COMPANY_NAME, ANNOUNCEMENT_TYPE, FILED_DATE, FISCAL_PERIOD, FISCAL_YEAR, ITEM_NUMBER, ITEM_TITLE, ANNOUNCEMENT_TEXT
    FROM HOLLY_DB.SEMI_STRUCTURED.EDGAR_FILINGS
);

-- 2.2 Public Transcripts Search
CREATE OR REPLACE CORTEX SEARCH SERVICE HOLLY_DB.UNSTRUCTURED.PUBLIC_TRANSCRIPTS_SEARCH
    ON TRANSCRIPT_TEXT
    ATTRIBUTES COMPANY_NAME, PRIMARY_TICKER, EVENT_TYPE, FISCAL_PERIOD, FISCAL_YEAR
    WAREHOUSE = HOLLY_WH
    TARGET_LAG = '1 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
AS (
    SELECT TRANSCRIPT_ID, COMPANY_ID, CIK, COMPANY_NAME, PRIMARY_TICKER, FISCAL_PERIOD, FISCAL_YEAR, EVENT_TYPE, EVENT_TIMESTAMP,
           TRANSCRIPT:text::VARCHAR AS TRANSCRIPT_TEXT
    FROM HOLLY_DB.UNSTRUCTURED.PUBLIC_TRANSCRIPTS
    WHERE TRANSCRIPT:text IS NOT NULL
);

-- Scale back down
ALTER WAREHOUSE HOLLY_WH SET WAREHOUSE_SIZE = 'MEDIUM';

-- ============================================================================
-- 3. VERIFY SEARCH SERVICES
-- ============================================================================

SHOW CORTEX SEARCH SERVICES IN DATABASE HOLLY_DB;
