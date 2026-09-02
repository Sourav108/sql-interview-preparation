# Module 28: Database System Design Interviews

A master collection of 5 end-to-end database system design interview cases for Senior & Staff backend engineering interviews.

---

## 🏛️ System Design Cases

| Case File | Domain | Key Architecture & Concurrency Challenges |
| :--- | :--- | :--- |
| [01-ecommerce-platform-design.md](01-ecommerce-platform-design.md) | E-Commerce Platform | Inventory overselling prevention, order lifecycle, financial audit trail |
| [02-banking-ledger-design.md](02-banking-ledger-design.md) | Double-Entry Core Banking | Invariant $\sum \text{Debit} = \sum \text{Credit}$, atomic transfers, balance snapshots |
| [03-social-network-feed-design.md](03-social-network-feed-design.md) | Social Activity Feed | Fanout-on-write vs fanout-on-read, follower graphs, Keyset pagination |
| [04-saas-subscription-billing-design.md](04-saas-subscription-billing-design.md) | Multi-Tenant SaaS Billing | Prorated billing, plan upgrades, automated invoice generation |
| [05-hotel-resource-booking-design.md](05-hotel-resource-booking-design.md) | Resource & Hotel Booking | Temporal non-overlapping range exclusion constraints (`GiST`), room locks |

---

## Standard System Design Architecture Template
Every case covers:
1. **Business & Technical Requirements (SLAs, QPS, Latency)**
2. **Entity-Relationship Modeling & Normalization**
3. **Complete DDL Schema (Types, Keys, Constraints)**
4. **Targeted Performance Indexing Strategy**
5. **ACID Transaction Boundaries & Concurrency Control**
6. **Core Access Patterns & Production Queries**
7. **Scale Considerations (Sharding, Partitioning, Caching, Archival)**
8. **Trade-offs & Senior Architectural Defense**
