# Holly Labs — Build an AI Financial Research Agent on Snowflake

**Repo:** https://github.com/sfc-gh-cmoynihan/holly-labs  
**Author:** Colm Moynihan  
**Date:** 25-Aug-2026  
**Version:** 1.0

## Overview

Holly Labs is a hands-on lab that walks you through building a production-grade AI financial research agent on Snowflake. By the end, you'll have a working agent called **Holly** that can answer natural language questions about S&P 500 stock prices, company fundamentals, and foreign exchange rates — with sub-second query performance and smooth charting.

## Use Cases

- **Stock price analysis** — Daily closing prices, comparisons, and performance rankings across S&P 500 companies
- **Foreign exchange rates** — Daily exchange rates for major currency pairs (EUR, GBP, JPY, CHF, CAD, AUD vs USD)
- **Live market context** — Web search fallback for breaking news and current events
- **Interactive dashboards** — Sub-second charting powered by Interactive Tables and Interactive Warehouses

## Prerequisites

- A **Snowflake account** (not a trial account — trial accounts lack access to Marketplace data)
- **ACCOUNTADMIN** role (required to install Marketplace data and create agents)
- A GitHub account (for the Git Workspace integration in Step 2)

## Steps

The lab consists of 8 steps that **must be executed in order** (each step depends on objects created in prior steps):

| Step | Readme | .sql |
|------|--------|------|
| 1 — Install S&P 500 market data from the Snowflake Marketplace | [step1_readme.md](step1_get_data/step1_readme.md) | [verify_data.sql](step1_get_data/verify_data.sql) |
| 2 — Connect this repo to a Snowflake Git Workspace | [step2_readme.md](step2_git_integration/step2_readme.md) | — |
| 3 — Build structured tables from raw Marketplace data | [step3_readme.md](step3_data_engineering/step3_readme.md) | [data_engineering.sql](step3_data_engineering/data_engineering.sql) |
| 4 — Create Semantic Views with verified queries for Cortex Analyst | [step4_readme.md](step4_semantic_views/step4_readme.md) | [create_semantic_views.sql](step4_semantic_views/create_semantic_views.sql) |
| 5 — Interactive Tables & Warehouses for sub-second queries | [step5_readme.md](step5_interactive_tables/step5_readme.md) | [create_interactive.sql](step5_interactive_tables/create_interactive.sql) |
| 6 — Deploy the Holly agent with 5 tools and 15 sample questions | [step6_readme.md](step6_holly_agent/step6_readme.md) | [create_agent.sql](step6_holly_agent/create_agent.sql) |
| 7 — Daily Refresh: Create a task to refresh the data | [step7_readme.md](step7_daily_refresh/step7_readme.md) | [create_task.sql](step7_daily_refresh/create_task.sql) |
| 8 — How to create artifacts and schedule automations | [step8_readme.md](step8_artifacts/step8_readme.md) | — |

## How to Run

1. Complete Step 1 (Marketplace install) and Step 2 (Git Workspace) manually via Snowsight
2. For Steps 3–7, open each `.sql` file in the Git Workspace and run it (use "Run All" in the worksheet)
3. Step 8 is a walkthrough — follow the instructions in the readme

## Architecture

```
Snowflake Marketplace
(S&P 500 + FX data)
       │
       ▼
┌─────────────────────────────────────────────────┐
│ Structured Data (Interactive Tables)            │
│ STOCK_PRICE_TIMESERIES_IT, SP500_COMPANIES,     │
│ FX_RATES_IT                                     │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│              Holly Agent (CoWork)                │
│  Tools: STOCK_PRICES, SP500_COMPANIES,          │
│         FX_RATES, WEB_SEARCH, DATA_TO_CHART     │
└─────────────────────────────────────────────────┘
```
