# Retail SQL Query Optimization and Performance Tuning (PostgreSQL)

Week 3 task: measure typical retail queries, optimize them with indexing, query rewriting,
partitioning and a materialized view, and document before-and-after performance.

## Dataset
50,000 customers, 5,000 products, 20 stores, 100,000 inventory rows, 300,000 orders, 900,000 order items
(generated with `generate_series`, fixed random seed).

## Files
| File | Purpose |
|---|---|
| `schema.sql` | Baseline tables (primary/foreign keys only) |
| `sample_data.sql` | Data generation |
| `baseline_queries.sql` | Seven baseline queries (Q1-Q7) |
| `optimizations.sql` | Indexes, yearly range partitioning, materialized view |
| `optimized_queries.sql` | Rewritten / optimized queries |
| `benchmark.py` | Runs each query 5 times with `EXPLAIN (ANALYZE, BUFFERS)`, stores median |
| `results/` | Raw JSON results, plans and charts |
| `SQL_Query_Optimization_Report.docx` | Full report |

## How to run
```bash
createdb retail
psql -d retail -f schema.sql
psql -d retail -f sample_data.sql
python3 benchmark.py baseline_queries.sql baseline_results.json
psql -d retail -f optimizations.sql
python3 benchmark.py optimized_queries.sql optimized_results.json
```

## Techniques
1. Indexing: single-column, composite `(customer_id, order_date DESC)`, covering (`INCLUDE`)
2. Query rewriting: no `SELECT *`, sargable date ranges, `NOT IN` -> `NOT EXISTS`
3. Partitioning: `orders` range-partitioned by `order_date` (partition pruning)
4. Materialized view: pre-aggregated daily product sales

## Results (median ms, PostgreSQL 16, 2 vCPU)
| Query | Before | After | Improvement |
|---|---|---|---|
| Q1 | 17.156 | 4.765 | 72.2% |
| Q2 | 14.856 | 0.124 | 99.2% |
| Q3 | 137.592 | 44.210 | 67.9% |
| Q4 | 4.598 | 0.168 | 96.3% |
| Q5 | 61.172 | 41.248 | 32.6% |
| Q6 | 47.471 | 39.592 | 16.6% |
| Q7 | 4.823 | 0.127 | 97.4% |

Total: 287.7 ms -> 130.2 ms (54.7% lower).
