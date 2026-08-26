-- Author: Colm Moynihan
-- Date: 26-Aug-2026
-- Version: 3.2

/*
================================================================================
  Step 5b: Earnings Transcripts Search Service
  
  Run this in Session 2 (parallel with create_search_services1.sql).
  Uses a dedicated warehouse HOLLY_AD_WH_2 so both services build
  concurrently without contention.
================================================================================
*/

USE ROLE ACCOUNTADMIN;

-- Create a second adaptive warehouse for parallel embedding builds
CREATE WAREHOUSE IF NOT EXISTS HOLLY_AD_WH_2
    WAREHOUSE_TYPE = 'STANDARD'
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

ALTER WAREHOUSE HOLLY_AD_WH_2 SET MAX_QUERY_PERFORMANCE_LEVEL = 'Large';

USE WAREHOUSE HOLLY_AD_WH_2;

-- ============================================================================
-- EARNINGS TRANSCRIPTS SEARCH SERVICE
-- ============================================================================

CREATE OR REPLACE CORTEX SEARCH SERVICE HOLLY_DB.UNSTRUCTURED.PUBLIC_TRANSCRIPTS_SEARCH
    ON TRANSCRIPT_TEXT
    ATTRIBUTES COMPANY_NAME, PRIMARY_TICKER, EVENT_TYPE, FISCAL_PERIOD, FISCAL_YEAR
    WAREHOUSE = HOLLY_AD_WH_2
    TARGET_LAG = '1 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
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

-- Scale back down and suspend AFTER service is ACTIVE
ALTER WAREHOUSE HOLLY_AD_WH_2 SET MAX_QUERY_PERFORMANCE_LEVEL = 'Medium';
