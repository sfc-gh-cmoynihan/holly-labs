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

| Step | Folder | Description |
|------|--------|-------------|
| 1 | `step_1_get_data/` | Install S&P 500 market data from the Snowflake Marketplace |
| 2 | `step_2_git_integration/` | Connect this repo to a Snowflake Git Workspace |
| 3 | `step_3_data_engineering/` | Build structured tables from raw Marketplace data |
| 4 | `step_4_semantic_views/` | Create Semantic Views with verified queries for Cortex Analyst |
| 5 | `step_5_cortex_search/` | Create Cortex Search Services over SEC filings and transcripts |
| 6 | `step_6_holly_agent/` | Deploy the Holly agent with 6 tools and sample questions |
| 7 | `step_7_interactive_tables/` | Add Interactive Tables and Interactive Warehouse for sub-second queries |
| 8 | `step_8_daily_refresh/` | Schedule a daily task to keep data fresh |
| 9 | `step_9_artifacts/` | Save and share agent outputs as persistent CoWork artifacts |

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
