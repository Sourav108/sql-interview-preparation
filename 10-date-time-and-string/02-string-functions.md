# 02. String Functions Reference

## 1. Core String Functions

```sql
-- [Standard SQL unless noted]

-- Concatenation
SELECT first_name || ' ' || last_name AS full_name FROM customers;   -- Standard SQL
SELECT CONCAT(first_name, ' ', last_name) FROM customers;            -- Function form (NULLs → empty string in CONCAT)
-- Key difference: || with NULL propagates NULL; CONCAT() treats NULL as ''

-- Length
SELECT LENGTH('hello world');    -- 11 (character count)
SELECT OCTET_LENGTH('hello');    -- 5 (byte count — differs for multi-byte chars)

-- Case conversion
SELECT UPPER('hello'), LOWER('HELLO'), INITCAP('hello world');
-- → 'HELLO', 'hello', 'Hello World'  [INITCAP is PostgreSQL Specific]

-- Trimming whitespace
SELECT TRIM('  hello  ');         -- 'hello'   (both sides)
SELECT LTRIM('  hello  ');        -- 'hello  ' (left only)
SELECT RTRIM('  hello  ');        -- '  hello' (right only)
SELECT TRIM(BOTH '.' FROM '..hello..'); -- 'hello' (trim specific character)

-- Substring extraction
SELECT SUBSTRING('alice@example.com' FROM 1 FOR 5);  -- 'alice' (Standard SQL)
SELECT SUBSTR('alice@example.com', 7);               -- 'example.com' (from position 7)
SELECT LEFT('mechanical keyboard', 10);              -- 'mechanical' [PostgreSQL Specific]
SELECT RIGHT('alice@example.com', 3);                -- 'com' [PostgreSQL Specific]

-- Position / Index
SELECT POSITION('@' IN 'alice@example.com');   -- 6 (Standard SQL)
SELECT STRPOS('alice@example.com', '@');       -- 6 [PostgreSQL Specific]

-- Replace
SELECT REPLACE('hello world', 'world', 'SQL');  -- 'hello SQL'

-- Repeat and Padding
SELECT REPEAT('ab', 3);                     -- 'ababab'
SELECT LPAD('42', 5, '0');                  -- '00042'  [PostgreSQL Specific]
SELECT RPAD('hello', 8, '.');               -- 'hello...' [PostgreSQL Specific]
```

---

## 2. Pattern Matching

```sql
-- LIKE: case-sensitive, Standard SQL
-- % = zero or more characters, _ = exactly one character
SELECT name FROM products WHERE name LIKE 'Mechanical%';    -- starts with
SELECT name FROM products WHERE name LIKE '%Keyboard';      -- ends with
SELECT name FROM products WHERE name LIKE '%USB%';          -- contains
SELECT name FROM products WHERE name LIKE 'USB-_ Hub%';     -- USB-C Hub...

-- [PostgreSQL Specific] ILIKE: case-insensitive
SELECT email FROM customers WHERE email ILIKE '%@EXAMPLE.COM';

-- [PostgreSQL Specific] Regular Expressions
SELECT name FROM products WHERE name ~ 'USB-[A-Z]';        -- regex match (case-sensitive)
SELECT name FROM products WHERE name ~* 'usb-[a-z]';       -- regex match (case-insensitive)
SELECT name FROM products WHERE name !~ 'Cable';            -- does NOT match regex

-- Extract regex match
SELECT REGEXP_SUBSTR('order-12345-shipped', '\d+');         -- '12345' [PostgreSQL Specific]
SELECT (REGEXP_MATCHES('alice@example.com', '(.+)@(.+)'))[1]; -- 'alice'

-- Replace with regex
SELECT REGEXP_REPLACE('Phone: +91-98765-43210', '[^0-9]', '', 'g');
-- → '919876543210' (strip all non-digits, 'g' flag = global replace)
```

---

## 3. String Aggregation

```sql
-- [PostgreSQL Specific] STRING_AGG: concatenate values in a group
SELECT
    o.id,
    STRING_AGG(p.name, ', ' ORDER BY p.name) AS products_ordered
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
JOIN products p ON p.id = oi.product_id
GROUP BY o.id;
-- Output: "Mechanical Keyboard, Wireless Mouse" per order
```

---

## 4. Extracting Email Domain

```sql
-- Real-world string manipulation: extract email domain for segmentation
SELECT
    SUBSTRING(email FROM POSITION('@' IN email) + 1) AS domain,
    COUNT(*)                                          AS user_count
FROM customers
GROUP BY domain
ORDER BY user_count DESC;
-- → example.com: 12
```

---

## 5. Interview Questions

**Q1: What is the difference between `||` and `CONCAT()` for NULL handling?**
The `||` concatenation operator propagates `NULL` — if any operand is `NULL`, the entire expression returns `NULL`. `CONCAT()` treats `NULL` arguments as empty strings and continues concatenation. For user-facing output where some columns may be `NULL` (e.g., middle name), use `COALESCE(middle_name, '')` before `||`, or use `CONCAT()` which handles nulls gracefully.

**Q2: Why can't a `LIKE '%keyword%'` query use a standard B-Tree index?**
A B-Tree index stores values in sorted order and supports seeks using a leftmost prefix. A leading wildcard (`%keyword`) means the matching prefix is unknown — the database cannot determine where in the sorted index to start looking, so it falls back to a sequential scan. Solutions: (1) if only trailing wildcards are needed (`keyword%`), a B-Tree index works. (2) For arbitrary substring search, create a GIN index using the `pg_trgm` extension: `CREATE INDEX ON products USING GIN (name gin_trgm_ops)`.

---

## 6. Further Reading
- [PostgreSQL 18 Documentation: String Functions](https://www.postgresql.org/docs/18/functions-string.html)
- [PostgreSQL 18 Documentation: Pattern Matching](https://www.postgresql.org/docs/18/functions-matching.html)
