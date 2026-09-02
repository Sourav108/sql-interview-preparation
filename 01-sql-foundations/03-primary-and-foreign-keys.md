# 03. Primary Keys, Foreign Keys, and Referential Integrity

## 1. Problem

Without unique identifiers and relationship enforcement, data becomes ambiguous ("which customer named 'Smith' placed this order?") and inconsistent (orders pointing to deleted customers). Keys and referential integrity constraints are the mechanisms that prevent these problems at the database layer.

---

## 2. Key Types

### 2.1 Superkey
Any set of columns that uniquely identifies every row. The set `{email}` and the set `{email, first_name}` are both superkeys if email is unique.

### 2.2 Candidate Key
A **minimal** superkey — no proper subset is itself a superkey. These are the eligible choices for the primary key.

### 2.3 Primary Key
One candidate key chosen to be the definitive row identifier. PostgreSQL automatically:
- Enforces `NOT NULL` on all PK columns.
- Creates a unique B-Tree index on the PK column(s).
- Assigns a constraint name (e.g., `users_pkey`).

### 2.4 Natural Key vs. Surrogate Key

| Dimension | Natural Key | Surrogate Key |
| :--- | :--- | :--- |
| **Source** | Exists in the real world (SSN, email, ISBN) | Artificial, system-generated (BIGSERIAL, UUID) |
| **Stability** | May change (user changes email address) | Immutable by design |
| **Size** | Variable; can be wide (composite strings) | Fixed, compact (8 bytes for BIGINT) |
| **Join Efficiency** | String comparisons, wider index pages | Integer equality — fastest join predicate |
| **Leakage Risk** | Exposes business data in URLs/APIs | Opaque identifier |
| **Recommendation** | Use as `UNIQUE` constraint; not PK | Preferred for PK in OLTP systems |

```sql
-- [Standard SQL + PostgreSQL Specific] 
-- Using IDENTITY column (SQL Standard) instead of SERIAL (PostgreSQL legacy)
CREATE TABLE users (
    id         BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email      VARCHAR(255) NOT NULL UNIQUE,  -- Natural candidate key as UNIQUE constraint
    first_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
```

---

## 3. Foreign Keys and Referential Integrity

A **foreign key** declares that the values in one column (or set of columns) must match a value that exists in the referenced table's primary or unique key column(s).

```
users (id)  ←────── orders (user_id)
             "Every order must belong to an existing user."
```

```sql
CREATE TABLE orders (
    id         BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id    BIGINT          NOT NULL,
    status     VARCHAR(20)     NOT NULL DEFAULT 'PENDING',
    total      NUMERIC(12, 2)  NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_orders_user
        FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE RESTRICT   -- Prevent deleting a user who has orders
        ON UPDATE CASCADE    -- If user.id changes (rare), propagate
);
```

### 3.1 Cascade Options

| Option | `ON DELETE` Behavior | Use Case |
| :--- | :--- | :--- |
| `RESTRICT` (default) | Prevents deletion of parent if children exist | Protecting financial records |
| `CASCADE` | Deletes child rows when parent is deleted | Soft ownership (e.g., `order_items` when `order` is deleted) |
| `SET NULL` | Sets FK column to `NULL` in child rows | Optional relationships (e.g., `assigned_agent_id`) |
| `SET DEFAULT` | Sets FK column to its `DEFAULT` value | Rare; requires a meaningful default referencing a valid parent |
| `NO ACTION` | Like `RESTRICT` but deferred to end of statement | Fine-grained deferred constraint evaluation |

---

## 4. Composite Primary Keys

Used in junction tables (many-to-many) and compound identifiers:

```sql
CREATE TABLE order_items (
    order_id    BIGINT         NOT NULL,
    product_id  BIGINT         NOT NULL,
    quantity    INTEGER        NOT NULL DEFAULT 1,
    unit_price  NUMERIC(10, 2) NOT NULL,

    PRIMARY KEY (order_id, product_id),

    CONSTRAINT fk_orderitems_order
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,

    CONSTRAINT fk_orderitems_product
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
);
```

---

## 5. Edge Cases and Traps

### 5.1 Foreign Keys and NULLs
A nullable FK column (`user_id BIGINT`) can store `NULL`, which means "no associated user." The FK constraint is only checked when the value is not `NULL`. This allows optional relationships.

### 5.2 Self-Referencing Foreign Key
```sql
CREATE TABLE categories (
    id        BIGINT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name      TEXT    NOT NULL,
    parent_id BIGINT  REFERENCES categories (id) ON DELETE RESTRICT
);
```
`parent_id = NULL` denotes a root-level category.

### 5.3 Deferred Constraints
```sql
-- [PostgreSQL Specific]
ALTER TABLE order_items
    ALTER CONSTRAINT fk_orderitems_order DEFERRABLE INITIALLY DEFERRED;
```
Deferred constraints are only enforced at transaction `COMMIT` time, allowing temporary violations during bulk inserts.

---

## 6. Interview Questions

**Q1: What is the difference between a candidate key and a primary key?**
A candidate key is any minimal set of columns that uniquely identifies every row. A primary key is the one candidate key chosen as the official row identifier. A table may have multiple candidate keys (e.g., both `id` and `email` uniquely identify a user) but only one primary key. Non-chosen candidate keys should be enforced with `UNIQUE NOT NULL` constraints.

**Q2: When would you use a natural key as a primary key?**
Rarely in modern OLTP systems. Natural keys (email, SSN, product SKU) create risk because real-world values can change (email addresses are reassigned, SSNs can be corrected). A surrogate BIGINT or UUID surrogate key is stable, compact, and safe for join predicates. Keep natural keys as `UNIQUE` constraints that enforce business uniqueness but do not serve as the FK join target.

**Q3: What happens to a foreign key constraint when you delete the parent row with `ON DELETE RESTRICT`?**
PostgreSQL raises an error: `ERROR: update or delete on table "users" violates foreign key constraint on table "orders"`. The parent row deletion is blocked until all referencing child rows are removed or the FK values are updated. This prevents orphaned child records and enforces referential integrity at the database layer.

**Q4: Why does adding an index on the FK column matter for performance?**
PostgreSQL does *not* automatically create an index on the foreign key column in the child table (it only creates one on the parent's referenced column via the unique/PK constraint). Without an index on `orders.user_id`, a query like `SELECT * FROM orders WHERE user_id = ?` or an `ON DELETE CASCADE` operation requires a full sequential scan of `orders`. Always index FK columns in high-traffic child tables.

---

## 7. Further Reading
- [PostgreSQL 18 Documentation: Constraints](https://www.postgresql.org/docs/18/ddl-constraints.html)
- [PostgreSQL 18 Documentation: Indexes on FK Columns](https://www.postgresql.org/docs/18/indexes-intro.html)
