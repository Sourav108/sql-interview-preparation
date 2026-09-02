# Cheatsheet 03: Window Functions & Analytical Query Patterns

## ⚡ 1. Ranking Functions for Input `[100, 100, 90]`

- **`ROW_NUMBER()`**: `1, 2, 3` (Unique sequential integer; breaks ties arbitrarily).
- **`RANK()`**: `1, 1, 3` (Leaves gaps after tied values).
- **`DENSE_RANK()`**: `1, 1, 2` (No gaps; ideal for "Nth highest" values).

---

## ⚡ 2. Window Framing Rules

$$\text{FUNCTION}()\ \mathbf{OVER}\ (\mathbf{PARTITION\ BY}\ \text{p}\ \mathbf{ORDER\ BY}\ \text{o}\ [\mathbf{FRAME}])$$

- **`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`**: Cumulative running total.
- **`ROWS BETWEEN 6 PRECEDING AND CURRENT ROW`**: Rolling 7-day moving window.
- **`ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`**: Full partition (mandatory for `LAST_VALUE()`).
