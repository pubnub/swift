# Coding Standards

This document contains shared Swift standards for this repository.

## Production Swift Library Code

Apply these standards to production Swift library code:

- Prefer value semantics and immutability where practical; use `let` instead of `var` unless mutation is required.
- Minimize access levels: default to `private` or `internal`; only expose `public` what SDK consumers explicitly need. Do not widen access without justification.
- Avoid force unwraps and other crash-prone patterns.
- Prefer clear, idiomatic Swift naming and small focused types/functions over overly clever abstractions.
- Preserve useful error information; do not ignore failures or replace specific errors with vague ones.

## Swift SDK Test Code

Apply these standards to Swift SDK test code:

- Test names should clearly describe the scenario and expected outcome.
- Prefer a clear Arrange-Act-Assert structure when practical.
- Cover edge cases and failure paths introduced by the change.
- Keep tests deterministic and isolated; avoid hidden shared state, order dependence, and timing-sensitive assertions.
- Prefer focused tests over broad tests that verify many behaviors at once.
- Declare test methods as `throws` and use `try` / `try XCTUnwrap()` instead of `guard let ... else { return XCTFail(...) }`. Tests should be flat with no early-return guard boilerplate.
- Each test method should create its own mutable state and dependencies locally — do not share them via class-level var properties or setUp()/tearDown(). Class-level let constants for static test data are fine.
- Use clearly-typed test doubles with consistent prefixes: `Mock` (verifies interactions), `Stub` (returns canned data), `NoOp` (null object), `Expector` (spy with XCTestExpectation).
- `unowned` captures in test code are acceptable; they reduce unwrapping noise and surface lifecycle bugs immediately.
