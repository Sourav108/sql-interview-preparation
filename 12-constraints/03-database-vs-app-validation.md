# 03. Database Constraints vs. Application-Layer Validation

## 1. The Core Architectural Dilemma

A perennial debate in backend system design: *Where should validation live?*
- **Team Application**: *"Validate in Java/Spring Boot! We get friendly error messages and unit tests without hitting the DB."*
- **Team Database**: *"Validate in SQL DDL! If the database allows invalid data, a bug or rogue script will eventually corrupt storage."*

**The Senior Engineer's Answer**: **Defense in Depth — You Need Both.**

---

## 2. Comparison Matrix

```
Client Request
      │
      ▼
┌────────────────────────────────────────────────────────┐
│  Application Layer (Spring Boot / API Gateway)         │
│  - Fast fail: return HTTP 400 with user-friendly error  │
│  - Complex business logic (call external KYC service)   │
│  - Cannot guarantee isolation under concurrency!       │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│  Database Layer (PostgreSQL Schema & Constraints)      │
│  - Authoritative source of truth                       │
│  - ACID transaction isolation guarantees               │
│  - Immune to application race conditions               │
└────────────────────────────────────────────────────────┘
```

| Dimension | Application Validation | Database Constraints |
| :--- | :--- | :--- |
| **User Experience** | Rich, internationalized error messages | Low-level SQL error codes (`23505`, `23514`) |
| **Execution Cost** | Negligible CPU in JVM | Small disk/index check overhead |
| **Race Conditions** | ❌ Vulnerable to Time-of-Check to Time-of-Use (TOCTOU) | ✅ Immune (enforced under table/row locking or index serialization) |
| **Multi-Service Architecture** | Fails if Service B bypasses Service A's validator | Enforced uniformly regardless of which client connects |
| **Direct DB Script Safety** | Completely bypassed during manual DBA patches / migrations | 100% enforced during all DML operations |

---

## 3. The Classic Concurrency Failure Case: TOCTOU

```
Thread 1 (Register user 'bob@acme.com')       Thread 2 (Register user 'bob@acme.com')
──────────────────────────────────────       ──────────────────────────────────────
1. SELECT COUNT(*) WHERE email = 'bob...'
   → returns 0 (Valid!)
                                             2. SELECT COUNT(*) WHERE email = 'bob...'
                                                → returns 0 (Valid!)
3. INSERT INTO users (email) VALUES ('bob')
   → Committed!
                                             4. INSERT INTO users (email) VALUES ('bob')
                                                → Without DB UNIQUE constraint:
                                                  CORRUPT DUPLICATE ROW CREATED!
```

**Takeaway**: No amount of application-level `if (!repository.existsByEmail(email))` checks can replace a `UNIQUE` index constraint in a multi-threaded or multi-instance environment.

---

## 4. Interview Questions

**Q: How do you handle database constraint violations gracefully in a backend microservice?**
**Answer**: Catch the database driver's specific error code at the repository/DAO persistence layer (e.g., PostgreSQL error `23505` for `unique_violation` or `23503` for `foreign_key_violation`). Translate this low-level SQL exception into a domain-specific exception (`DuplicateUserException`), which is then mapped by an HTTP exception handler to a structured `409 Conflict` or `400 Bad Request` API response. Never let raw SQL error details leak to the frontend.
