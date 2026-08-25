-- Author: Colm Moynihan
-- Date: 25-Aug-2026
-- Version: 1.2

/*
================================================================================
  Step 4: Create Cortex Search Services
  
  Build semantic search over SEC filings and earnings transcripts.
  Uses LARGE_WH (4XL) for fast initial embedding build (~2 min total).
================================================================================
*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE LARGE_WH;

-- ============================================================================
-- 1. SEC FILINGS SEARCH SERVICE
-- ============================================================================

CREATE OR REPLACE CORTEX SEARCH SERVICE HOLLY_DB.SEMI_STRUCTURED.EDGAR_FILINGS_SEARCH
    ON ANNOUNCEMENT_TEXT
    ATTRIBUTES COMPANY_NAME, ANNOUNCEMENT_TYPE, FILED_DATE, FISCAL_PERIOD, FISCAL_YEAR, ITEM_NUMBER, ITEM_TITLE
    WAREHOUSE = LARGE_WH
    TARGET_LAG = '1 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
AS (
    SELECT 
        COMPANY_NAME, ANNOUNCEMENT_TYPE, FILED_DATE, FISCAL_PERIOD, FISCAL_YEAR, 
        ITEM_NUMBER, ITEM_TITLE, ANNOUNCEMENT_TEXT
    FROM HOLLY_DB.SEMI_STRUCTURED.EDGAR_FILINGS
);

-- ============================================================================
-- 2. EARNINGS TRANSCRIPTS SEARCH SERVICE
-- ============================================================================

CREATE OR REPLACE CORTEX SEARCH SERVICE HOLLY_DB.UNSTRUCTURED.PUBLIC_TRANSCRIPTS_SEARCH
    ON TRANSCRIPT_TEXT
    ATTRIBUTES COMPANY_NAME, PRIMARY_TICKER, EVENT_TYPE, FISCAL_PERIOD, FISCAL_YEAR
    WAREHOUSE = LARGE_WH
    TARGET_LAG = '1 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
AS (
    SELECT 
        COMPANY_NAME, PRIMARY_TICKER, FISCAL_PERIOD, FISCAL_YEAR, 
        EVENT_TYPE, EVENT_TIMESTAMP,
        TRANSCRIPT:text::VARCHAR AS TRANSCRIPT_TEXT
    FROM HOLLY_DB.UNSTRUCTURED.PUBLIC_TRANSCRIPTS
    WHERE TRANSCRIPT:text IS NOT NULL
);

-- ============================================================================
-- VERIFY (services will show status = BUILDING initially)
-- ============================================================================

-- Scale down warehouse for ongoing refreshes (saves credits on daily lag)
ALTER CORTEX SEARCH SERVICE HOLLY_DB.SEMI_STRUCTURED.EDGAR_FILINGS_SEARCH SET WAREHOUSE = HOLLY_WH;
ALTER CORTEX SEARCH SERVICE HOLLY_DB.UNSTRUCTURED.PUBLIC_TRANSCRIPTS_SEARCH SET WAREHOUSE = HOLLY_WH;

SHOW CORTEX SEARCH SERVICES IN SCHEMA HOLLY_DB.SEMI_STRUCTURED;
SHOW CORTEX SEARCH SERVICES IN SCHEMA HOLLY_DB.UNSTRUCTURED;
