-- Author: Colm Moynihan
-- Date: 26-Aug-2026
-- Version: 1.5

/*
================================================================================
  Step 5: Create Cortex Search Services
  
  Build semantic search over SEC filings and earnings transcripts.
  Limits source data to last 12 months for fast initial builds (~2 min).
  Temporarily scales HOLLY_AD_WH to 4X-Large for fast embedding builds.
  
  PERFORMANCE NOTE: Run both CREATE statements in PARALLEL (two separate
  worksheets/sessions) to halve build time.
================================================================================
*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE HOLLY_AD_WH;

-- Scale up adaptive warehouse for fast embedding build
ALTER WAREHOUSE HOLLY_AD_WH SET MAX_QUERY_PERFORMANCE_LEVEL = '4X-Large';

-- ============================================================================
-- 1. SEC FILINGS SEARCH SERVICE (run in Session 1)
-- ============================================================================

CREATE OR REPLACE CORTEX SEARCH SERVICE HOLLY_DB.SEMI_STRUCTURED.EDGAR_FILINGS_SEARCH
    ON ANNOUNCEMENT_TEXT
    ATTRIBUTES COMPANY_NAME, ANNOUNCEMENT_TYPE, FILED_DATE, FISCAL_PERIOD, FISCAL_YEAR, ITEM_NUMBER, ITEM_TITLE
    WAREHOUSE = HOLLY_AD_WH
    TARGET_LAG = '1 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-m-v2.0'
AS (
    SELECT 
        COMPANY_NAME, ANNOUNCEMENT_TYPE, FILED_DATE, FISCAL_PERIOD, FISCAL_YEAR, 
        ITEM_NUMBER, ITEM_TITLE, ANNOUNCEMENT_TEXT
    FROM HOLLY_DB.SEMI_STRUCTURED.EDGAR_FILINGS
    WHERE FILED_DATE >= DATEADD(YEAR, -1, CURRENT_DATE())
);

-- ============================================================================
-- 2. EARNINGS TRANSCRIPTS SEARCH SERVICE (run in Session 2, parallel)
-- ============================================================================

CREATE OR REPLACE CORTEX SEARCH SERVICE HOLLY_DB.UNSTRUCTURED.PUBLIC_TRANSCRIPTS_SEARCH
    ON TRANSCRIPT_TEXT
    ATTRIBUTES COMPANY_NAME, PRIMARY_TICKER, EVENT_TYPE, FISCAL_PERIOD, FISCAL_YEAR
    WAREHOUSE = HOLLY_AD_WH
    TARGET_LAG = '1 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-m-v2.0'
AS (
    SELECT 
        COMPANY_NAME, PRIMARY_TICKER, FISCAL_PERIOD, FISCAL_YEAR, 
        EVENT_TYPE, EVENT_TIMESTAMP,
        LEFT(TRANSCRIPT:text::VARCHAR, 8000) AS TRANSCRIPT_TEXT
    FROM HOLLY_DB.UNSTRUCTURED.PUBLIC_TRANSCRIPTS
    WHERE TRANSCRIPT:text IS NOT NULL
      AND EVENT_TIMESTAMP >= DATEADD(YEAR, -1, CURRENT_DATE())
);

-- ============================================================================
-- VERIFY (services will show status = BUILDING initially)
-- Wait for BOTH services to reach ACTIVE before scaling down.
-- ============================================================================

SHOW CORTEX SEARCH SERVICES IN SCHEMA HOLLY_DB.SEMI_STRUCTURED;
SHOW CORTEX SEARCH SERVICES IN SCHEMA HOLLY_DB.UNSTRUCTURED;

-- Scale back down AFTER both services are ACTIVE
ALTER WAREHOUSE HOLLY_AD_WH SET MAX_QUERY_PERFORMANCE_LEVEL = 'Medium';
