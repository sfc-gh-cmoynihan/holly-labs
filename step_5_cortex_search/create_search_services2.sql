-- Author: Colm Moynihan
-- Date: 26-Aug-2026
-- Version: 3.4

/*
================================================================================
  Step 5b: Earnings Transcripts Search Service
  
  Scales HOLLY_WH to X-Large for fast embedding builds, then back to Medium.
  Run this in Session 2 (parallel with create_search_services1.sql).
  Uses HOLLY_WH — both services can build concurrently on the same warehouse.
================================================================================
*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE HOLLY_WH;

-- Scale up for embedding builds
ALTER WAREHOUSE HOLLY_WH SET WAREHOUSE_SIZE = 'X-LARGE';

-- ============================================================================
-- EARNINGS TRANSCRIPTS SEARCH SERVICE
-- ============================================================================

CREATE OR REPLACE CORTEX SEARCH SERVICE HOLLY_DB.UNSTRUCTURED.PUBLIC_TRANSCRIPTS_SEARCH
    ON TRANSCRIPT_TEXT
    ATTRIBUTES COMPANY_NAME, PRIMARY_TICKER, EVENT_TYPE, FISCAL_PERIOD, FISCAL_YEAR
    WAREHOUSE = HOLLY_WH
    TARGET_LAG = '1 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-m-v1.5'
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
-- VERIFY
-- ============================================================================

SHOW CORTEX SEARCH SERVICES IN SCHEMA HOLLY_DB.UNSTRUCTURED;

-- Scale back down
ALTER WAREHOUSE HOLLY_WH SET WAREHOUSE_SIZE = 'MEDIUM';

