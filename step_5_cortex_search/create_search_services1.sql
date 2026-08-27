-- Author: Colm Moynihan
-- Date: 26-Aug-2026
-- Version: 3.4

/*
================================================================================
  Step 5a: SEC Filings Search Service
  
  Scales HOLLY_WH to X-Large for fast embedding builds, then back to Medium.
  Run this in Session 1. Run create_search_services2.sql in Session 2
  simultaneously for parallel builds (~2 min total).
================================================================================
*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE HOLLY_WH;

-- Scale up for embedding builds
ALTER WAREHOUSE HOLLY_WH SET WAREHOUSE_SIZE = 'X-LARGE';

-- ============================================================================
-- SEC FILINGS SEARCH SERVICE
-- ============================================================================

CREATE OR REPLACE CORTEX SEARCH SERVICE HOLLY_DB.SEMI_STRUCTURED.EDGAR_FILINGS_SEARCH
    ON ANNOUNCEMENT_TEXT
    ATTRIBUTES COMPANY_NAME, ANNOUNCEMENT_TYPE, FILED_DATE, FISCAL_PERIOD, FISCAL_YEAR, ITEM_NUMBER, ITEM_TITLE
    WAREHOUSE = HOLLY_WH
    TARGET_LAG = '1 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-m-v1.5'
AS (
    SELECT 
        COMPANY_NAME, ANNOUNCEMENT_TYPE, FILED_DATE, FISCAL_PERIOD, FISCAL_YEAR, 
        ITEM_NUMBER, ITEM_TITLE, LEFT(ANNOUNCEMENT_TEXT, 8000) AS ANNOUNCEMENT_TEXT
    FROM HOLLY_DB.SEMI_STRUCTURED.EDGAR_FILINGS
    WHERE FILED_DATE >= DATEADD(YEAR, -1, CURRENT_DATE())
);

-- ============================================================================
-- VERIFY
-- ============================================================================

SHOW CORTEX SEARCH SERVICES IN SCHEMA HOLLY_DB.SEMI_STRUCTURED;

-- Scale back down
ALTER WAREHOUSE HOLLY_WH SET WAREHOUSE_SIZE = 'MEDIUM';

