# 02. Testing Constraints, Race Conditions & Concurrency

## 1. Concurrency Testing Pattern: `CountDownLatch`

To verify that optimistic locking or row locks prevent lost updates in automated test suites:

```java
@Test
void shouldPreventLostUpdatesUnderConcurrentTransfers() throws InterruptedException {
    int numThreads = 10;
    ExecutorService executor = Executors.newFixedThreadPool(numThreads);
    CountDownLatch startLatch = new CountDownLatch(1);
    CountDownLatch doneLatch = new CountDownLatch(numThreads);

    // Initial balance: 1000.00
    accountRepository.save(new Account(1L, new BigDecimal("1000.00")));

    for (int i = 0; i < numThreads; i++) {
        executor.submit(() -> {
            try {
                startLatch.await(); // All threads wait here until unleashed simultaneously!
                accountService.depositAtomic(1L, new BigDecimal("10.00"));
            } catch (Exception ignored) {
            } finally {
                doneLatch.countDown();
            }
        });
    }

    startLatch.countDown(); // Unleash all 10 threads concurrently!
    doneLatch.await(5, TimeUnit.SECONDS);

    // Final balance MUST be exactly 1000 + (10 * 10) = 1100.00
    Account account = accountRepository.findById(1L).orElseThrow();
    assertEquals(new BigDecimal("1100.00"), account.getBalance());
}
```
