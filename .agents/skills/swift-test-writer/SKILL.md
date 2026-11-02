---
name: swift-test-writer
description: Write, change, or review a unit or integration XCTest in the PubNub Swift SDK. Holds the repository's test code rules. Not for contract tests.
---

# Swift test writer

Writes unit and integration tests for this repository. It assists the author; it does not replace review.

Scope: `Tests/PubNubUnitTests/` and `Tests/PubNubIntegrationTests/`. Never write or change `Tests/PubNubContractTests/` (CI-managed Cucumberish).

## Rules

Apply these rules to every test:

- Name each test `test_<Scenario>_<ExpectedOutcome>`.
- Structure each test as Arrange, Act, Assert, separated by blank lines.
- Do not use `sleep`, fixed delays, or wall-clock comparisons. Wait with `XCTestExpectation` and an explicit timeout.
- Do not depend on test execution order or on state shared between tests.
- Verify one behavior per test method.
- When testing public behavior, call the SDK API exactly as a consumer would. Do not wrap it in a test-only helper that reads like part of the API.
- When an asynchronous API completes with a `Result`, assert inside the real completion handler: switch over the result, call `XCTFail` on the unexpected case, and fulfill the expectation last.
- When failure is expected, assert the exact `PubNubError` reason (`error.pubNubError?.reason`), not only that the call failed.
- Write fixed expected values inline in the assertion. Do not derive expected values from a fixture or from the production result being asserted.
- Do not widen production access or add test-only behavior to production code solely to enable a test.
- Mark a test method `throws` when it can throw, and use `try` and `try XCTUnwrap()` instead of `if let` or `guard let`.
- Create mutable state and reference-type dependencies inside each test method. Do not hold them in class-level `var` properties or create them in `setUp()` / `tearDown()`. Class-level `let` constants for static test data (including structs and enums) are allowed.
- When Arrange setup is complex or repeated, extract it into a narrowly scoped factory or setup fixture that creates fresh state for each test. Keep scenario-specific inputs, the behavior under test, and expected values visible in the test method; never use fixtures to share mutable state.
- Use `unowned` in a test closure only when the captured object outlives the closure.

## Choose the workflow

- For a unit test or unit-test review, read [references/unit-tests.md](references/unit-tests.md).
- For an integration test or integration-test review, read [references/integration-tests.md](references/integration-tests.md).

## Finish

1. Run the smallest relevant validation described in `AGENTS.md`.
2. Re-read the test against the Rules section and the selected workflow reference, then fix every deviation.
3. Run `swiftlint --fix`, then `swiftlint --strict`.
