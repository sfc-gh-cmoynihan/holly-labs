# Step 3: Data Engineering

**Time: 10 minutes**

## What You'll Build

Create a dedicated database with structured tables optimized for AI workloads — stock prices, SEC filings, and earnings transcripts.

```mermaid
graph TD
    subgraph Marketplace
        M1[STOCK_PRICE_TIMESERIES]
        M4[FX_RATES_TIMESERIES]
    end

    subgraph HOLLY_DB
        subgraph StructuredSchema [STRUCTURED schema]
            S1[SP500_COMPANIES]
            S2[STOCK_PRICE_TIMESERIES]
            S3[FX_RATES]
        end
    end

    M1 -->|CTAS| S2
    M4 -->|CTAS| S3
```

## Instructions

Run `data_engineering.sql` in Snowsight. The script:

1. Creates `HOLLY_DB` database with STRUCTURED schema
2. Loads S&P 500 companies reference table (503 companies)
3. Creates stock price table filtered to S&P 500 tickers
4. Creates FX rates table for major currency pairs
5. Enables change tracking for incremental refresh

### Key Design Decisions

- **S&P 500 companies** — static reference table with all current index constituents
- **Clustering** on `(TICKER, DATE)` for fast time-series lookups
- **Change tracking** enables incremental refresh without full rebuilds

## Verify It Worked

```sql
SELECT 'SP500_COMPANIES' AS TABLE_NAME, COUNT(*) AS ROWS FROM HOLLY_DB.STRUCTURED.SP500_COMPANIES
UNION ALL
SELECT 'STOCK_PRICE_TIMESERIES', COUNT(*) FROM HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES
UNION ALL
SELECT 'FX_RATES', COUNT(*) FROM HOLLY_DB.STRUCTURED.FX_RATES;
```

Expected: ~503 companies, ~10M price rows, ~500K+ FX rate rows.

## Why Snowflake?

| Traditional Approach | Snowflake |
|---------------------|-----------|
| ETL pipelines with Spark/Airflow | Single CTAS statement — transforms at query time |
| Manual partitioning for performance | Automatic micro-partitioning with clustering |
| CDC pipelines for change detection | Built-in change tracking with zero config |
| Separate systems for different data types | One platform for all structured data |

**Key advantage:** A single SQL script creates production-ready, AI-optimized tables from marketplace data. No Spark cluster, no ETL orchestration, no schema management. The clustering and change tracking are the only setup needed for high-performance AI workloads.

## Next Step

[Step 4: Semantic Views →](../step4_semantic_views/)
