# Integration tests

Use this reference for tests in `Tests/PubNubIntegrationTests/`. The shared rules in `SKILL.md` remain authoritative.

## Test through the public SDK

Integration tests make real PubNub network requests. Use `import PubNubSDK`, create a real `PubNub` client, and exercise the public API as a consumer would. Do not use `MockURLSession` or unit-test response fixtures.

Define the externally observable service behavior before writing the test. Keep setup operations, the behavior under test, and cleanup distinct. Assert every operation whose outcome the test depends on.

## Isolate remote state

- Generate unique channel, group, user, entity, and other resource identifiers for each test run.
- Do not rely on execution order or resources created by another test.
- Register cleanup in a `defer` and remove every resource the test creates.
- Use `waitForCompletion` only for cleanup operations.

```swift
func test_CreateChannel_WithValidPayload_ReturnsCreatedChannel() throws {
  let createChannelExpect = XCTestExpectation(description: "Channel created")
  let bundle = Bundle(for: DataSyncChannelEndpointIntegrationTests.self)
  let client = PubNub(configuration: try dataSyncConfiguration(from: bundle))
  let channelId = randomString()

  defer {
    waitForCompletion {
      client.dataSync.removeChannel(id: channelId, completion: $0)
    }
  }

  client.dataSync.createChannel(
    classVersion: 1,
    id: channelId,
    status: "active",
    payload: TestChannelPayload(name: "Swift integration test")
  ) { result in
    switch result {
    case let .success(channel):
      XCTAssertEqual(channel.id, channelId)
      XCTAssertEqual(channel.status, "active")
    case let .failure(error):
      XCTFail("Unexpected error: \(error)")
    }
    createChannelExpect.fulfill()
  }

  wait(for: [createChannelExpect], timeout: 10.0)
}
```

When a test chains setup and verification requests, handle failure at every stage and fulfill the expectation on every terminal path. Do not let a failed setup request turn into a timeout.

## Events and subscriptions

Establish the subscription and observe its connected state before performing the action expected to emit an event. Use separate expectations for connection, the service operation, and the event when the test verifies each one. Use ordered waiting only when order is part of the behavior.

Do not use fixed delays to wait for propagation. Prefer an observable service response, connection state, or event that establishes readiness.

## Credentials and shared fixtures

- Standard integration keys come from `PubNubTests_Info.plist`.
- DataSync suites read `PubNubDataSyncTests_Info.plist` through `DataSyncTestCredentials`.
- Never commit real keys or tokens.
- DataSync healthcare classes must exist on the keyset. If they are missing, create them with `Scripts/DataSync/`.
- Keep `Scripts/DataSync/` in step with `Support/DataSyncHealthcareFixtures.swift`.

## Repository integration

- Reuse helpers in `Tests/PubNubIntegrationTests/Support/`.
- Integration tests run through Xcode or Fastlane, not `swift test`.
- Run integration tests only when valid credentials and the required remote configuration are available, following `AGENTS.md`.
