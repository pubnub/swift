---
name: swift-docc-author
description: Author or review contract-first DocC comments for consumer-facing public APIs in the PubNub Swift SDK. Use for inline API documentation and Quick Help improvements; do not use for general prose, release notes, or implementation comments.
---

# Swift DocC author

Write documentation that makes the SDK feel like a native Apple framework: concise, precise, and focused on what callers observe.

## Core principles

> Document the public contract from the SDK consumer's perspective. Describe purpose, observable behavior, consequences, constraints, and lifecycle. Exclude implementation details unless they create a user-visible guarantee.

> Put shared behavior at the nearest common abstraction. Document each callback only with the condition that triggers it and the value it delivers.

> Inspect how a symbol is initialized, consumed, and tested before documenting it. Do not infer its contract from its name, declaration, or apparent default value alone.

Conciseness must not remove conditions that change observable behavior.

## Workflow

1. Read the repository's `AGENTS.md` and `CODING_STANDARDS.md` before editing.
2. Confirm that the symbol is part of the intended consumer-facing API. The `public` access level alone is insufficient. Exclude `Sources/PubNub/KMP/` by default because it is interoperability infrastructure unless the user explicitly includes it.
3. Trace the symbol before writing:
   - Inspect every public initializer and default that can establish its value.
   - Find reads, writes, callers, conformances, and related state.
   - Inspect focused tests and snippets for observable behavior and edge cases.
   - Check availability, deprecation, threading, callback, persistence, cancellation, and lifecycle behavior where relevant.
4. Identify the nearest common abstraction for shared rules. Prefer documenting common callback delivery, replacement, queue, and lifecycle behavior once on a protocol or owning type.
5. Write only claims supported by code, tests, or established public documentation. If behavior remains ambiguous, preserve the existing accurate wording or report the uncertainty instead of inventing a guarantee.
6. Keep the first sentence independently useful in Xcode Quick Help. Add discussion only when it helps callers choose or correctly use the API.
7. Preserve copyright headers, snippet markers, availability attributes, and unrelated user changes. Do not expose unreleased or internal features.
8. Validate proportionally:
   - Re-read edited comments beside their declarations.
   - Confirm parameter labels and symbol links match the source.
   - Run the smallest relevant build or test from `AGENTS.md`.
   - Build documentation when the repository has a supported DocC validation command.

Before authoring or reviewing comments, read [the PubNub DocC style guide](references/style-guide.md).

## Boundaries

Do not:

- Restate a declaration without explaining its meaning or effect.
- Describe routers, adapters, containers, locks, serialization steps, algorithms, or control flow.
- Promise ordering, retention, retries, delivery, thread safety, or persistence unless verified.
- Copy the same callback policy onto every callback property.
- Treat a stored-property initializer as the effective public default without inspecting public initializers.
- Rewrite unrelated documentation merely to make wording uniform.

Implementation facts belong in DocC only when callers can observe or depend on their consequence. Describe the consequence, not the mechanism.
