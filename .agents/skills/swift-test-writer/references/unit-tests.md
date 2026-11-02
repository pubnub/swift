# Unit tests

Use this reference for tests in `Tests/PubNubUnitTests/`. The shared rules in `SKILL.md` remain authoritative.

## Start from observable behavior

Identify what the subject exposes:

- A returned value or thrown error.
- Validation of input.
- A state transition and emitted effects.
- An interaction with a collaborator.
- An asynchronous callback, listener event, or stream value.
- A constructed HTTP request.
- A decoded HTTP response or mapped error.

Test the observable result, not private implementation steps. One behavior may require several assertions: for example, a state transition's resulting state and emitted effects together form one outcome.

List the cases before writing code: the success path, every new failure path, and each relevant boundary value the change handles, such as empty, nil, minimum, or maximum. Write one test per case.

## Choose the test shape

| Subject | Exercise | Assert |
| --- | --- | --- |
| Value or transformation | Call the function | Exact returned value |
| Validation | Supply valid or invalid input | Exact validation result or error |
| State transition | Apply one event to one state | Resulting state and emitted effects |
| Collaborator interaction | Invoke the subject with a test double | Contractual calls and arguments |
| Callback, listener, or stream | Trigger one event | Exact delivered value |
| Router | Construct the router | Request and validation |
| Endpoint | Supply a mocked response | Decoded value or mapped error |

### Values, transformations, and validation

Keep the Arrange, Act, and Assert phases distinct even when the subject is small. Assert the complete value instead of reconstructing the production algorithm in the test. For throwing behavior, assert the specific error rather than only using `XCTAssertThrowsError`.

```swift
func test_CryptoError_WithUnknownRawValue_ReturnsUnknown() {
  let result = CryptoError(rawValue: CCCryptorStatus(1_240_124))

  XCTAssertEqual(result, .unknown)
}
```

### State transitions and effects

Apply one event to one starting state. Assert both the resulting state and the ordered effects when both are part of the transition contract. Do not test a chain of unrelated transitions in one method.

```swift
func test_Reconnect_FromHandshakeStoppedState_TransitionsToHandshakingAndRequestsHandshake() {
  let input = SubscribeInput(channels: ["channel"])
  let cursor = SubscribeCursor(timetoken: 0, region: 0)
  let transition = SubscribeTransition()

  let result = transition.transition(
    from: Subscribe.HandshakeStoppedState(input: input, cursor: cursor),
    event: .reconnect(cursor: nil)
  )

  XCTAssertEqual(
    result.state,
    Subscribe.HandshakingState(input: input, cursor: cursor)
  )
  XCTAssertEqual(
    result.invocations,
    [.managed(.handshakeRequest(channels: ["channel"], groups: []))]
  )
}
```

Use an existing equality helper from `Support/` or the surrounding suite when the state or effect type is not `Equatable`. Do not add production conformance solely for assertions.

### Collaborator interactions

Use a test double only when the collaborator crosses the unit boundary or its interaction is part of the subject's contract. Prefer testing returned state or values over incidental calls.

Name every test double with exactly one of these prefixes:

- `Mock`: records calls and is asserted on. A double that also returns canned data is still a `Mock`.
- `Stub`: returns canned data and is never asserted on.
- `NoOp`: does nothing and only satisfies a dependency.
- `Expector`: fulfills an `XCTestExpectation` when an observed event occurs.

Do not add other prefixes such as `Fake`, `Spy`, or `Dummy`.

### Callbacks, listeners, and streams

Trigger the event through the subject's real interface. Assert the delivered value inside the callback and fulfill the expectation last. Set `assertForOverFulfill` when receiving the event more than once would be a defect.

```swift
func test_MessagePayload_WhenReceived_NotifiesListenerOnce() {
  let messageExpect = XCTestExpectation(description: "Message received")
  messageExpect.assertForOverFulfill = true

  let client = TestPubNubFactory.make()
  let subscription = client.channel("test-channel").subscription()

  subscription.onMessage = { message in
    XCTAssertEqual(message.channel, "test-channel")
    XCTAssertEqual(message.payload.stringOptional, "expected-message")
    messageExpect.fulfill()
  }

  subscription.onPayloadsReceived(payloads: [
    mockMessagePayload(channel: "test-channel", message: "expected-message")
  ])

  wait(for: [messageExpect], timeout: 1.0)
}
```

Do not fulfill an expectation without first asserting the value or interaction that the test names.

## Networking unit tests

Unit tests never make real network calls. Test request construction separately from response handling.

### Router tests

Place router tests in `Tests/PubNubUnitTests/Networking/Routers/`. Build the router with `TestPubNubFactory.makeConfig()` and assert only its request contract: path, query items, headers, body, and validation. Do not create a session.

```swift
func test_TimeRouter_WithValidConfiguration_BuildsExpectedRequest() throws {
  let router = TimeRouter(.time, configuration: TestPubNubFactory.makeConfig())

  XCTAssertEqual(try router.path.get(), "/time/0")
  XCTAssertEqual(try router.queryItems.get(), router.defaultQueryItems)
  XCTAssertNil(router.validationError)
}
```

### Endpoint tests

Create the client with `TestPubNubFactory.make(session:)`, using a session from `MockURLSession.mockSession(for:)`. Call the public API and assert only response decoding or error mapping.

```swift
func test_Time_WithSuccessfulResponse_ReturnsTimetoken() throws {
  let timeExpect = XCTestExpectation(description: "Time response")
  let sessions = try MockURLSession.mockSession(for: ["time_success"])
  let client = TestPubNubFactory.make(session: sessions.session)

  client.time { result in
    switch result {
    case let .success(timetoken):
      XCTAssertEqual(timetoken, 15_643_405_135_132_358)
    case let .failure(error):
      XCTFail("Unexpected error: \(error)")
    }
    timeExpect.fulfill()
  }

  wait(for: [timeExpect], timeout: 1.0)
}
```

Keep JSON response fixtures in `Tests/PubNubUnitTests/Support/Responses/{Feature}/`, one fixture per scenario. Refer to each fixture by name. Expected values in assertions must not be derived from the fixture.

## Repository integration

- Use `@testable import PubNubSDK` only when the test needs internal access.
- Reuse `Support/Factories/`, `Support/Helpers/`, and `Support/Mocks/` before adding helpers.
- Keep unit tests and fixtures working under both SwiftPM and Xcode.
- When adding or moving a file, ensure it belongs to the SwiftPM `PubNubTests` target and the `PubNubTests` Xcode target.
- Validate first with `swift test --filter <TestClassName>`. Use the Xcode validation from `AGENTS.md` when its conditions apply.
