# Step 5: Interactive Tables & Warehouses

**Time: 10 minutes**

## What You'll Build

Convert stock price data to Interactive Tables served by an Interactive Warehouse for sub-second query response — making Holly's price lookups feel instant.

```mermaid
graph LR
    subgraph "Standard Path"
        T1[Regular Table] -->|~2-5s| W1[Standard Warehouse]
    end

    subgraph "Interactive Table Path"
        IT[Interactive Table<br/>Pre-loaded in memory] -->|~200ms| IW[Interactive Warehouse<br/>Always-hot compute]
    end

    subgraph "Zero-Copy Path"
        ST[Standard Table<br/>Attached to IW] -->|~200ms| IW2[Interactive Warehouse<br/>Caches data automatically]
    end

    subgraph "Result"
        R[Sub-second answers<br/>in CoWork]
    end

    W1 --> R
    IW --> R
    IW2 --> R

    style IT fill:#29B5E8
    style IW fill:#29B5E8
    style ST fill:#71C6E0
    style IW2 fill:#29B5E8
```

## What are Interactive Tables and Warehouses?

**Interactive Tables** are pre-materialized, memory-optimized tables that serve data at sub-second latency. They're ideal for:
- Dashboards and conversational AI where users expect instant responses
- Frequently queried datasets with known access patterns
- Time-series data used in charting and lookups

**Interactive Warehouses** are always-hot compute clusters that keep Interactive Tables loaded in memory. They include:
- Automatic fallback to a standard warehouse for queries that don't hit Interactive Tables
- No cold-start latency — always ready to serve

## Zero-Copy Interactive (New — Sep 2026)

As of September 2026, Interactive Warehouses can also query **standard tables and Iceberg tables directly** — no need to create Interactive Tables first. This is called [Zero-Copy Interactive](https://www.snowflake.com/en/blog/engineering/zero-copy-interactive-analytics/).

**How it works:**
- Attach any existing table to an Interactive Warehouse with `ALTER WAREHOUSE ... ADD TABLES`
- The IW automatically caches the data for sub-second queries
- Attaching is an optimization, not a prerequisite — any table can be queried through an IW

**When to use which:**

| Approach | Best For |
|----------|----------|
| **Interactive Tables** | Dedicated serving with pre-aggregation or specific projections |
| **Zero-Copy Interactive** | Quick low-latency access to existing tables without creating new objects |

This lab uses Interactive Tables for stock prices and FX rates (the primary serving path), and demonstrates Zero-Copy with SP500_COMPANIES as a simpler alternative.

## Instructions

Run `create_interactive.sql`. The script:

1. Creates an Interactive Table from stock price data
2. Creates an Interactive Warehouse (MEDIUM size)
3. Creates a fallback warehouse for non-interactive queries
4. Attaches the Interactive Table to the Interactive Warehouse

## Verify It Worked

```sql
-- Check Interactive Table exists
SHOW INTERACTIVE TABLES IN SCHEMA HOLLY_DB.STRUCTURED;

-- Check Interactive Warehouse
SHOW WAREHOUSES LIKE 'HOLLY_IW';

-- Test query speed (should be <500ms)
SELECT TICKER, DATE, VALUE AS CLOSING_PRICE
FROM HOLLY_DB.STRUCTURED.STOCK_PRICE_TIMESERIES_IT
WHERE TICKER = 'NVDA' AND VARIABLE_NAME = 'Post-Market Close'
ORDER BY DATE DESC
LIMIT 5;
```

## Why Snowflake?

| Traditional Approach | Interactive Tables + Warehouses |
|---------------------|-------------------------------|
| Redis/Memcached caching layer in front of DB | Built-in memory-optimized serving — no cache invalidation |
| Pre-compute materialized views for speed | Interactive Tables refresh automatically from source |
| Manage cache consistency and TTLs | Single source of truth — no stale data |
| Separate hot/cold storage tiers | Automatic fallback from interactive to standard |
| Provision always-on compute for low-latency | Interactive Warehouse with intelligent resource management |

**Key advantage:** Interactive Tables turn any table into a sub-second data source with a single DDL statement. Combined with Interactive Warehouses, Holly answers stock price questions in ~200ms instead of 2-5 seconds — making the conversational experience feel natural and immediate.

## Next Step

[Step 6: Holly Agent →](../step6_holly_agent/)
