# Module 24: Production SQL & Database Performance Debugging

## Learning Objectives

By the end of this module, you will be able to:
- Apply the 7-step production triage framework: **Symptom $\to$ Evidence $\to$ Hypotheses $\to$ Investigation $\to$ Root Cause $\to$ Fix $\to$ Prevention**.
- Diagnose and remediate CPU saturation, memory thrashing, connection pool exhaustion, and lock queuing.
- Troubleshoot table and index bloat caused by long-running transactions and lagging autovacuum.
- Master **40 realistic production database incident scenarios** covering the full spectrum of database engineering failures.
- Execute hands-on troubleshooting labs reproducing connection exhaustion and transaction horizon freezing.

---

## Lessons in This Module

| File | Topic |
| :--- | :--- |
| [01-debugging-framework-and-runbooks.md](01-debugging-framework-and-runbooks.md) | The 7-step triage methodology, triage queries, and diagnostics |
| [02-forty-production-scenarios.md](02-forty-production-scenarios.md) | **40 Comprehensive Real-World Production Debugging Scenarios** |
| [labs/lab-01-long-transaction.md](labs/lab-01-long-transaction.md) | Lab: Investigating `idle in transaction` locking horizons & WAL bloat |
| [labs/lab-02-connection-exhaustion.md](labs/lab-02-connection-exhaustion.md) | Lab: Diagnosing max connections exhaustion & PgBouncer remediation |
