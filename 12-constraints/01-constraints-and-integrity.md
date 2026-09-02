# 01. Constraints and Integrity Guardrails

## 1. Problem

Applications crash, concurrent requests race, and background scripts execute directly on production databases. If data validity is only enforced in application code (e.g. Java validation annotations `@NotNull`, `@Min`), bad data inevitably enters the database via race conditions, manual updates, or separate microservices.

**The core architectural rule**: *Enforce business invariant constraints at the database storage layer so corrupt state is physically impossible to persist.*

---

## 2. Standard Constraint Families

```
                               ┌─────────────────────────────────┐
                               │       Database Constraints      │
                               └────────────────┬────────────────┘
                                                │
       ┌──────────────────┬─────────────────────┼─────────────────────┬──────────────────┐
       ▼                  ▼                     ▼                     ▼                  ▼
  NOT NULL           PRIMARY KEY             UNIQUE              FOREIGN KEY           CHECK
Disallows NULLs    Entity identity      Enforces uniqueness   Referential link     Arbitrary boolean
                   (UNIQUE + NOT NULL)  (allows NULLs in SQL) to parent table      expression
```

### 2.1 NOT NULL
Ensures a column cannot hold `NULL`.
```sql
CREATE TABLE accounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_number VARCHAR(32) NOT NULL,
    balance NUMERIC(14, 2) NOT NULL DEFAULT 0.00
);
```

### 2.2 UNIQUE
Enforces distinctness across all non-null values.
```sql
ALTER TABLE accounts ADD CONSTRAINT uq_account_number UNIQUE (account_number);
```
> **Note on NULLs**: Under standard SQL, `UNIQUE` allows multiple `NULL` values. In PostgreSQL 15+, you can write `UNIQUE NULLS NOT DISTINCT` if only one `NULL` should be allowed.

### 2.3 CHECK Constraints
Validates arbitrary row-level expressions upon `INSERT` and `UPDATE`.
```sql
CREATE TABLE products (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    discounted_price NUMERIC(10, 2),
    stock_quantity INT NOT NULL,

    -- Price constraints
    CONSTRAINT chk_price_positive CHECK (price >= 0),
    CONSTRAINT chk_stock_non_negative CHECK (stock_quantity >= 0),
    -- Multi-column relational check
    CONSTRAINT chk_discount_less_than_price CHECK (
        discounted_price IS NULL OR (discounted_price >= 0 AND discounted_price <= price)
    )
);
```

---

## 3. Foreign Key Referential Integrity & Cascades

A Foreign Key (`FK`) guarantees that the value in the referencing child table exists in the referenced parent table.

```sql
CREATE TABLE orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    total NUMERIC(12, 2) NOT NULL,
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);
```

### Cascade Behaviors Comparison

| Action | Behavior on Parent `DELETE` | Typical Use Case |
| :--- | :--- | :--- |
| **`RESTRICT`** (Default) | Rejects parent deletion immediately with error | Financial records, orders with customers |
| **`NO ACTION`** | Rejects parent deletion at end of transaction if deferred | Circular dependencies with deferred constraints |
| **`CASCADE`** | Automatically deletes all referencing child rows | Dependent child entities (e.g. `order_items` when `order` deleted) |
| **`SET NULL`** | Sets foreign key column to `NULL` in child rows | Optional references (e.g. `assigned_agent_id` when agent deleted) |
| **`SET DEFAULT`** | Sets foreign key column to default value | Fallback handler routing |

---

## 4. Constraint Enforcement Timing

Constraints can be evaluated immediately per statement or deferred to `COMMIT`:

```sql
-- Create deferrable constraint
ALTER TABLE order_items
    ADD CONSTRAINT fk_order_items_order
    FOREIGN KEY (order_id) REFERENCES orders (id)
    DEFERRABLE INITIALLY DEFERRED;
```
- `NOT DEFERRABLE` (Default): Checked immediately after every individual statement.
- `DEFERRABLE INITIALLY IMMEDIATE`: Checked after each statement, but transaction can switch to deferred using `SET CONSTRAINTS ALL DEFERRED;`.
- `DEFERRABLE INITIALLY DEFERRED`: Checked exclusively at transaction `COMMIT` time, enabling complex multi-table circular inserts.

---

## 5. Interview Questions & Model Answers

**Q1: Why does PostgreSQL not automatically index foreign key columns?**
**Answer**: Primary keys automatically receive a unique B-Tree index, but foreign keys do not. Creating an index consumes storage and adds write amplification during inserts/updates. PostgreSQL leaves this decision to the engineer. However, in practice, FK columns in high-traffic tables should almost always be indexed to accelerate joins and prevent full-table sequential scans when rows in the parent table are deleted with cascade checks.

**Q2: What happens if an `UPDATE` violates a `CHECK` constraint?**
**Answer**: PostgreSQL aborts the statement immediately with an error (e.g., `ERROR: new row for relation "products" violates check constraint "chk_price_positive"`), rolling back any modifications made within that statement. If inside an active transaction block, the entire transaction enters an aborted state until `ROLLBACK` is issued.

---

## 6. Further Reading
- [PostgreSQL 18 Documentation: Table Constraints](https://www.postgresql.org/docs/18/ddl-constraints.html)
