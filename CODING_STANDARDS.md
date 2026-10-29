# Coding Standards

This document is the source of truth for code quality and style in this repository. Repository layout, workflow, and validation commands live in `AGENTS.md`.

## Production Swift Library Code

Apply these rules to production Swift library code:

- Use `struct` or `enum` unless the type needs identity, inheritance, or Objective-C interoperability. State the reason in a comment on any new `class`.
- Use `let` unless the value is mutated after initialization.
- Default to `internal`. Use `private` for helpers used by a single type or file. Use `public` only for API that SDK consumers call or implement. Do not widen the access level of an existing declaration without noting it in the PR description.
- Do not use force unwraps (`!`), `try!`, `as!`, implicitly unwrapped optionals, `fatalError`, or `preconditionFailure`.
- Do not introduce a new protocol or generic parameter unless at least two production types conform to it or use it, or a test double requires it.
- Name types, functions, and properties so they read at the call site without a comment; follow the Swift API Design Guidelines.
- Do not discard errors with `try?` or an empty `catch`. When converting an error into another type, keep the original as the underlying or associated error.
- Split long or complex code to fit the limits in `.swiftlint.yml` instead of disabling a rule.

## Swift SDK Test Code

Apply these rules to Swift SDK test code:

- Name each test `test<Scenario>_<ExpectedOutcome>` or an equivalent form that states both the scenario and the expected outcome.
- Structure each test as Arrange, Act, Assert, separated by blank lines.
- Add at least one failure-path test for every new throwing or error-returning code path, and one test for each boundary value (empty, nil, minimum, maximum) the change handles.
- Do not use `sleep`, fixed delays, or wall-clock comparisons. Wait with `XCTestExpectation` and an explicit timeout.
- Do not depend on test execution order or on state shared between tests.
- Verify one behavior per test method.
- Mark a test method `throws` when it can throw, and use `try` and `try XCTUnwrap()` instead of `if let` or `guard let`.
- Create mutable state and reference-type dependencies inside each test method. Do not hold them in class-level `var` properties or create them in `setUp()` / `tearDown()`. Class-level `let` constants for static test data (including structs and enums) are allowed.
- Use `unowned` in a test closure only when the captured object outlives the closure.

### Test doubles

Name every test double with exactly one of these prefixes, chosen by what the double does:

- `Mock`: records calls and is asserted on by the test (verifies interactions). Example: `MockURLSession`.
- `Stub`: returns canned data and is never asserted on. Example: `StubDispatcher`.
- `NoOp`: does nothing and only satisfies a dependency. Example: `NoOpEffectHandler`.
- `Expector`: a spy that fulfills an `XCTestExpectation` when observed events occur. Example: `SessionExpector`.

A double that both returns canned data and records calls is a `Mock`. Do not add other prefixes (`Fake`, `Spy`, `Dummy`).
