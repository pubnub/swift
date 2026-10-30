# Coding Standards

This document is the source of truth for production Swift library code quality and style in this repository. Rules for test code live in the `swift-test-writer` skill (`.agents/skills/swift-test-writer/SKILL.md`). Repository layout, workflow, and validation commands live in `AGENTS.md`.

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
