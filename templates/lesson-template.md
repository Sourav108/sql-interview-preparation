# Standard Technical Lesson Template

# [Topic Title]

## 1. Problem
<!-- What business or data retrieval requirement does this solve? -->

## 2. Concept
<!-- Theoretical definition, relational semantics, and formal rules -->

## 3. Mental Model
<!-- Conceptual visual model, ASCII diagram, or relational intuition -->

## 4. Example Schema
```sql
CREATE TABLE example_entity (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

## 5. Sample Data
```sql
INSERT INTO example_entity (name, created_at) VALUES
('Sample A', '2026-09-01 10:00:00+00'),
('Sample B', '2026-09-02 11:30:00+00');
```

## 6. SQL
```sql
-- Solution query implementing the requirement
SELECT id, name
FROM example_entity
ORDER BY created_at DESC;
```

## 7. Expected Result
| id | name |
| :-: | :--- |
| 2 | Sample B |
| 1 | Sample A |

## 8. Edge Cases
<!-- Boundary conditions, empty sets, ties, zero division -->

## 9. NULL Behavior
<!-- How NULL values interact with this operation -->

## 10. Duplicate Behavior
<!-- How duplicate values or ties are resolved -->

## 11. How the Database Executes It
<!-- Internal parser, planner, and executor mechanics -->

## 12. Performance
<!-- Time/space complexity, index support, and memory considerations -->

## 13. Common Mistakes
<!-- Anti-patterns, trap questions, and junior vs senior implementations -->

## 14. Interview Questions
<!-- Realistic interview questions on this topic -->

## 15. Interview Answer
<!-- Model senior engineer response -->

## 16. Exercises
<!-- 2-3 unsolved practice problems -->

## 17. Solutions
<!-- Verified SQL solutions for the exercises -->

## 18. Further Reading
<!-- PostgreSQL official documentation references -->
