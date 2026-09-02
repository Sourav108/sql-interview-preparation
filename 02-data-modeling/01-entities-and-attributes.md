# 01. Entities, Attributes, and Relationships

## 1. Problem

A business stakeholder says: *"We have customers who place orders for products."* Your job as a database engineer is to convert this plain English description into precise relational tables with enforced integrity.

---

## 2. Concept: The Three Building Blocks

### 2.1 Entity
A **thing** the business cares about and needs to store data about.

- A **Customer** is an entity.
- An **Order** is an entity.
- A **Product** is an entity.

Entities become **tables**.

### 2.2 Attribute
A **property or characteristic** of an entity.

- A Customer has: `email`, `first_name`, `last_name`, `created_at`.
- An Order has: `total_amount`, `status`, `placed_at`.

Attributes become **columns**.

### 2.3 Relationship
A **verb** connecting two entities.

- A Customer **places** an Order.
- An Order **contains** Products.

Relationships determine **foreign keys** and **junction tables**.

---

## 3. Mental Model: From English to Tables

```
Business Statement:
"A customer places one or more orders.
 Each order contains one or more products.
 A product can appear in many orders."

Parsing:
  Nouns (Entities)   : Customer, Order, Product
  Verbs (Relationships): places (Customer → Order), contains (Order ↔ Product)
  Cardinality        : Customer 1──N Order
                       Order    M──N Product  → needs junction table: OrderItem

Result Schema:
  customers      (id, email, first_name, created_at)
  orders         (id, customer_id→customers, status, total, placed_at)
  products       (id, sku, name, price, stock_qty)
  order_items    (order_id→orders, product_id→products, quantity, unit_price)
```

---

## 4. Cardinality Types

### 4.1 One-to-One (1:1)
Each row in Table A corresponds to at most one row in Table B, and vice versa.

**Example**: A `users` row has at most one `user_profiles` row with extended demographic data.

```sql
CREATE TABLE users (
    id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE user_profiles (
    user_id         BIGINT       PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    bio             TEXT,
    profile_picture TEXT,
    date_of_birth   DATE
);
```

The FK column (`user_id`) in the child table is *also* the PK — enforcing strict 1:1.

### 4.2 One-to-Many (1:N) — Most Common
One row in the parent table can have many rows in the child table.

**Example**: One `customer` can have many `orders`.

```sql
-- FK in the "many" side (orders) pointing to the "one" side (customers)
CREATE TABLE orders (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers (id) ON DELETE RESTRICT,
    placed_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

⚠️ **Row Multiplication Trap**: When you `JOIN customers TO orders`, each customer row is duplicated for every associated order. If you then `SUM` a customers column across this join, you multiply it N times. This is covered deeply in [Module 04 — Joins](../04-joins/).

### 4.3 Many-to-Many (M:N)
Many rows in Table A relate to many rows in Table B. Cannot be modeled with just a FK — requires a **junction (associative) table**.

**Example**: Many `orders` contain many `products`.

```sql
CREATE TABLE order_items (
    order_id    BIGINT         NOT NULL REFERENCES orders (id)   ON DELETE CASCADE,
    product_id  BIGINT         NOT NULL REFERENCES products (id) ON DELETE RESTRICT,
    quantity    INTEGER        NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),

    PRIMARY KEY (order_id, product_id)
);
```

The junction table `order_items` has:
- A **composite PK** preventing the same product from appearing twice in one order.
- **FK to each parent** enforcing referential integrity on both sides.
- **Its own attributes** (`quantity`, `unit_price`) — this is an *associative entity*.

---

## 5. Identifying vs. Non-Identifying Relationships

| Type | Meaning | FK in Child | Example |
| :--- | :--- | :--- | :--- |
| **Identifying** | Child's PK includes the parent's FK | Part of PK | `order_items(order_id, product_id)` — child identity depends on both parents |
| **Non-Identifying** | Child has its own independent PK | Separate from PK | `orders(id)` with `orders.customer_id` — an order has its own identity regardless of which customer placed it |

---

## 6. Interview Questions

**Q1: How do you model a many-to-many relationship?**
A many-to-many relationship requires a **junction (associative) table**. The junction table holds foreign keys referencing each of the two parent tables. Its primary key is typically a composite of those two FK columns, preventing duplicate associations. If the relationship itself has attributes (e.g., `quantity` in `order_items`), the junction becomes a full entity.

**Q2: When should the junction table use a composite PK vs. a surrogate PK?**
A composite PK (`order_id, product_id`) is preferable when the relationship itself is the identity — it prevents duplicates at the constraint level and avoids creating an extra index. A surrogate PK on the junction table is warranted when the association needs to be referenced by other tables (e.g., `shipment_items` references a specific `order_item_id`). In that case, add a `UNIQUE` constraint on `(order_id, product_id)` to maintain business uniqueness.

**Q3: What is the risk of a 1:N join in aggregation queries?**
When you join a parent table (1 side) to a child table (N side), each parent row is replicated N times. If you then `SUM` a parent-side column (e.g., `shipping_cost` on the order), it gets multiplied by the number of matching child rows. The fix is to aggregate the child data first in a CTE or subquery before joining to the parent.

---

## 7. Further Reading
- [PostgreSQL 18 Documentation: Table Basics](https://www.postgresql.org/docs/18/ddl-basics.html)
- Chen, P.P. (1976). *The Entity-Relationship Model — Toward a Unified View of Data*. ACM TODS.
