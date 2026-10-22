---
title: "Design Patterns: Chain of Responsibility Pattern - Routing Requests Through Composable Handlers"
date: "2026-10-17T11:00:00-04:00"
description: "A practical Java-focused guide to the Chain of Responsibility pattern, including request pipelines, short-circuit handling, and production trade-offs."
tags:
  - architecture
  - engineering
  - java
  - best practices
---

## The Chain of Responsibility Pattern Solves a Routing and Decision Flow Problem

Many systems process requests through a sequence of checks and transformations:

- authentication
- authorization
- validation
- enrichment
- execution

The anti-pattern is one large method that does all of this with nested branching. It becomes fragile, hard to test, and difficult to evolve when steps change.

The Chain of Responsibility pattern solves this by passing a request through a chain of handlers. Each handler can process the request, pass it onward, or stop the chain.

In Java systems, this is a practical pattern for request pipelines, middleware-style processing, and policy enforcement flows.

---

## The Gang of Four Intent

The Gang of Four defines Chain of Responsibility as:

> Avoid coupling the sender of a request to its receiver by giving more than one object a chance to handle the request.

Practically, this means:

- define a common handler contract
- link handlers in sequence
- let each handler decide whether and how to continue

This keeps request senders decoupled from concrete handling logic and order details.

---

## Why Teams Use Chain of Responsibility

Without this pattern, teams usually get:

- giant conditional dispatch blocks
- duplicate pre-check logic in multiple services
- difficult-to-reuse validation/enforcement steps
- brittle control flow when adding/removing stages

With a chain:

- each concern becomes a focused handler
- ordering is explicit and configurable
- tests can target each stage independently
- cross-cutting pipeline behavior becomes composable

---

## Java Example: API Request Processing Pipeline

### Request and response

```java
public record ApiRequest(String userId, String token, String payload) {}
public record ApiResponse(int statusCode, String body) {}
```

### Handler contract

```java
public interface RequestHandler {
    ApiResponse handle(ApiRequest request);
}
```

### Base chain helper

```java
public abstract class AbstractHandler implements RequestHandler {
    private RequestHandler next;

    public AbstractHandler setNext(RequestHandler next) {
        this.next = next;
        return this;
    }

    protected ApiResponse next(ApiRequest request) {
        if (next == null) {
            return new ApiResponse(200, "OK");
        }
        return next.handle(request);
    }
}
```

### Concrete handlers

```java
public class AuthenticationHandler extends AbstractHandler {
    @Override
    public ApiResponse handle(ApiRequest request) {
        if (request.token() == null || request.token().isBlank()) {
            return new ApiResponse(401, "Missing auth token");
        }
        return next(request);
    }
}
```

```java
public class AuthorizationHandler extends AbstractHandler {
    @Override
    public ApiResponse handle(ApiRequest request) {
        if (!request.userId().startsWith("user-")) {
            return new ApiResponse(403, "User is not authorized");
        }
        return next(request);
    }
}
```

```java
public class ValidationHandler extends AbstractHandler {
    @Override
    public ApiResponse handle(ApiRequest request) {
        if (request.payload() == null || request.payload().isBlank()) {
            return new ApiResponse(400, "Payload cannot be empty");
        }
        return next(request);
    }
}
```

```java
public class BusinessHandler extends AbstractHandler {
    @Override
    public ApiResponse handle(ApiRequest request) {
        return new ApiResponse(200, "Processed request for " + request.userId());
    }
}
```

### Chain composition

```java
AuthenticationHandler authn = new AuthenticationHandler();
AuthorizationHandler authz = new AuthorizationHandler();
ValidationHandler validation = new ValidationHandler();
BusinessHandler business = new BusinessHandler();

authn.setNext(authz).setNext(validation).setNext(business);

ApiResponse response = authn.handle(new ApiRequest("user-123", "token-abc", "hello"));
System.out.println(response.statusCode() + " - " + response.body());
```

This gives clear, composable request handling with short-circuit behavior.

---

## Another Java Example: Expense Approval Chain

This pattern is common in approval workflows.

### Request

```java
public record ExpenseRequest(String requesterId, long amountCents) {}
```

### Handler

```java
public interface ExpenseApprover {
    boolean approve(ExpenseRequest request);
}
```

### Approvers

```java
public class TeamLeadApprover implements ExpenseApprover {
    private ExpenseApprover next;

    public TeamLeadApprover setNext(ExpenseApprover next) {
        this.next = next;
        return this;
    }

    @Override
    public boolean approve(ExpenseRequest request) {
        if (request.amountCents() <= 50_000) {
            return true;
        }
        return next != null && next.approve(request);
    }
}
```

```java
public class DirectorApprover implements ExpenseApprover {
    private ExpenseApprover next;

    public DirectorApprover setNext(ExpenseApprover next) {
        this.next = next;
        return this;
    }

    @Override
    public boolean approve(ExpenseRequest request) {
        if (request.amountCents() <= 500_000) {
            return true;
        }
        return next != null && next.approve(request);
    }
}
```

```java
public class CfoApprover implements ExpenseApprover {
    @Override
    public boolean approve(ExpenseRequest request) {
        return request.amountCents() <= 5_000_000;
    }
}
```

This keeps escalation logic clean and extensible.

---

## Chain of Responsibility vs Command

- **Chain of Responsibility** routes a request through multiple potential handlers.
- **Command** encapsulates a request as an object for execution, queueing, or undo.

They can be combined (commands flowing through a chain), but they solve different problems.

---

## Chain of Responsibility vs Decorator

- **Chain of Responsibility**: each handler may stop or continue request flow.
- **Decorator**: always wraps/delegates while adding behavior around the same operation.

If early termination and conditional handling are core requirements, Chain is usually the better fit.

---

## SOLID Alignment

This pattern aligns strongly with SOLID:

### Single Responsibility Principle
Each handler owns one concern.

### Open/Closed Principle
Add or reorder handlers without modifying existing handler internals.

### Dependency Inversion Principle
Pipeline assembly depends on handler abstractions, not concrete end-to-end logic blocks.

This makes request-processing architectures easier to evolve safely.

---

## Common Mistakes

### 1. Hidden chain ordering
Order changes behavior. Chain composition should be explicit and test-covered.

### 2. Handlers doing too much
Overgrown handlers become mini-monoliths. Keep stages narrow and focused.

### 3. Unclear stop/continue semantics
Document and enforce whether handlers should short-circuit on failure or always continue.

### 4. Missing observability
Without logging/metrics per stage, production debugging is painful.

---

## Practical Guidance for Java Teams

Use Chain of Responsibility when:

- request handling is multi-stage and likely to evolve
- each stage has distinct concerns
- early exits and conditional routing are meaningful

Avoid it when:

- processing is simple and linear with little variation
- handler abstraction adds indirection without clear benefits
- a direct service flow is easier to understand and maintain

Pattern value comes from clear stage boundaries, not from introducing pipelines by default.

---

## Final Thoughts

The Chain of Responsibility pattern is a practical way to turn complex request processing into modular, composable stages.

In Java, it works especially well for middleware-like flows, policy pipelines, and approval chains where concerns need to remain isolated yet ordered.

Used well, it improves maintainability and extensibility. Used carelessly, it creates opaque request paths and debugging pain.

The practical standard is clear:

- keep handlers focused
- make ordering explicit
- define stop/continue rules clearly
- instrument each stage for visibility

That is how you build request pipelines that scale with system complexity instead of collapsing under it.
