# 01. Database Integration Testing with Testcontainers

## 1. The H2 In-Memory Database Trap

For years, developers ran unit tests against H2 in-memory databases while deploying against PostgreSQL in production.

### Why Testing Against H2 Is an Anti-Pattern:
1. **Dialect Mismatches**: H2 does not support `JSONB` GIN indexing, `EXCLUDE USING gist`, `DISTINCT ON`, or `FILTER (WHERE ...)`.
2. **Locking & MVCC Differences**: H2's lock manager does not replicate PostgreSQL's `xmin`/`xmax` MVCC, serialization failure codes (`40001`), or `FOR UPDATE SKIP LOCKED`.
3. **False Sense of Security**: Migrations and queries that pass in H2 fail catastrophically upon production PostgreSQL deployment.

---

## 2. Production Testing Standard: Real PostgreSQL via Testcontainers

```java
@Testcontainers
@SpringBootTest
public class OrderRepositoryIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:18.6-alpine")
            .withDatabaseName("test_db")
            .withUsername("test_user")
            .withPassword("test_pwd");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Test
    void shouldEnforcePositiveOrderTotalConstraint() {
        assertThrows(DataIntegrityViolationException.class, () -> {
            orderRepository.save(new Order(1L, new BigDecimal("-50.00")));
        });
    }
}
```
