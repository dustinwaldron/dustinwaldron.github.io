---
title: "Design Patterns: Strategy Pattern - Replacing Conditionals with Interchangeable Behavior"
date: "2026-10-12T11:00:00-04:00"
description: "A practical Java-focused guide to the Strategy pattern, including runtime behavior selection, testability benefits, and common implementation pitfalls."
tags:
  - architecture
  - engineering
  - java
  - best practices
---

## The Strategy Pattern Solves a Behavior Variation Problem

Many systems start with one algorithm. Then product requirements split:

- pricing rules vary by customer tier
- retry policy varies by endpoint
- sorting logic varies by context
- shipping logic varies by region and SLA

The common anti-pattern is a growing `if/else` or `switch` chain embedded in one class.

That design works briefly, then becomes fragile. Every new variation requires editing existing logic, retesting broad paths, and managing side effects from unrelated branches.

The Strategy pattern solves this by encapsulating each algorithm in its own class behind a shared interface. The client chooses which strategy to use at runtime without changing the client’s core flow.

In Java systems, this is one of the most practical patterns for keeping behavior extensible and testable.

---

## The Gang of Four Intent

The Gang of Four defines Strategy as:

> Define a family of algorithms, encapsulate each one, and make them interchangeable. Strategy lets the algorithm vary independently from clients that use it.

Practically, this means:

- define a strategy interface
- implement concrete strategy classes
- inject or select strategy in context/client code
- avoid hardcoded conditional branching in the client

This makes behavior extension additive instead of invasive.

---

## Why Teams Use Strategy

Without Strategy, algorithm changes tend to create:

- branching-heavy service methods
- duplicated pre/post processing logic
- tight coupling between decision logic and execution logic
- difficult unit testing of individual behavior variants

With Strategy, each algorithm becomes a composable unit.

That improves:

- readability
- change isolation
- test focus
- long-term maintainability

---

## Java Example: Shipping Cost Calculation

### Strategy interface

```java
public interface ShippingStrategy {
    long calculateCents(Order order);
}
```

### Concrete strategies

```java
public class StandardShippingStrategy implements ShippingStrategy {
    @Override
    public long calculateCents(Order order) {
        return 799L;
    }
}
```

```java
public class ExpressShippingStrategy implements ShippingStrategy {
    @Override
    public long calculateCents(Order order) {
        return 1999L;
    }
}
```

```java
public class FreeShippingOverThresholdStrategy implements ShippingStrategy {
    private final long thresholdCents;

    public FreeShippingOverThresholdStrategy(long thresholdCents) {
        this.thresholdCents = thresholdCents;
    }

    @Override
    public long calculateCents(Order order) {
        return order.subtotalCents() >= thresholdCents ? 0L : 999L;
    }
}
```

### Context

```java
public class CheckoutService {
    private final ShippingStrategy shippingStrategy;

    public CheckoutService(ShippingStrategy shippingStrategy) {
        this.shippingStrategy = shippingStrategy;
    }

    public long totalCents(Order order) {
        return order.subtotalCents() + shippingStrategy.calculateCents(order);
    }
}
```

```java
public record Order(String id, long subtotalCents) {}
```

### Usage

```java
Order order = new Order("ord-123", 12_500L);
CheckoutService checkout = new CheckoutService(new FreeShippingOverThresholdStrategy(10_000L));
long total = checkout.totalCents(order);
System.out.println("Total cents: " + total);
```

No branching in `CheckoutService`, and new shipping behavior can be added without modifying that class.

---

## Another Java Example: Payment Retry Policy

Retry behavior often varies by integration reliability profile.

### Strategy

```java
public interface RetryStrategy {
    boolean shouldRetry(int attemptNumber, int statusCode);
}
```

### Concrete strategies

```java
public class AggressiveRetryStrategy implements RetryStrategy {
    @Override
    public boolean shouldRetry(int attemptNumber, int statusCode) {
        return attemptNumber < 5 && statusCode >= 500;
    }
}
```

```java
public class ConservativeRetryStrategy implements RetryStrategy {
    @Override
    public boolean shouldRetry(int attemptNumber, int statusCode) {
        return attemptNumber < 2 && statusCode == 503;
    }
}
```

### Context

```java
public class PaymentClient {
    private final RetryStrategy retryStrategy;

    public PaymentClient(RetryStrategy retryStrategy) {
        this.retryStrategy = retryStrategy;
    }

    public void charge(String customerId, long amountCents) {
        int attempt = 0;
        int statusCode;

        do {
            attempt++;
            statusCode = simulateRemoteCall(customerId, amountCents, attempt);
            if (statusCode == 200) {
                return;
            }
        } while (retryStrategy.shouldRetry(attempt, statusCode));

        throw new IllegalStateException("Charge failed with status " + statusCode);
    }

    private int simulateRemoteCall(String customerId, long amountCents, int attempt) {
        return attempt < 2 ? 503 : 200;
    }
}
```

The client workflow remains stable while retry policy changes independently.

---

## Strategy vs State

These patterns look similar structurally but differ in intent:

- **Strategy** selects among interchangeable algorithms.
- **State** changes behavior based on internal state transitions over time.

If behavior choice is configuration/policy-driven, Strategy is usually the fit.  
If behavior evolves because object state transitions, State is often more appropriate.

---

## Strategy vs Template Method

- **Strategy** uses composition and interchangeable objects.
- **Template Method** uses inheritance and fixed algorithm skeletons with overridable steps.

In Java enterprise systems, Strategy is often preferred when runtime flexibility and testability are priorities.

---

## SOLID Alignment

Strategy is a direct expression of SOLID principles:

### Open/Closed Principle
New behaviors are added via new strategy classes, not by editing existing context logic.

### Single Responsibility Principle
Each strategy class owns one algorithmic concern.

### Dependency Inversion Principle
Context classes depend on abstractions (`ShippingStrategy`, `RetryStrategy`), not concrete algorithms.

This is why Strategy scales well as product logic evolves.

---

## Common Mistakes

### 1. Too many trivial strategies
Do not create class-per-line abstractions for minor differences that do not justify indirection.

### 2. Leaking context internals into strategies
Keep strategy inputs focused and stable. Passing entire service internals increases coupling.

### 3. Strategy selection logic spread across the system
Centralize selection at composition boundaries (configuration, factory, DI container) where possible.

### 4. Ignoring defaults
Define safe default behavior. Missing strategy configuration should fail clearly or use an intentional baseline.

---

## Practical Guidance for Java Teams

Use Strategy when:

- algorithm variants are real and expected to grow
- you need runtime behavior selection
- testability of each algorithm matters
- branch-heavy logic is growing in a core service

Avoid Strategy when:

- there is one stable algorithm with low change likelihood
- indirection adds more complexity than it removes
- a straightforward method parameter or comparator is enough

Use the pattern to reduce complexity, not to decorate simple code.

---

## Final Thoughts

The Strategy pattern remains one of the most useful behavioral patterns because it turns algorithm variation from a maintenance risk into a composable design choice.

In Java, it helps teams replace brittle conditional logic with explicit, testable, and swappable behavior modules.

Used well, Strategy makes services easier to evolve and reason about. Used carelessly, it can create unnecessary class sprawl.

The practical standard is clear:

- extract meaningful algorithm families
- keep strategy contracts narrow
- centralize strategy selection
- test each strategy as production-critical logic

That is how you keep behavior flexible without letting complexity spread through core workflows.
