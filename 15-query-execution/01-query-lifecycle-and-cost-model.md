# 01. The PostgreSQL Query Engine Lifecycle & Cost Model

## 1. The Query Processing Pipeline

When a client sends a SQL string to PostgreSQL over the wire protocol, it passes through 5 distinct pipeline stages before returning results:

```
Client SQL String
       │
       ▼
┌──────────────┐
│    Parser    │  Checks grammar and syntax; generates an abstract Parse Tree.
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Analyzer   │  Validates table/column names, schemas, and types against the System Catalog.
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Rewriter   │  Applies query rewrite rules (e.g. expands VIEWs into base table queries).
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Planner    │  Generates candidate execution paths; estimates I/O and CPU costs; picks
└──────┬───────┘  the lowest-cost Execution Plan Tree.
       │
       ▼
┌──────────────┐
│   Executor   │  Iterates over the plan tree using the Volcano/Iterator model (fetching
└──────────────┘  tuples via next() calls) and streams results back to the client.
```

---

## 2. The PostgreSQL Cost Model

The Planner evaluates multiple potential execution paths (e.g., Seq Scan vs Index Scan vs Bitmap Scan) and computes a synthetic **cost** in abstract units (where $1.0 = \text{cost of 1 sequential 8KB page fetch}$).

### Core Cost Parameters in `postgresql.conf`

| Parameter | Default Value | Description | Modern SSD Recommendation |
| :--- | :--- | :--- | :--- |
| `seq_page_cost` | `1.0` | Cost of fetching an 8KB disk page sequentially | `1.0` |
| `random_page_cost` | `4.0` | Cost of a non-sequential random 8KB page seek (HDD legacy) | `1.1` (on NVMe/SSD) |
| `cpu_tuple_cost` | `0.01` | CPU cost to process one row | `0.01` |
| `cpu_index_tuple_cost`| `0.005`| CPU cost to process one index entry | `0.005` |
| `cpu_operator_cost` | `0.0025`| CPU cost to evaluate a WHERE clause operator/function | `0.0025` |

> **Critical Performance Rule**: On modern SSD/NVMe cloud instances, setting `random_page_cost = 1.1` prevents PostgreSQL from stubbornly picking slow Sequential Scans when fast random B-Tree seeks are actually available.

---

## 3. Estimated Cost Notation: `(cost=startup..total)`

When reading `EXPLAIN`, every node displays two numbers:
```
cost=4.44..78.12 rows=20 width=36
```
- **Startup Cost (`4.44`)**: The cost incurred before the node can return its **very first row** (e.g., building an in-memory hash table or sorting an array).
- **Total Cost (`78.12`)**: The cumulative cost to execute the node to completion and return all estimated rows.
- **Estimated Rows (`20`)**: The number of rows the planner calculates will pass filters (based on `pg_statistic`).
- **Average Width (`36`)**: The estimated size in bytes of each returned tuple.
