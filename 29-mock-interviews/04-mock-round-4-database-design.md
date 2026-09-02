# Mock Interview Round 4: Database System Architecture (E-Commerce)

## 1. Interviewer Prompt
> **Interviewer**: *"Design the database storage layer for an e-commerce flash sale platform. How do you model inventory, cart checkout, and payments to guarantee zero overselling under 10,000 concurrent checkout attempts per second?"*

---

## 2. Key Architectural Decision Points Defended by Senior Candidate
1. **Isolation of Inventory Write Locks**:
   - Do NOT store `stock_qty` on the `products` table. Create a dedicated `inventory` table so row-level locks do not block catalog readers.
2. **Database-Level Invariant**:
   - Add `CHECK (stock_qty >= 0)` to make negative inventory physically impossible to write.
3. **Atomic Decrement with Row Locks**:
   - Execute:
     ```sql
     UPDATE inventory
     SET stock_qty = stock_qty - :qty
     WHERE product_id = :id AND stock_qty >= :qty;
     ```
   - Check `rows_affected == 1`. If 0, rollback immediately and return HTTP 409.
4. **Idempotency Keys on Payments**:
   - Store unique client `idempotency_key` on `payments` table to prevent double-charging on network retry timeouts.
5. **Historical Price Immutability**:
   - Store `unit_price` directly in `order_items` at checkout timestamp.
