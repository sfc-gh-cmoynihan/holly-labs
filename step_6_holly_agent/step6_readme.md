# Step 6: Holly Agent

**Time: 10 minutes**

## What You'll Build

Create Holly — a financial research agent that orchestrates semantic views, Cortex Search, web search, and charting into a single conversational interface with 24 sample questions.

```mermaid
graph TD
    subgraph "User"
        U[Natural Language Question]
    end

    subgraph "Holly Agent"
        O[Orchestrator<br/>Routes to correct tool]
    end

    subgraph "Tools"
        T1[STOCK_PRICES<br/>Cortex Analyst]
        T2[SP500_COMPANIES<br/>Cortex Analyst]
        T3[FX_RATES<br/>Cortex Analyst]
        T4[SEC_FILINGS_SEARCH<br/>Cortex Search]
        T5[TRANSCRIPTS_SEARCH<br/>Cortex Search]
        T6[WEB_SEARCH<br/>Live web]
        T7[DATA_TO_CHART<br/>Visualization]
    end

    U --> O
    O --> T1
    O --> T2
    O --> T3
    O --> T4
    O --> T5
    O --> T6
    O --> T7

    style O fill:#29B5E8
```

## What is a Cortex Agent?

A Cortex Agent is an AI orchestrator that:
1. **Understands intent** — classifies the user's question
2. **Selects tools** — routes to the right data source (structured vs unstructured)
3. **Generates answers** — combines tool results into coherent responses
4. **Creates visualizations** — renders charts with customizable Vega-Lite templates

## Instructions

Run `create_agent.sql`. The script creates:

1. The Holly agent with 7 tools (3 analyst, 2 search, web search, charting)
2. Chart customization with monotone interpolation for smooth stock charts
3. 24 sample questions spanning all tool types

### 24 Sample Questions

| # | Question | Tool Used |
|---|----------|-----------|
| 1 | Plot the closing price of MSFT, AMZN, GOOGL, NVDA over the last 6 months | STOCK_PRICES + CHART |
| 2 | Show a bar chart of the top 5 best performing stocks over the last 3 months | STOCK_PRICES + CHART |
| 3 | Show a heatmap of monthly returns for MSFT, AMZN, META, NVDA over 12 months | STOCK_PRICES + CHART |
| 4 | What is the latest share price of NVIDIA? | STOCK_PRICES |
| 5 | What is the share price of Amazon? | STOCK_PRICES |
| 6 | Compare the stock price of Microsoft and Google over the last 6 months | STOCK_PRICES |
| 7 | What are the top 5 best performing stocks over the last 3 months? | STOCK_PRICES |
| 8 | Which companies in the S&P 500 are in the semiconductor industry? | SP500_COMPANIES |
| 9 | Which oil and gas companies are in the S&P 500? | SP500_COMPANIES |
| 10 | Is Tesla in the S&P 500? When was it added? | SP500_COMPANIES |
| 11 | What did NVIDIA's latest 10-K say about revenue growth? | SEC_FILINGS_SEARCH |
| 12 | What did Apple disclose about AI in their most recent filing? | SEC_FILINGS_SEARCH |
| 13 | Compare the risk factors in Microsoft and Google's latest 10-K filings | SEC_FILINGS_SEARCH |
| 14 | What did Jensen Huang say about data center demand? | TRANSCRIPTS_SEARCH |
| 15 | What guidance did Amazon give in their latest earnings call? | TRANSCRIPTS_SEARCH |
| 16 | What did Meta's CFO say about capital expenditure? | TRANSCRIPTS_SEARCH |
| 17 | What is the latest news about NVIDIA? | WEB_SEARCH |
| 18 | What happened to Tesla stock today? | WEB_SEARCH |
| 19 | Compare Nvidia's revenue growth vs AMD using their latest filings | SEC_FILINGS_SEARCH (multi) |
| 20 | Plot the stock price of the top 3 semiconductor companies over 6 months | SP500 + STOCK_PRICES + CHART |
| 21 | What is the current EUR/USD exchange rate? | FX_RATES |
| 22 | Plot the EUR/USD exchange rate over the last 6 months | FX_RATES + CHART |
| 23 | What is the USD to EUR exchange rate? | FX_RATES |
| 24 | What is the USD to GBP exchange rate? | FX_RATES |

## Verify It Worked

```sql
-- Check the agent exists
SHOW AGENTS IN SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS;

-- Describe it
DESCRIBE AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.HOLLY;
```

Then open **Snowflake CoWork** and ask: "What is the latest share price of NVIDIA?"

## Why Snowflake?

| Traditional Approach | Snowflake Cortex Agent |
|---------------------|------------------------|
| Build custom LangChain/LlamaIndex orchestration | Declarative agent definition in SQL |
| Manage tool routing logic in application code | Built-in orchestrator with automatic tool selection |
| Integrate separate vector DB, SQL engine, and APIs | Unified platform — search, analyst, and web in one agent |
| Custom chart rendering pipeline | Built-in Vega-Lite chart generation with customization |
| Deploy and scale infrastructure | Serverless — no infrastructure to manage |

**Key advantage:** A single `CREATE AGENT` statement creates a production-ready AI assistant that orchestrates structured data queries, semantic search, web search, and visualization. The `<chart_customization>` block with `vega_template` ensures professional-quality charts with monotone interpolation — the same rendering quality as dedicated charting libraries.

## Next Step

[Step 7: Interactive Tables & Warehouses →](../step_7_interactive_tables/)
