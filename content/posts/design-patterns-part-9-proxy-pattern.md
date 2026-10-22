---
title: "Design Patterns: Proxy Pattern - Controlling Access Without Changing the Core"
date: "2026-10-10T11:00:00-04:00"
description: "A practical Java-focused guide to the Proxy pattern, including remote, virtual, and protection proxies with production-oriented examples and trade-offs."
tags:
  - architecture
  - engineering
  - java
  - best practices
---

## The Proxy Pattern Solves an Access and Control Problem

In real systems, not every object should be called directly.

Sometimes you need:

- authorization checks
- lazy loading for expensive resources
- remote invocation boundaries
- request throttling
- caching and fallback behavior

The core object should still do its job, but callers may need controlled access to it.  
That is where the Proxy pattern fits.

Proxy provides a substitute or placeholder for another object to control access to it. In Java systems, it is a practical way to insert operational policy around a component while keeping the component’s core logic unchanged.

---

## The Gang of Four Intent

The Gang of Four defines Proxy as:

> Provide a surrogate or placeholder for another object to control access to it.

In practical terms:

- the proxy implements the same interface as the real subject
- callers interact with the proxy as if it were the real object
- the proxy decides how and when to delegate

The pattern is most useful when control concerns are real and repeated.

---

## Why Teams Use Proxy in Production

Without a proxy, control logic often leaks into business code:

- auth checks repeated in multiple services
- ad hoc remote retry/circuit logic spread across clients
- lazy initialization logic duplicated per call site

A proxy centralizes those policies.

It lets you keep business interfaces stable while enforcing operational rules in one place.

---

## Java Example: Protection Proxy for Authorization

### Subject interface

```java
public interface DocumentService {
    String read(String documentId, UserContext userContext);
}
```

### Real subject

```java
public class RealDocumentService implements DocumentService {
    @Override
    public String read(String documentId, UserContext userContext) {
        return "Document content for " + documentId;
    }
}
```

### Proxy

```java
public class AuthorizationDocumentProxy implements DocumentService {
    private final DocumentService delegate;

    public AuthorizationDocumentProxy(DocumentService delegate) {
        this.delegate = delegate;
    }

    @Override
    public String read(String documentId, UserContext userContext) {
        if (!userContext.hasRole("DOCUMENT_READ")) {
            throw new SecurityException("User is not authorized to read documents");
        }
        return delegate.read(documentId, userContext);
    }
}
```

```java
public record UserContext(String userId, java.util.Set<String> roles) {
    public boolean hasRole(String role) {
        return roles.contains(role);
    }
}
```

This keeps authorization at the boundary and domain behavior in the real service.

---

## Java Example: Virtual Proxy for Lazy Loading

A virtual proxy is useful when object initialization is expensive.

### Subject interface

```java
public interface ReportRenderer {
    String render();
}
```

### Expensive real subject

```java
public class HeavyReportRenderer implements ReportRenderer {
    public HeavyReportRenderer() {
        // simulate expensive startup
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Initialization interrupted", e);
        }
    }

    @Override
    public String render() {
        return "Rendered high-fidelity report";
    }
}
```

### Lazy proxy

```java
public class LazyReportRendererProxy implements ReportRenderer {
    private volatile ReportRenderer delegate;

    @Override
    public String render() {
        if (delegate == null) {
            synchronized (this) {
                if (delegate == null) {
                    delegate = new HeavyReportRenderer();
                }
            }
        }
        return delegate.render();
    }
}
```

This defers expensive initialization until the first real call.

---

## Java Example: Remote Proxy Boundary

A remote proxy makes local code look like a local call while delegating over the network.

```java
public interface CustomerProfileClient {
    CustomerProfile getProfile(String customerId);
}
```

```java
public class HttpCustomerProfileClientProxy implements CustomerProfileClient {
    private final HttpGateway gateway;

    public HttpCustomerProfileClientProxy(HttpGateway gateway) {
        this.gateway = gateway;
    }

    @Override
    public CustomerProfile getProfile(String customerId) {
        String path = "/customers/" + customerId;
        String json = gateway.get(path);
        return CustomerProfile.fromJson(json);
    }
}
```

```java
public record CustomerProfile(String customerId, String email) {
    public static CustomerProfile fromJson(String json) {
        // simplified parsing for example purposes
        return new CustomerProfile("customer-123", "user@example.com");
    }
}
```

This isolates transport and serialization concerns from business services.

---

## Common Proxy Variants

In practice, you will see these proxy types frequently:

- **Protection proxy**: enforces authorization/policy
- **Virtual proxy**: lazy-loads expensive objects
- **Remote proxy**: represents remote services locally
- **Caching proxy**: caches results before delegating
- **Logging/monitoring proxy**: captures telemetry around calls

These are all the same structural idea: same interface, controlled delegation.

---

## Proxy vs Decorator vs Adapter

These patterns are similar structurally but different in intent:

- **Proxy** controls access to an object.
- **Decorator** adds behavior/responsibilities compositionally.
- **Adapter** translates incompatible interfaces.

If your concern is access control, lifecycle, remoting, or policy gates, Proxy is usually the right fit.

---

## SOLID Alignment

Proxy can reinforce SOLID principles when applied deliberately:

### Single Responsibility Principle
Control concerns (auth, caching, remoting) live in proxies; domain logic remains in real subjects.

### Open/Closed Principle
You can add new proxy behaviors without modifying existing subject implementations.

### Dependency Inversion Principle
Clients depend on stable interfaces, not concrete classes or transport details.

This is why Proxy scales well in layered Java architectures.

---

## Common Mistakes

### 1. Putting domain logic in the proxy
Proxy should govern access and delegation, not become the business service.

### 2. Hiding expensive side effects
If a proxy adds network calls or retries, document it. “Looks local” can mislead performance expectations.

### 3. Building deep proxy chains without observability
Multiple wrappers can obscure behavior. Use clear naming and telemetry.

### 4. Weak error semantics
Proxies should normalize errors thoughtfully, not swallow failure details that operators need.

---

## Practical Guidance for Java Teams

Use Proxy when:

- you need policy enforcement at call boundaries
- object creation should be deferred
- remote integration details should stay isolated
- cross-cutting control concerns need consistency

Avoid Proxy when:

- direct invocation is already simple and safe
- added indirection provides no operational value
- proxy layers make debugging harder than the control benefit they provide

Pattern discipline means using proxy for real control concerns, not cosmetic abstraction.

---

## Final Thoughts

The Proxy pattern is one of the most practical patterns in enterprise Java because it handles a common reality: access to behavior often needs governance.

Used well, Proxy keeps interfaces stable while enforcing authorization, lazy loading, remote boundaries, and operational policy in one place. Used poorly, it hides complexity and obscures performance characteristics.

The right approach is straightforward:

- keep proxy intent explicit
- keep subject interfaces clean
- separate control concerns from domain concerns
- test policy and delegation paths as production-critical behavior

That is how you add control without contaminating core business logic.
