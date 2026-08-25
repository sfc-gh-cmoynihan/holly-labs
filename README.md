# Holly Labs — Build an AI Financial Research Agent on Snowflake

**Repo:** https://github.com/sfc-gh-cmoynihan/holly-labs  
**Author:** Colm Moynihan  
**Date:** 25-Aug-2026  
**Version:** 1.0

## Overview

Holly Labs is a hands-on lab that walks you through building a production-grade AI financial research agent on Snowflake. By the end, you'll have a working agent called **Holly** that can answer natural language questions about S&P 500 stock prices, SEC filings, and earnings call transcripts — with sub-second query performance and smooth charting.

## Use Cases

- **Stock price analysis** — Daily closing prices, comparisons, and performance rankings across S&P 500 companies
- **SEC filing research** — Semantic search over 10-K, 10-Q, and 8-K filing content from EDGAR
- **Earnings call intelligence** — Search transcripts for management commentary, guidance, and strategic signals
- **Live market context** — Web search fallback for breaking news and current events
- **Interactive dashboards** — Sub-second charting powered by Interactive Tables and Interactive Warehouses

## Prerequisites

- A **Snowflake account** (not a trial account — trial accounts lack access to Marketplace data)
- **ACCOUNTADMIN** role (required to install Marketplace data and create agents)
- A GitHub account (for the Git Workspace integration in Step 2)

## Steps

The lab consists of 9 steps that **must be executed in order** (each step depends on objects created in prior steps):

| Step | Readme | .sql |
|------|--------|------|
| 1 — Install S&P 500 market data from the Snowflake Marketplace | [step1.md](step_1_get_data/step1.md) | [get_data.sql](step_1_get_data/get_data.sql) |
| 2 — Connect this repo to a Snowflake Git Workspace | [step2.md](step_2_git_integration/step2.md) | — |
| 3 — Build structured tables from raw Marketplace data | [step3.md](step_3_data_engineering/step3.md) | [data_engineering.sql](step_3_data_engineering/data_engineering.sql) |
| 4 — Create Semantic Views with verified queries for Cortex Analyst | [step4.md](step_4_semantic_views/step4.md) | [create_semantic_views.sql](step_4_semantic_views/create_semantic_views.sql) |
| 5 — Create Cortex Search Services over SEC filings and transcripts | [step5.md](step_5_cortex_search/step5.md) | [create_search_services.sql](step_5_cortex_search/create_search_services.sql) |
| 6 — Deploy the Holly agent with 6 tools and sample questions | [step6.md](step_6_holly_agent/step6.md) | [create_agent.sql](step_6_holly_agent/create_agent.sql) |
| 7 — Add Interactive Tables and Interactive Warehouse for sub-second queries | [step7.md](step_7_interactive_tables/step7.md) | [create_interactive.sql](step_7_interactive_tables/create_interactive.sql) |
| 8 — Daily Refresh: Create a task to refresh the data | [step8.md](step_8_daily_refresh/step8.md) | [create_task.sql](step_8_daily_refresh/create_task.sql) |
| 9 — How to create artifacts and schedule automations | [step9.md](step_9_artifacts/step9.md) | — |

## How to Run

1. Complete Step 1 (Marketplace install) and Step 2 (Git Workspace) manually via Snowsight
2. For Steps 3–8, open each `.sql` file in the Git Workspace and run it (use "Run All" in the worksheet)
3. Step 9 is a walkthrough — follow the instructions in `step_9_artifacts/step9_readme.md`

## Architecture

```
Snowflake Marketplace          Cortex Search Services
(S&P 500 data)                 (SEC filings + transcripts)
       │                              │
       ▼                              ▼
┌─────────────────┐           ┌──────────────────┐
│ Structured Data │           │ Unstructured Data│
│ (Interactive    │           │ (Embeddings +    │
│  Tables)        │           │  Vector Index)   │
└────────┬────────┘           └────────┬─────────┘
         │                             │
         ▼                             ▼
┌─────────────────────────────────────────────────┐
│              Holly Agent (CoWork)                │
│  Tools: STOCK_PRICES, SP500_COMPANIES,          │
│         SEC_FILINGS_SEARCH, TRANSCRIPTS_SEARCH, │
│         WEB_SEARCH, DATA_TO_CHART               │
└─────────────────────────────────────────────────┘
```
