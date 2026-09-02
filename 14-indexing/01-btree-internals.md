# 01. B-Tree Internals and the Physical Cost of Indexing

## 1. Why Indexes Exist

A table in PostgreSQL is physically stored as an unordered collection of 8KB disk pages called a **heap**. Without an index, finding a single row matching `WHERE email = 'alice@example.com'` in a 10-million-row table requires reading every single 8KB page from disk/buffer pool — a **Sequential Scan** ($O(N)$ I/O).

A **B-Tree index** is a self-balancing search tree stored on disk that allows lookups, equality checks, and range queries in $O(\log N)$ page reads.

---

## 2. Physical Layout of a B-Tree Index

```
                              ┌────────────────────────┐
                              │       Root Page        │
                              │ [ Keys: 100  |  500 ]  │
                              └───────┬────────┬───────┘
                     ┌────────────────┘        └────────────────┐
                     ▼                                          ▼
        ┌────────────────────────┐                 ┌────────────────────────┐
        │   Branch/Internal Page │                 │  Branch/Internal Page  │
        │ [ Keys: 25   |   75 ]  │                 │ [ Keys: 250  |  400 ]  │
        └───────┬────────┬───────┘                 └───────┬────────┬───────┘
                │        │                                 │        │
      ┌─────────┘        └─────────┐             ┌─────────┘        └─────────┐
      ▼                            ▼             ▼                            ▼
┌──────────────┐             ┌──────────────┐  ┌──────────────┐             ┌──────────────┐
│  Leaf Page 1 │ ◄─────────► │  Leaf Page 2 │  │  Leaf Page 3 │ ◄─────────► │  Leaf Page 4 │
│ Key: 10 → TID│             │ Key: 50 → TID│  │Key: 200 → TID│             │Key: 450 → TID│
│ Key: 20 → TID│             │ Key: 70 → TID│  │Key: 230 → TID│             │Key: 490 → TID│
└──────────────┘             └──────────────┘  └──────────────┘             └──────────────┘
                                  Leaf pages form a doubly-linked list
```

### Key Properties:
1. **High Fan-Out**: A single 8KB index page holds hundreds of keys. A 3-to-4 level deep B-Tree can index tens of millions of rows.
2. **Leaf Node Doubly-Linked List**: Leaf pages point to their left and right sibling pages, enabling fast range scans (`BETWEEN 50 AND 230`) without re-traversing from the root.
3. **Tuple Identifiers (TID)**: Each index leaf entry contains the indexed column values plus a `TID` pointer `(block_number, offset)` pointing to the exact physical tuple on the heap table page.

---

## 3. The Core Truth: An Index Is Not Free

Adding an index is a deliberate trade-off between **read acceleration** and **write penalty**:

```
                                The Cost of an Index
 ─────────────────────────────────────────────────────────────────────────────────
 Read Advantage:                               Write & Storage Cost:
 - Speeds up equality & range SELECTs          - Every INSERT writes to heap + all indexes
 - Accelerates JOINs and ORDER BY               - UPDATEs to indexed columns write new index tuples
 - Enables Index-Only Scans                     - Index bloat & B-tree page splits
                                                - Consumes shared_buffers & RAM cache space
```

### 3.1 Write Amplification
If a table has 10 indexes, inserting a single row requires writing 1 heap tuple plus 10 index entries across 10 distinct B-Trees.

### 3.2 Page Splits
When inserting a new key into an already full 8KB leaf page, PostgreSQL must allocate a new page, split the keys 50/50, update parent pointers, and write WAL logs — temporarily introducing latency spikes.

---

## 4. Scan Types Explained

When executing a query, the PostgreSQL query planner chooses between three primary access paths:

```
                                Planner Access Paths
                                         │
        ┌────────────────────────────────┼────────────────────────────────┐
        ▼                                ▼                                ▼
  Sequential Scan                   Index Scan                    Bitmap Index Scan
  Scans all heap pages          Seeks B-tree leaf and         Scans B-tree to build bitmap
  Best for low selectivity      fetches heap page for each.   of matching heap pages, sorts
  or small tables (< 100 pages) Best for high selectivity     by physical page number, then
                                (< 1-5% of table)             fetches heap pages in sequential order.
```
