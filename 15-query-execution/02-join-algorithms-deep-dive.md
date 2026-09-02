# 02. Physical Join Algorithms Deep Dive

The query executor employs three fundamental physical join algorithms:

```
                            Physical Join Algorithms
                                       │
        ┌──────────────────────────────┼──────────────────────────────┐
        ▼                              ▼                              ▼
  Nested Loop Join                 Hash Join                      Merge Join
  Outer loop + Inner seek        Build hash table in RAM        Sort both sides by key,
  Best for small sets            Best for large unindexed sets  then zip together. Best
  or index-backed inner keys     with equi-join (=)             when already sorted by index.
```

---

## 1. Nested Loop Join

### Mechanics
Iterates through every row of the **outer relation**, and for each outer row, scans the **inner relation** for matching rows.

$$\text{Time Complexity} = O(M \times N) \quad \text{(without index)}, \quad O(M \log N) \quad \text{(with index)}$$

### Ideal Scenario
- When the outer relation is small (e.g. 1–100 rows), and the inner relation has an index on the join key.
- For non-equi joins (`<`, `>`, `BETWEEN`, `&&`).

---

## 2. Hash Join

### Mechanics
1. **Build Phase**: Scans the inner table and builds an in-memory hash table on the join key (limited by `work_mem`).
2. **Probe Phase**: Scans the outer table row-by-row, hashes the outer join key, and probes the hash table for instant matches.

$$\text{Time Complexity} = O(M + N)$$

### Memory Spills (Batches)
- If the inner hash table fits in `work_mem`, it executes in **1 batch** in pure RAM.
- If the hash table exceeds `work_mem`, PostgreSQL splits the data into multiple disk-backed batches (`Hash Join: Batches: 4`), increasing I/O latency.

---

## 3. Merge Join

### Mechanics
1. Both relations must be sorted on the join key (either via an existing index or a preceding `Sort` node).
2. The executor advances two pointers simultaneously through both sorted streams (like the merge step in MergeSort).

$$\text{Time Complexity} = O(M \log M + N \log N) \quad \text{(with sort)}, \quad O(M + N) \quad \text{(if already indexed)}$$

### Ideal Scenario
- Very large tables where both inputs are already physically sorted by a B-Tree index on the join key, avoiding memory constraints.

---

## 4. Summary Comparison

| Dimension | Nested Loop | Hash Join | Merge Join |
| :--- | :--- | :--- | :--- |
| **Supported Operators** | Any boolean expression (`=`, `<`, `>`, `&&`) | Equality only (`=`) | Equality (`=`) or Ordering (`<`, `>`) |
| **Memory Requirement** | Minimal (streams tuple by tuple) | High (`work_mem` for hash table) | Moderate (`work_mem` if sort needed) |
| **Pipelining / Startup** | Instant startup (low startup cost) | High startup cost (must build hash table first) | High startup if sorting, instant if indexed |
| **Index Dependency** | Critical on inner table | None | Beneficial |
