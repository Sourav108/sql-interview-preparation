# Mock Interview Round 2: Live Problem Solving (Gaps & Islands)

## 1. Interviewer Prompt
> **Interviewer**: *"We are building a daily streak gamification feature for our learning app. Given a table `user_activity (user_id INT, active_date DATE)`, write a SQL query to return the longest continuous active streak (in consecutive days) for each user."*

---

## 2. Expected Candidate Thinking Process (Applying `R-E-Q-U-I-R-E`)
1. **Read & Clarify**: Are multiple activities on the same day possible? (*Yes $\implies$ Deduplicate with `DISTINCT` first!*).
2. **Establish Pattern**: This is a classic **Gaps and Islands** problem.
3. **Mental Model**: If we subtract `ROW_NUMBER() * INTERVAL '1 day'` from `active_date`, consecutive dates produce a constant date anchor (the island identifier).
4. **Draft Query with CTE**: Group by `user_id` and `island_group`, then aggregate `MAX(streak_length)`.

---

## 3. Candidate Spoken Solution & Code Draft

```sql
WITH deduplicated_activity AS (
    -- Step 1: Deduplicate multiple events on same calendar day
    SELECT DISTINCT user_id, active_date
    FROM user_activity
),
island_groups AS (
    -- Step 2: Generate constant island group anchor via Row-Difference
    SELECT
        user_id,
        active_date,
        active_date - (ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY active_date ASC
        ) * INTERVAL '1 day') AS island_anchor
    FROM deduplicated_activity
),
streak_lengths AS (
    -- Step 3: Compute length of each distinct island
    SELECT
        user_id,
        COUNT(*) AS streak_days,
        MIN(active_date) AS streak_start,
        MAX(active_date) AS streak_end
    FROM island_groups
    GROUP BY user_id, island_anchor
)
-- Step 4: Extract longest streak per user
SELECT
    user_id,
    MAX(streak_days) AS longest_streak_days
FROM streak_lengths
GROUP BY user_id
ORDER BY longest_streak_days DESC;
```

---

## 4. Evaluation Rubric
- **Did candidate ask about duplicate same-day logins?** (Differentiator).
- **Did candidate explain the mathematical intuition of the row-difference technique?** (Differentiator).
- **Time Complexity**: $O(N \log N)$ sort followed by $O(N)$ single pass aggregation.
