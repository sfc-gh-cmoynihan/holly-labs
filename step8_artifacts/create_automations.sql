-- Author: Colm Moynihan
-- Date: 02-Sep-2026
-- Version: 2.0

/*
================================================================================
  Step 8: Automations
  
  Schedule recurring reports using Snowflake CoWork Automations.
  
  CoWork Automations deliver AI-generated insights on a schedule — each run
  re-executes your question against the latest data and emails you the result
  with a link back to CoWork for follow-up questions.
  
  Prerequisites:
  - Holly agent must be deployed (Step 6)
  - EXECUTE AGENT TASK privilege (granted to PUBLIC by default)
  - A verified email address on your Snowflake account
  
  How to use this file:
  - Open it in Snowsight via the Git Workspace
  - Follow the instructions below to create each automation in CoWork
  - The SQL statements at the end are optional admin commands
================================================================================
*/

-- ============================================================================
-- ADMIN: Verify automations are enabled (granted to PUBLIC by default)
-- ============================================================================

-- Check if EXECUTE AGENT TASK is granted to PUBLIC (automations are enabled by default):
SHOW GRANTS TO ROLE PUBLIC;
SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) WHERE "privilege" = 'EXECUTE AGENT TASK';

-- If automations were previously disabled, re-enable with:
-- GRANT EXECUTE AGENT TASK ON ACCOUNT TO ROLE PUBLIC;

-- To restrict automations to specific roles only:
-- REVOKE EXECUTE AGENT TASK ON ACCOUNT FROM ROLE PUBLIC;
-- GRANT EXECUTE AGENT TASK ON ACCOUNT TO ROLE <role_name>;

/*
================================================================================
  HOW TO CREATE AN AUTOMATION IN COWORK
  
  There are two ways to create an automation:
  
  METHOD 1: Conversationally (recommended)
  -----------------------------------------
  1. Open Snowflake CoWork
  2. Ask Holly the question (copy from the examples below)
  3. After Holly returns the result, say:
     "Send me this report every [schedule]"
  4. CoWork confirms the schedule and first delivery date
  
  METHOD 2: From the Automations tab
  ------------------------------------
  1. In the left navigation, select the Automations tab
  2. Select "Create automation"
  3. Choose "Manually"
  4. Enter the Name, Instructions (the question), and Frequency
  5. Select "Create"
================================================================================
*/

-- ============================================================================
-- AUTOMATION 1: Tech Stock Price Tracker
--
-- Schedule: Every weekday (daily)
-- What it does: Plots MSFT, AMZN, GOOGL, NVDA closing prices over 6 months
-- Maps to Holly sample question #1
-- ============================================================================

/*
  STEP 1: Open CoWork and ask Holly:

    Plot the closing price of MSFT, AMZN, GOOGL, NVDA over the last 6 months

  STEP 2: After the chart renders, say:

    Send me this report every weekday at 8am

  OR create manually in the Automations tab:
    Name:         Tech Stock Tracker
    Instructions: Plot the closing price of MSFT, AMZN, GOOGL, NVDA over the last 6 months
    Frequency:    Daily
*/

-- ============================================================================
-- AUTOMATION 2: Top Performers Chart
--
-- Schedule: Every Monday (weekly)
-- What it does: Bar chart of top 5 S&P 500 performers over 3 months
-- Maps to Holly sample question #2
-- ============================================================================

/*
  STEP 1: Open CoWork and ask Holly:

    Show a bar chart of the top 5 best performing stocks over the last 3 months

  STEP 2: After the chart renders, say:

    Send me this report every Monday at 9am

  OR create manually in the Automations tab:
    Name:         Top Performers Chart
    Instructions: Show a bar chart of the top 5 best performing stocks over the last 3 months
    Frequency:    Weekly (Monday)
*/

-- ============================================================================
-- AUTOMATION 3: NVIDIA Price Check
--
-- Schedule: Every weekday (daily)
-- What it does: Gets latest NVIDIA share price
-- Maps to Holly sample question #3
-- ============================================================================

/*
  STEP 1: Open CoWork and ask Holly:

    What is the latest share price of NVIDIA?

  STEP 2: After the result, say:

    Send me this report every weekday at 7am

  OR create manually in the Automations tab:
    Name:         NVIDIA Price Check
    Instructions: What is the latest share price of NVIDIA?
    Frequency:    Daily
*/

-- ============================================================================
-- AUTOMATION 4: Microsoft vs Google Comparison
--
-- Schedule: Every Monday (weekly)
-- What it does: Compares MSFT and GOOGL stock prices over 6 months
-- Maps to Holly sample question #4
-- ============================================================================

/*
  STEP 1: Open CoWork and ask Holly:

    Compare the stock price of Microsoft and Google over the last 6 months

  STEP 2: After the chart renders, say:

    Send me this report every Monday at 8am

  OR create manually in the Automations tab:
    Name:         Microsoft vs Google Comparison
    Instructions: Compare the stock price of Microsoft and Google over the last 6 months
    Frequency:    Weekly (Monday)
*/

-- ============================================================================
-- MANAGING AUTOMATIONS
--
-- You can manage automations conversationally in CoWork or from the
-- Automations tab in the left navigation.
-- ============================================================================

/*
  Conversational management — just ask CoWork:

    "What automations do I have?"
    "Pause the NVIDIA Price Check report"
    "Resume the NVIDIA Price Check report"
    "Change my Monday report to 7am instead"
    "Delete my weekly top performers report"

  From the Automations tab:
    - View all automations and their run history (last 2 months)
    - Edit, pause, resume, or delete any automation
    - Click into a run to see the full report and ask follow-up questions
*/

-- ============================================================================
-- SUMMARY
-- ============================================================================

/*
  | #  | Automation                    | Question                                                                       | Schedule          |
  |----|-------------------------------|--------------------------------------------------------------------------------|-------------------|
  | 1  | Tech Stock Tracker            | Plot the closing price of MSFT, AMZN, GOOGL, NVDA over the last 6 months      | Weekdays 8am      |
  | 2  | Top Performers Chart          | Show a bar chart of the top 5 best performing stocks over the last 3 months    | Weekly (Mon 9am)  |
  | 3  | NVIDIA Price Check            | What is the latest share price of NVIDIA?                                      | Weekdays 7am      |
  | 4  | Microsoft vs Google           | Compare the stock price of Microsoft and Google over the last 6 months         | Weekly (Mon 8am)  |
*/
