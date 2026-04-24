# CODING_STANDARDS.md

This document contains shared Swift standards for this repository.

## Production Swift Library Code

Apply these standards to production Swift library code:

- Prefer value semantics and immutability where practical; use `let` instead of `var` unless mutation is required.
- Avoid force unwraps and other crash-prone patterns unless they are provably safe and justified.
- Flag redundant optional rebinding of the form `if let x = x` or `guard let x = x` when Swift shorthand binding (`if let x` / `guard let x`) would express the same logic just as clearly.
- Preserve clear ownership and lifecycle behavior; flag likely retain cycles, leaked observers, and long-lived captured references.
- Watch for race conditions and shared mutable state, especially around callbacks, queues, async work, and listener management.
- Prefer clear, idiomatic Swift naming and small focused types/functions over overly clever abstractions.
- Flag duplicated logic, dead code, and abstractions that add complexity without a real boundary or testability benefit.
- Preserve useful error information; do not ignore failures or replace specific errors with vague ones.
- Watch for hot-path inefficiencies such as repeated allocations, avoidable copying, and unnecessary collection transformations.

## Swift SDK Test Code

Apply these standards to Swift SDK test code:

- Test names should clearly describe the scenario and expected outcome.
- Prefer a clear Arrange-Act-Assert structure when practical.
- Cover edge cases and failure paths introduced by the change.
- Keep tests deterministic and isolated; avoid hidden shared state, order dependence, and timing-sensitive assertions.
- Prefer focused tests over broad tests that verify many behaviors at once.
