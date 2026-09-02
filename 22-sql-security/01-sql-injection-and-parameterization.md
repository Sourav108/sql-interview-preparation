# 01. SQL Injection Mechanics & Parameterized Prepared Statements

## 1. How SQL Injection Works

SQL Injection occurs when untrusted user input is directly concatenated into a SQL statement string before parsing.

### Vulnerable Toy Example:
```sql
-- Application Code:
"SELECT * FROM users WHERE username = '" + userInput + "' AND password = '" + pass + "'";

-- Malicious Input:
userInput = "admin' --"

-- Evaluated SQL:
SELECT * FROM users WHERE username = 'admin' --' AND password = '...';
-- The trailing -- comments out password verification entirely!
```

---

## 2. The Universal Fix: Parameterized Prepared Statements

Parameterized queries separate the **SQL code structure** from the **literal data values**:

```sql
-- Step 1: Prepare query structure once (Parsed & Planned beforehand)
PREPARE find_user_plan (text, text) AS
    SELECT id, username, email
    FROM users
    WHERE username = $1 AND password_hash = $2;

-- Step 2: Execute with parameters passed over the binary protocol
EXECUTE find_user_plan ('admin', '$2a$12$e8...');
```

### Why Prepared Statements Are 100% Immune to Injection:
1. The SQL query tree is compiled, parsed, and validated **before** parameters are received.
2. Parameters are transmitted over the PostgreSQL binary wire protocol as raw typed byte buffers, not text tokens.
3. It is physically impossible for user data to be interpreted as SQL keywords, quotes, or comment operators.
