# REVIEW.md

Review instructions for the PubNub Swift SDK. The review action provides the general procedure, the severity definitions, the finding format with examples 
and the handling of earlier findings; this file only holds what is specific to this repository.

## Scope

- Apply `AGENTS.md`. Read `CODING_STANDARDS.md` and apply it to changed production code, naming the rule in each finding..
- Paths in these instructions are relative to the repository root, which is your working directory.
- Trace production changes from the public entry point through request construction, decoding and tests.
- Search for related declarations, overloads, fixtures, snippets and distribution metadata outside the diff.

## Writing findings

Write the way a helpful teammate would in a code review: plain words, say what you noticed and why it matters, then suggest a fix. Explain, don't just assert.

## Review checklist

### Public API

Applies to the `PubNub` facade (`Sources/PubNub/PubNub.swift`, `Sources/PubNub/APIs/**`), `PubNubConfiguration`, and any other public declaration.

- Trace every parameter of a new or changed method to the correct request field; none may be dropped or swapped.
- A method taking `custom requestConfig` passes it to `route(custom:)` and its `customConfiguration` to the router.
- Keep the facade thin. Validation, request building and decoding belong in the Router or ResponseDecoder, not an `APIs/` method.
- The completion is called exactly once on every path. Errors preserve their documented reason and useful context; report translations that lose actionable information.
- Keep declarations non-public unless consumers call or implement them. Widening access requires a concrete use case in the PR description and matching tests.
- Consumer-visible behavior changes update affected DocC, snippets and tests. Require snippets only where a consumer-facing snippet surface exists.

### Breaking changes

Breaking changes may be intentional, but must be declared. Check removed and changed public declarations, including members of `public extension`s without an explicit `public` keyword.

- API break: removal, renaming or retyping of a public symbol; changes to optionality, availability, generic constraints, inheritance, `throws`, `mutating`, `static`, `final`, `open` or a parameter label; or a parameter added without a default.
- Protocol break: a new requirement without a default, changed inheritance or associated-type constraints, or removal of a default implementation used by existing conformers.
- Enum break: adding or removing a public case breaks consumers' exhaustive `switch`.
- Objective-C break: changing an exposed class, selector, label, nullability annotation or inherited protocol.
- Behavior break: changing a default, limit, ordering guarantee, error reason, callback frequency or callback queue.
- A `BREAKING CHANGES:` footer records intent; it does not suppress review. Require migration guidance, deprecation when feasible, and explicit maintainer approval or release metadata proving intent.
- Report one `high` finding for all undeclared or unsupported source breaks. Anchor it to the most significant, name the others, and prefer a compatibility-preserving deprecated forwarder.

### Concurrency

- Shared state needs synchronization or confinement that protects the complete invariant. `Atomic<T>`, a serial queue or another correct primitive is acceptable.
- Report a compound operation split across lock calls, and user closures called under a lock.
- Report concrete cycles where an object retains a closure that captures it without `[weak self]`, `WeakBox` or explicit cleanup.
- Report concrete data races and false `Sendable` or `@unchecked Sendable` claims, not concurrency migrations.

### Security

- Redact logged keys, tokens, cipher keys, authorization headers, signed URLs and sensitive request/response bodies with `redacted()` or `fullyRedacted`, as `PubNub.swift` does.
- No real keys or tokens in the diff, including test plists, snippets and examples.
- No new production dependencies or executable build hooks. Check Swift package dependencies, binary targets, plugins and macros; podspec dependencies and scripts; linked or vendored frameworks; and Carthage metadata.
- Crypto changes preserve nonce/IV uniqueness, authentication checks and failure handling. Do not recommend replacing compatibility-only legacy cryptors unless changed code makes them less safe.

### Build and release integrity

CI does not catch these.

