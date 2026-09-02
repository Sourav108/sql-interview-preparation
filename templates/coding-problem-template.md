# Coding Problem Template: [Problem Name]

- **Difficulty**: Easy / Medium / Hard
- **Domain**: E-Commerce / Fintech / Analytics / Social / Subscriptions / Telemetry
- **Key Concepts**: Joins / Aggregation / Window Functions / CTEs / NULL Semantics / Keyset

---

## 1. Problem Statement
<!-- Clear, concise description of the business question -->

## 2. Relational Schema
```sql
CREATE TABLE table_name (
    id BIGINT PRIMARY KEY,
    -- columns
);
```

## 3. Sample Data
```sql
INSERT INTO table_name VALUES
-- sample rows
;
```

## 4. Expected Output
| col1 | col2 |
| :--- | :--- |
| ... | ... |

## 5. Hints
1. *Hint 1...*
2. *Hint 2...*

## 6. Naive Solution
```sql
-- Initial / baseline query
```

## 7. Optimal Solution
```sql
-- Clean, optimal, production-grade query
```

## 8. Alternative Solution (PostgreSQL Specific or Alternative Pattern)
```sql
-- Alternative approach (e.g. DISTINCT ON vs Window Function)
```

## 9. Performance & Complexity Analysis
- **Time Complexity**: $O(...)$
- **Space Complexity**: $O(...)$
- **Execution Plan Node Summary**: (e.g. `HashAggregate`, `WindowAgg`, `Index Scan`)

## 10. Common Traps & Edge Cases
- Edge cases: Empty sets, NULL handling, ties in rankings.

## 11. Interviewer Follow-Up Questions
- *"How would you handle ties?"*
- *"How would this scale if the table had 1 billion rows?"*
