# Holly Labs — Build an AI Financial Research Agent on Snowflake

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
| 1 — Get Data | [step1](step_1_get_data/step1_readme.md) | [get_data.sql](step_1_get_data/get_data.sql) |
| 2 — Git Integration | [step2](step_2_git_integration/step2_readme.md) | — |
| 3 — Data Engineering | [step3](step_3_data_engineering/step3_readme.md) | [data_engineering.sql](step_3_data_engineering/data_engineering.sql) |
| 4 — Semantic Views | [step4](step_4_semantic_views/step4_readme.md) | [create_semantic_views.sql](step_4_semantic_views/create_semantic_views.sql) |
| 5 — Cortex Search | [step5](step_5_cortex_search/step5_readme.md) | [create_search_services.sql](step_5_cortex_search/create_search_services.sql) |
| 6 — Holly Agent | [step6](step_6_holly_agent/step6_readme.md) | [create_agent.sql](step_6_holly_agent/create_agent.sql) |
| 7 — Interactive Tables | [step7](step_7_interactive_tables/step7_readme.md) | [create_interactive.sql](step_7_interactive_tables/create_interactive.sql) |
| 8 — Daily Refresh: Create a task to refresh the data from the marketplace | [step8](step_8_daily_refresh/step8_readme.md) | [create_task.sql](step_8_daily_refresh/create_task.sql) |
| 9 — Artifacts: Create artifacts and create automations | [step9](step_9_artifacts/step9_readme.md) | — |

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
