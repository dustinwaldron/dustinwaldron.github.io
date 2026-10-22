---
title: "Design Patterns: Command Pattern - Turning Requests into First-Class Objects"
date: "2026-10-16T11:00:00-04:00"
description: "A practical Java-focused guide to the Command pattern, including request encapsulation, undo support, queues, and production-oriented trade-offs."
tags:
  - architecture
  - engineering
  - java
  - best practices
---

## The Command Pattern Solves a Request Management Problem

In many systems, actions are not just method calls. They are business requests with lifecycle needs:

- execute now or later
- queue and retry
- audit who requested what
- support undo/redo
- replay during recovery

When request logic is embedded directly in UI handlers, controllers, or services, these capabilities become difficult to add consistently.

The Command pattern solves this by encapsulating a request as an object. The request object carries execution behavior (and optionally undo behavior), allowing requests to be queued, logged, composed, retried, and replayed in a structured way.

In Java systems, this is one of the most practical behavioral patterns for workflow orchestration and operational control.

---

## The Gang of Four Intent

The Gang of Four defines Command as:

> Encapsulate a request as an object, thereby letting you parameterize clients with queues, requests, and operations.

In practical terms:

- define a command interface
- represent each action as a concrete command class
- invokers trigger command execution
- receivers hold business behavior implementation

This separates “what to do” from “when/how it is invoked.”

---

## Why Teams Use Command

Without Command, systems often accumulate:

- controller methods packed with business action details
- duplicated retry/audit logic around each endpoint
- brittle switch-based dispatchers
- poor traceability for operational actions

With Command:

- actions become explicit units
- dispatch and execution can evolve independently
- command metadata can be logged uniformly
- queues/schedulers can process commands consistently

This is especially valuable in admin tooling, workflow engines, and task execution systems.

---

## Java Example: Basic Command Structure

### Command contract

```java
public interface Command {
    void execute();
}
```

### Receiver

```java
public class AccountService {
    public void freeze(String accountId) {
        System.out.println("Freezing account " + accountId);
    }

    public void unfreeze(String accountId) {
        System.out.println("Unfreezing account " + accountId);
    }
}
```

### Concrete command

```java
public class FreezeAccountCommand implements Command {
    private final AccountService accountService;
    private final String accountId;

    public FreezeAccountCommand(AccountService accountService, String accountId) {
        this.accountService = accountService;
        this.accountId = accountId;
    }

    @Override
    public void execute() {
        accountService.freeze(accountId);
    }
}
```

### Invoker

```java
public class CommandBus {
    public void dispatch(Command command) {
        command.execute();
    }
}
```

### Usage

```java
AccountService accountService = new AccountService();
Command command = new FreezeAccountCommand(accountService, "acct-123");
new CommandBus().dispatch(command);
```

This decouples request creation from execution orchestration.

---

## Java Example: Command with Undo

Undo support is one of the classic strengths of this pattern.

### Undoable command contract

```java
public interface UndoableCommand {
    void execute();
    void undo();
}
```

### Concrete command

```java
public class FreezeAccountUndoableCommand implements UndoableCommand {
    private final AccountService accountService;
    private final String accountId;
    private boolean executed;

    public FreezeAccountUndoableCommand(AccountService accountService, String accountId) {
        this.accountService = accountService;
        this.accountId = accountId;
    }

    @Override
    public void execute() {
        accountService.freeze(accountId);
        executed = true;
    }

    @Override
    public void undo() {
        if (!executed) {
            throw new IllegalStateException("Cannot undo before execution");
        }
        accountService.unfreeze(accountId);
    }
}
```

### Invoker with history

```java
import java.util.ArrayDeque;
import java.util.Deque;

public class UndoableCommandBus {
    private final Deque<UndoableCommand> history = new ArrayDeque<>();

    public void dispatch(UndoableCommand command) {
        command.execute();
        history.push(command);
    }

    public void undoLast() {
        UndoableCommand command = history.poll();
        if (command == null) {
            throw new IllegalStateException("No command to undo");
        }
        command.undo();
    }
}
```

This gives structured undo semantics without exposing receiver internals to callers.

---

## Java Example: Queued Command Processing

Command objects are natural queue payloads.

```java
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;

public class QueuedCommandProcessor {
    private final BlockingQueue<Command> queue = new LinkedBlockingQueue<>();

    public void submit(Command command) {
        queue.add(command);
    }

    public void processNext() throws InterruptedException {
        Command command = queue.take();
        command.execute();
    }
}
```

This separates producer timing from execution timing, which is often essential in operational systems.

---

## Command vs Strategy

These patterns are related but different:

- **Strategy** encapsulates interchangeable algorithms.
- **Command** encapsulates invocable requests/actions.

If your problem is “which algorithm should run,” think Strategy.  
If your problem is “how to represent, queue, execute, track, or undo an action,” think Command.

---

## Command vs Chain of Responsibility

- **Command** wraps one request as an object.
- **Chain of Responsibility** routes a request through multiple handlers until one handles it.

They can be combined, but they solve different concerns.

---

## SOLID Alignment

Command strongly supports SOLID principles:

### Single Responsibility Principle
Each command class owns one action.

### Open/Closed Principle
Add new actions by adding new command types, not by editing central dispatch conditionals.

### Dependency Inversion Principle
Invokers depend on command interfaces, not concrete business services.

This promotes modular action design and easier extension over time.

---

## Common Mistakes

### 1. Putting too much logic in invokers
Invokers should orchestrate execution, not absorb command business rules.

### 2. Weak command identity and metadata
In production systems, commands usually need IDs, timestamps, actor context, and correlation IDs for observability.

### 3. Non-idempotent retries without safeguards
Queued or retried commands must consider duplicate execution risks.

### 4. Overusing command classes for trivial one-off calls
If an action is simple and has no scheduling/audit/undo needs, a direct call may be cleaner.

---

## Practical Guidance for Java Teams

Use Command when:

- actions need to be queued, audited, retried, or undone
- request handling must be decoupled from request invocation
- action catalogs are growing and need structured dispatch

Avoid Command when:

- direct method calls are sufficient and stable
- introducing command classes adds ceremony without operational value
- there is no realistic need for deferred execution, history, or replay

Pattern discipline means matching abstraction to workflow and operational requirements.

---

## Final Thoughts

The Command pattern is valuable because modern systems often need to treat actions as durable, observable, and schedulable units, not just immediate method calls.

In Java, Command gives teams a clean way to model actions for queueing, undo, replay, and orchestration while keeping invokers decoupled from business receivers.

Used well, it improves extensibility and operational control. Used carelessly, it creates class sprawl without meaningful benefit.

The practical standard is clear:

- model meaningful actions as commands
- keep receiver logic cohesive
- keep invokers lean
- design for retries, idempotency, and observability where commands are durable

That is how you turn request handling into a maintainable system capability instead of scattered control flow.