- Every added, renamed or deleted `.swift` file under `Sources/`, `Tests/PubNubUnitTests/` or `Tests/PubNubIntegrationTests/` needs a matching `project.pbxproj` change. A miss is `major`.
- The release bot owns versions and the changelog. A hand edit is `minor`: `version:` or `changelog:` in `.pubnub.yml`, `s.version` in the podspec, `MARKETING_VERSION` in `project.pbxproj`, `pubnubSwiftSDKVersion` in `Constants.swift`.
- The platform floors are iOS 13, macOS 10.15, tvOS 13, watchOS 6, visionOS 1 and Swift 5.9 (Swift 5 language mode). Report: 
  - disagreement among `Package.swift`, the podspec and Xcode deployment targets;
  - APIs newer than the floors without `#available`, or syntax requiring a newer toolchain.
- Keep SPM, CocoaPods, Carthage, the shared Xcode scheme, resources, privacy manifests and module/product names consistent. Inspect Carthage, watchOS and visionOS, which CI does not validate.
- `Sources/PubNub/KMP/` is consumed through the generated Objective-C header. Report renamed or removed `@objc` classes, selectors or labels, and header-breaking names such as `id` before another parameter.

### Networking

- Changed Routers preserve endpoint HTTP methods, paths, percent encoding, query names and omission rules, headers, body encoding, timeouts and signing inputs.
- Authentication and custom configuration reach every request branch, including compression, pagination and retry.
- Decoding handles documented success shapes and maps status codes, service errors and malformed responses without losing useful error information.
- Pass pagination cursors, limits and offsets in the correct direction. Preserve the public cancellation, retry and callback-queue contract.

### Tests

- A bug fix or behavior change comes with a test that would fail without it. A miss is `major`.
- New helpers that encode behavior need coverage; existing higher-level tests can provide it.
- A new Router or ResponseDecoder has a router test and an endpoint test with a fixture.
- Unit tests use `MockURLSession`, remain deterministic, cover new failure and boundary paths, assert exact error reasons, and keep mutable/reference state local rather than in `setUp()` or class-level `var` properties.
- Async tests assert inside the real completion, fail the unexpected `Result` case and fulfill expectations last.
- Integration tests cover only what the live service can prove and do not duplicate unit tests. They import `PubNubSDK`, not `@testable`.

### Snippets

`swift build` compiles `Snippets/`. Check that they teach correctly, not that they compile.

- Use only public `PubNubSDK` API in the recommended pattern; no `@testable import`, internal or `KMP` types.
- Preserve `// snippet.<id>` and `// snippet.end` markers and IDs. Use `// snippet.hide` and `// snippet.show` only around compilation scaffolding.
- Add a snippet for new public API to the matching `Snippets/{Area}/` file, modeled on the nearest snippet.

### Documentation comments

- Comment claims match the code: parameter names, defaults (check public initializers), callback queue, `nil` and empty-value behavior.
- Public DocC describes observable purpose, constraints, lifecycle and special values, not internal implementation. Put shared callback policy on the nearest common abstraction.
- Make the first sentence useful in Quick Help. Verify symbol links. Promise ordering, retries, persistence, thread safety or delivery only when source and tests establish them.
- User-facing comments, snippets and messages name no unreleased or internal feature, ticket ID or internal URL.
- Wording and punctuation problems in shipped docs are `nitpick`.

## Do not report

- Formatting covered by `.swiftlint.yml` and `.swift-format`, including line length, spacing and trailing commas.
- Taste and vague suggestions: naming preferences, `if let` shorthand, new protocols or abstractions, and performance concerns without a concrete hot path. Doc wording is exempt.
- Concurrency migrations to `async`/`await` or actors. Concrete bugs and false safety annotations are reviewable.
- Missing DocC on non-public symbols and on `Sources/PubNub/KMP/`.
- Build and test failures already reported by required CI. Do report platform/distribution failures and review-system gaps that required CI does not cover.
- Generated files and paths `.swiftlint.yml` excludes: `Pods/`, `.build/`, `Examples/`, `fastlane/`, lockfiles, `.DS_Store`, and `Tests/PubNubContractTests/` (CI-managed).
