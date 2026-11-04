# Changelog

All notable public changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [11.1.0] - 2026-10-29

> **Upgrade required:** This release raises the minimum supported versions of
> iOS, tvOS, and watchOS.

### Added

- Decrypt AES-GCM payloads with [`aesCbcCryptoModule(with:withRandomIV:)`](https://github.com/pubnub/swift/blob/b59243badb7d8dd60c1339ff8bbfe8d3abde10bd/Sources/PubNub/Helpers/Crypto/CryptoModule.swift#L585) and [`legacyCryptoModule(with:withRandomIV:)`](https://github.com/pubnub/swift/blob/b59243badb7d8dd60c1339ff8bbfe8d3abde10bd/Sources/PubNub/Helpers/Crypto/CryptoModule.swift#L604), improving compatibility with payloads produced by other PubNub SDKs without changing their encryption formats.

### Changed

- **Breaking:** Require iOS 13, tvOS 13, and watchOS 6 or later while retaining macOS 10.15 support. **Migration:** Raise the affected application deployment targets before upgrading.

### Fixed

- Prevent [`signal(channel:message:customMessageType:custom:completion:)`](https://github.com/pubnub/swift/blob/b59243badb7d8dd60c1339ff8bbfe8d3abde10bd/Sources/PubNub/APIs/Publish%2BPubNub.swift#L168-L174) payloads from being encrypted when published or decrypted when received, restoring interoperability with other PubNub SDKs.
- Read and write cryptor-header metadata of 255 bytes or more, including metadata ending exactly at the end of a stream.
- Decrypt empty data and files without rejecting the plaintext as malformed.
- Include default and secondary cryptors when comparing, hashing, and describing `CryptoModule` values.

## [11.0.1] - 2026-10-16

No public SDK contract changes.

## [11.0.0] - 2026-10-12

> **Upgrade required:** This release contains breaking changes. See the
> [PubNub 11.0 Migration Guide](https://github.com/pubnub/swift/blob/11.0.0/Documentation/PubNub_11_0_Migration_Guide.md)
> for detailed migration instructions.

### Added

- Perform paginated create, fetch, replace, update, and remove operations through `PubNub.dataSync` for entities, users, channels, memberships, and relationships.
- Receive DataSync object changes as `PubNubDataSyncEvent` values through subscription listeners, including base and projection subscriptions.
- Parse DataSync resource permissions from Access Manager tokens, including the `create` permission.
- Configure `PubNubConfiguration` from a bundle containing an `originAt` key, falling back to `PubNubOrigin`.

### Changed

- **Breaking:** Use `target` instead of `entity` throughout the subscription API and remove the `Representation` suffix from subscription target types. **Migration:** Replace the renamed symbols with their `target`-based equivalents.
- **Breaking:** Create `Subscription` and `SubscriptionSet` instances through their `PubNub` factory methods. **Migration:** Replace direct initialization with the corresponding factory method.
- Emit the same `PubNubEvent` values from legacy and modern subscription listeners, including the new `dataSyncChanged` case.
- Configure `BaseSubscriptionListener.queue` and `supressCancellationErrors` during initialization, preventing unsafe mutation on an active listener.

### Deprecated

- Deprecate catch-all `SubscriptionListener` callbacks in favor of granular, event-specific callbacks. **Migration:** Register the callback corresponding to each event type the application handles.

### Removed

- **Breaking:** Remove the `PubNubUser`, `PubNubSpace`, and `PubNubMembership` products from Swift Package Manager distribution. **Migration:** Use the corresponding APIs distributed through `PubNubSDK`.

### Fixed

- Decode `yyyy-MM-dd` values as dates when a full ISO 8601 representation is unavailable.
- Prevent dictionaries from comparing equal to supersets containing additional keys.
- Ignore unrecognized subscribe-event types without interrupting delivery of valid events from the same response.

## [10.2.0] - 2026-09-03

### Added

- Configure non-alert APNs notifications with [`PubNubAPNSPayload.pushType`](https://github.com/pubnub/swift/blob/cddc5c38d44b9218c8a6ab80dcc593e91abf331e/Sources/PubNub/Models/PubNubAPNSPayload.swift#L34); when omitted, APNs continues to treat the notification as an alert.

## [10.1.8] - 2026-07-08

### Changed

- Keep presence state isolated between `PubNub` instances.

### Fixed

- Invoke message-action add and remove completion handlers only once when an error occurs.

### Security

- Reject invalid initialization-vector lengths, misaligned ciphertext, and legacy random-IV payloads too short to contain an IV before decryption.
- Return uniform `encryptionFailure` and `decryptionFailure` errors without exposing CommonCrypto status details.
- Redact authentication keys and tokens from logs.
- Default `PubNubLogger` to the `.none` log level and warn that verbose logging can expose sensitive data.

## [10.1.7] - 2026-06-15

No public SDK contract changes.

## [10.1.6] - 2026-05-12

### Added

- Log the negotiated transport protocol from `URLSessionTaskMetrics` for network diagnostics.
- Expose readable diagnostic output by adding `CustomStringConvertible` conformance to `RequestConfiguration`.

### Fixed

- Format `SubscribeMessagePayload` and `EmitMessagesEffect` descriptions as readable multiline output.

## [10.1.5] - 2026-04-23

### Changed

- Rename `URL.appending(queryItems:)` to `appendingQueryItems(_:)`, avoiding an ambiguity with the Foundation API of the same name.

### Fixed

- Preserve the warning category when forwarding SDK log messages.
- Report the correct channel groups in local `subscriptionChanged(.subscribed)` events.

## [10.1.4] - 2026-04-20

### Fixed

- Preserve message actions in history responses when `CryptoModule` is enabled.

## [10.1.3] - 2026-04-08

### Fixed

- Apply configuration changes immediately and safely to active Subscribe and Presence workflows.

## [10.1.2] - 2026-01-22

No public SDK contract changes.

## [10.1.1] - 2025-12-11

No public SDK contract changes.

## [10.1.0] - 2025-11-13

> **Upgrade required:** This release removes support for Microsoft Push
> Notification Service.

### Removed

- **Breaking:** Remove Microsoft Push Notification Service support following its end of life. **Migration:** Use APNs or FCM for supported mobile push notifications.

## [10.0.1] - 2025-10-23

No public SDK contract changes.

## [10.0.0] - 2025-10-21

> **Upgrade required:** This release contains breaking changes. See the
> [PubNub 10.0 Migration Guide](https://github.com/pubnub/swift/blob/10.0.0/Documentation/PubNub_10_0_Migration_Guide.md)
> for detailed migration instructions.

### Changed

- **Breaking:** Pass a `LogMessage` and `LogMetadata` to `LogWriter` implementations. **Migration:** Update custom writers to accept the structured message and metadata parameters.
- **Breaking:** Limit `hereNow` results to 1,000 occupants per channel. **Migration:** Paginate requests for channels that may contain more than 1,000 occupants.

### Removed

- **Breaking:** Remove public logger convenience methods such as `debug` and `warning`. **Migration:** Write log events through an attached logger.
- **Breaking:** Remove the static `log` and `logLog` properties from `PubNub`. **Migration:** Attach a logger when creating the `PubNub` instance.

## [9.3.5] - 2025-10-16

### Fixed

- Return `"fcm"` from `PubNub.PushService.fcm` while preserving the deprecated `.gcm` value as `"gcm"` for compatibility.

## [9.3.4] - 2025-09-15

### Fixed

- Handle history file-list responses that omit `limit` or `next` in `listFiles(channel:limit:next:custom:completion:)`.

## [9.3.3] - 2025-08-07

### Fixed

- Prevent crashes when application-performance monitoring libraries intercept URL session invalidation.

## [9.3.2] - 2025-08-06

No public SDK contract changes.

## [9.3.1] - 2025-07-31

### Fixed

- Prevent recursive locking when disposing a `SubscriptionSet`.

## [9.3.0] - 2025-07-29

> **Upgrade required:** This release changes the presence unsubscription API.

### Added

- Subscribe directly to presence channels and channel groups without subscribing to their main counterparts.

### Changed

- **Breaking:** Remove the `presenceOnly` parameter from `PubNub.unsubscribe(from:and:)`. **Migration:** Pass presence channels or channel groups explicitly.

## [9.2.3] - 2025-07-29

No public SDK contract changes.

## [9.2.2] - 2025-07-18

No public SDK contract changes.

## [9.2.1] - 2025-06-20

### Fixed

- Send a heartbeat after changing subscribed channels or channel groups, keeping presence state current.

## [9.2.0] - 2025-05-15

### Added

- Encrypt a local file with [`encryptStream(from:)`](https://github.com/pubnub/swift/blob/094d029c2bf55886dbf0e292398638d7a278a39b/Sources/PubNub/Helpers/Crypto/CryptoModule.swift#L217) without manually creating an `InputStream` or calculating its content length.

## [9.1.0] - 2025-05-13

### Added

- Return both the encrypted stream and its content length from [`encrypt(stream:contentLength:)`](https://github.com/pubnub/swift/blob/56b8f5ee4e1d6932f7e8b4efb2b0ea76fd9ac826/Sources/PubNub/Helpers/Crypto/CryptoModule.swift#L184).
- Decrypt local files with [`decryptStream(from:to:)`](https://github.com/pubnub/swift/blob/56b8f5ee4e1d6932f7e8b4efb2b0ea76fd9ac826/Sources/PubNub/Helpers/Crypto/CryptoModule.swift#L287) without manually creating an input stream or specifying its content length.

## [9.0.1] - 2025-03-20

### Fixed

- Include the endpoint error message in `PubNubError.details`.

## [9.0.0] - 2025-03-06

> **Upgrade required:** Custom `LogWriter` implementations must be updated. See
> the [PubNub 9.0 Migration Guide](https://github.com/pubnub/swift/blob/9.0.0/Documentation/PubNub_9_0_Migration_Guide.md)
> for detailed migration instructions.

### Added

- Provide `OSLogWriter` as the recommended adapter for Apple unified logging.
- Provide readable object diagnostics through `CustomStringConvertible`.

### Changed

- **Breaking:** Refine the `LogWriter` protocol to support Apple's `Logger`. **Migration:** Update custom writers to the new protocol signature.

## [8.3.1] - 2025-01-24

### Fixed

- Invoke request completion handlers in scenarios where they were previously skipped.

## [8.3.0] - 2025-01-20

### Added

- Support `ETag` values when setting channel and user metadata.

## [8.2.5] - 2025-01-16

### Fixed

- Prevent crashes caused by concurrent access to subscription state.

## [8.2.4] - 2025-01-10

No public SDK contract changes.

## [8.2.3] - 2025-01-03

No public SDK contract changes.

## [8.2.2] - 2024-12-11

### Fixed

- Reduce excessive memory usage when processing high message volumes.
- Populate `PubNubFileEvent.customMessageType` in received file events.

## [8.2.1] - 2024-12-09

No public SDK contract changes.

## [8.2.0] - 2024-12-04

### Added

- Expose the `type` field on `PubNubMembershipMetadata`.
- Provide `PubNub.ChannelIncludeFields` and `PubNub.UserIncludeFields` for type-safe App Context include options.

### Deprecated

- Deprecate App Context methods whose signatures use `uuid`, `uuids`, or Boolean `include` parameters. **Migration:** Use their user-oriented and typed-include replacements.
- Deprecate `remove(channel:custom:completion:)`. **Migration:** Use its replacement overload.
- Deprecate `uuidMetadataId` and `uuid` on `PubNubMembershipMetadata`. **Migration:** Use the corresponding user-oriented properties.
- Deprecate `PubNubUUIDMetadata`, `PubNubUUIDMetadataBase`, and `PubNubUUIDMetadataChangeset`. **Migration:** Use `PubNubUserMetadata`, `PubNubUserMetadataBase`, and `PubNubUserMetadataChangeset`; compatibility aliases remain available.

## [8.1.0] - 2024-11-18

### Added

- Support custom message types in publish, signal, file-sharing, subscribe, and history APIs.

## [8.0.1] - 2024-10-17

No public SDK contract changes.

## [8.0.0] - 2024-09-23

> **Upgrade required:** This release contains breaking changes. See the
> [PubNub 8.0 Migration Guide](https://github.com/pubnub/swift/blob/8.0.0/Documentation/PubNub_8_0_Migration_Guide.md)
> for detailed migration instructions.

### Added

- Attach additional listeners to `Subscription` and `SubscriptionSet`.
- Fetch additional fields through `PubNub.MembershipInclude` and `PubNub.MemberInclude`.

### Changed

- **Breaking:** Rename the imported module to `PubNubSDK`. **Migration:** Replace `import PubNub` with `import PubNubSDK`.
- Enable automatic retry for subscribe requests by default using an exponential reconnection policy.

### Removed

- **Breaking:** Remove the deprecated `connecting` and `reconnecting` connection statuses. **Migration:** Handle `subscriptionChanged(channels:groups:)` instead.
- **Breaking:** Remove `.legacyExponential(base:scale:maxDelay:)`. **Migration:** Use a supported automatic-retry policy.

### Fixed

- Prevent the SDK from retaining subscriptions after application references are released.

## [7.3.3] - 2024-09-13

### Fixed

- Synchronize access to weak and global subscription collections, preventing inconsistent state during concurrent updates.

## [7.3.2] - 2024-07-25

### Fixed

- Allow applications to construct `EncryptedData` and `EncryptedStreamData` through their public initializers.

## [7.3.1] - 2024-06-18

### Fixed

- Send presence leave requests when unsubscribing, including when heartbeat processing is inactive or stopped.

## [7.3.0] - 2024-06-12

### Changed

- Send Firebase Cloud Messaging notifications through the FCM HTTP v1 API.

## [7.2.1] - 2024-05-09

### Added

- Support visionOS.

### Fixed

- Refresh Event Engine dependencies after adding a subscription listener.

## [7.2.0] - 2024-04-16

### Added

- Bundle `PrivacyInfo.xcprivacy` so applications can include the SDK's required privacy declarations.

## [7.1.0] - 2024-03-18

### Fixed

- Keep an active subscription connected when subscribing through `PubNub` to an already-subscribed channel.
- Compute stable and consistent hash values for `CryptoModule`.

## [7.0.0] - 2024-02-21

> **Upgrade required:** This release enables Event Engine subscription handling
> by default.

### Added

- Provide the listener-based subscription API.

### Changed

- Enable Event Engine as the default Subscribe and Presence implementation.

## [6.3.0] - 2024-01-22

### Added

- Introduce Event Engine implementations for Subscribe and Presence workflows.

## [6.2.3] - 2023-11-28

### Fixed

- Receive unencrypted messages when `CryptoModule` is configured.

## [6.2.2] - 2023-10-30

### Changed

- Change the project license to the PubNub Software Development Kit License.

## [6.2.1] - 2023-10-23

> **Upgrade required:** This release renames the public crypto module.

### Changed

- **Breaking:** Rename `CryptorModule` to `CryptoModule`. **Migration:** Replace references to `CryptorModule` with `CryptoModule`.

## [6.2.0] - 2023-10-16

### Added

- Configure SDK message and file encryption through `CryptorModule`.

### Security

- Use `AESCBCCryptor` to strengthen the default cryptographic implementation.

## [6.1.0] - 2023-08-30

### Added

- Set `$PubNubAsStaticFramework` in a Podfile to choose whether CocoaPods integrates `PubNubSwift` as a static framework.

## [6.0.5] - 2023-05-18

### Fixed

- Send the `excluded_devices` field using the uppercase format expected by the push-notification API.

## [6.0.4] - 2023-03-16

### Changed

- Limit concurrent subscribe connections per host.
- Send presence leave requests through the subscribe URL session, reducing presence race conditions.

## [6.0.3] - 2023-01-05

### Fixed

- Release subscription listeners after applications remove their final strong reference.

## [6.0.2] - 2022-12-14

### Fixed

- Release subscription sessions when they are no longer in use.

## [6.0.1] - 2022-09-05

### Fixed

- Build the example project without a missing Swift reference error.
- Build the SDK through Carthage without schemes that reference missing targets.

## [6.0.0] - 2022-07-05

> **Upgrade required:** This release changes `PubNub` from a value type to a
> reference type.

### Added

- Expose VSP methods and models through modules on `PubNub`.
- Expose `HTTPSession` for per-request network-session overrides.

### Changed

- **Breaking:** Change `PubNub` from a `struct` to a `class`. **Migration:** Review code that depends on copying `PubNub` values or value semantics.
- Replace `[String: JSONCodableScalar]` with `FlatJSONCodable` in VSP models.

## [5.1.0] - 2022-02-02

### Added

- Include affected channels and channel groups in `PubNubError.affected`.

## [5.0.1] - 2022-01-19

### Fixed

- Apply updated access tokens to active subscription sessions.

## [5.0.0] - 2022-01-12

> **Upgrade required:** Applications must now provide a UUID explicitly.

### Changed

- **Breaking:** Stop generating UUIDs automatically in `PubNubConfiguration`. **Migration:** Supply a UUID when creating the configuration.

## [4.1.2] - 2021-11-08

### Changed

- Allow channel and UUID metadata to omit `name`.

## [4.1.1] - 2021-11-05

### Fixed

- Apply configured request mutators to outgoing requests.

## [4.1.0] - 2021-09-16

### Added

- Parse resource permissions from Access Manager tokens.
- Attach component identifiers to requests.

### Changed

- Prefer an access token over `authKey` when both are configured.

### Fixed

- Resize temporary file-encryption buffers when the configured stream buffer is too small.
- Send FCM device tokens as raw data instead of hexadecimal text.

[11.1.0]: https://github.com/pubnub/swift/compare/11.0.1...11.1.0
[11.0.1]: https://github.com/pubnub/swift/compare/11.0.0...11.0.1
[11.0.0]: https://github.com/pubnub/swift/compare/10.2.0...11.0.0
[10.2.0]: https://github.com/pubnub/swift/compare/10.1.8...10.2.0
[10.1.8]: https://github.com/pubnub/swift/compare/10.1.7...10.1.8
[10.1.7]: https://github.com/pubnub/swift/compare/10.1.6...10.1.7
[10.1.6]: https://github.com/pubnub/swift/compare/10.1.5...10.1.6
[10.1.5]: https://github.com/pubnub/swift/compare/10.1.4...10.1.5
[10.1.4]: https://github.com/pubnub/swift/compare/10.1.3...10.1.4
[10.1.3]: https://github.com/pubnub/swift/compare/10.1.2...10.1.3
[10.1.2]: https://github.com/pubnub/swift/compare/10.1.1...10.1.2
[10.1.1]: https://github.com/pubnub/swift/compare/10.1.0...10.1.1
[10.1.0]: https://github.com/pubnub/swift/compare/10.0.1...10.1.0
[10.0.1]: https://github.com/pubnub/swift/compare/10.0.0...10.0.1
[10.0.0]: https://github.com/pubnub/swift/compare/9.3.5...10.0.0
[9.3.5]: https://github.com/pubnub/swift/compare/9.3.4...9.3.5
[9.3.4]: https://github.com/pubnub/swift/compare/9.3.3...9.3.4
[9.3.3]: https://github.com/pubnub/swift/compare/9.3.2...9.3.3
[9.3.2]: https://github.com/pubnub/swift/compare/9.3.1...9.3.2
[9.3.1]: https://github.com/pubnub/swift/compare/9.3.0...9.3.1
[9.3.0]: https://github.com/pubnub/swift/compare/9.2.3...9.3.0
[9.2.3]: https://github.com/pubnub/swift/compare/9.2.2...9.2.3
[9.2.2]: https://github.com/pubnub/swift/compare/9.2.1...9.2.2
[9.2.1]: https://github.com/pubnub/swift/compare/9.2.0...9.2.1
[9.2.0]: https://github.com/pubnub/swift/compare/9.1.0...9.2.0
[9.1.0]: https://github.com/pubnub/swift/compare/9.0.1...9.1.0
[9.0.1]: https://github.com/pubnub/swift/compare/9.0.0...9.0.1
[9.0.0]: https://github.com/pubnub/swift/compare/8.3.1...9.0.0
[8.3.1]: https://github.com/pubnub/swift/compare/8.3.0...8.3.1
[8.3.0]: https://github.com/pubnub/swift/compare/8.2.5...8.3.0
[8.2.5]: https://github.com/pubnub/swift/compare/8.2.4...8.2.5
[8.2.4]: https://github.com/pubnub/swift/compare/8.2.3...8.2.4
[8.2.3]: https://github.com/pubnub/swift/compare/8.2.2...8.2.3
[8.2.2]: https://github.com/pubnub/swift/compare/8.2.1...8.2.2
[8.2.1]: https://github.com/pubnub/swift/compare/8.2.0...8.2.1
[8.2.0]: https://github.com/pubnub/swift/compare/8.1.0...8.2.0
[8.1.0]: https://github.com/pubnub/swift/compare/8.0.1...8.1.0
[8.0.1]: https://github.com/pubnub/swift/compare/8.0.0...8.0.1
[8.0.0]: https://github.com/pubnub/swift/compare/7.3.3...8.0.0
[7.3.3]: https://github.com/pubnub/swift/compare/7.3.2...7.3.3
[7.3.2]: https://github.com/pubnub/swift/compare/7.3.1...7.3.2
[7.3.1]: https://github.com/pubnub/swift/compare/7.3.0...7.3.1
[7.3.0]: https://github.com/pubnub/swift/compare/7.2.1...7.3.0
[7.2.1]: https://github.com/pubnub/swift/compare/7.2.0...7.2.1
[7.2.0]: https://github.com/pubnub/swift/compare/7.1.0...7.2.0
[7.1.0]: https://github.com/pubnub/swift/compare/7.0.0...7.1.0
[7.0.0]: https://github.com/pubnub/swift/compare/6.3.0...7.0.0
[6.3.0]: https://github.com/pubnub/swift/compare/6.2.3...6.3.0
[6.2.3]: https://github.com/pubnub/swift/compare/6.2.2...6.2.3
[6.2.2]: https://github.com/pubnub/swift/compare/6.2.1...6.2.2
[6.2.1]: https://github.com/pubnub/swift/compare/6.2.0...6.2.1
[6.2.0]: https://github.com/pubnub/swift/compare/6.1.0...6.2.0
[6.1.0]: https://github.com/pubnub/swift/compare/6.0.5...6.1.0
[6.0.5]: https://github.com/pubnub/swift/compare/6.0.4...6.0.5
[6.0.4]: https://github.com/pubnub/swift/compare/6.0.3...6.0.4
[6.0.3]: https://github.com/pubnub/swift/compare/6.0.2...6.0.3
[6.0.2]: https://github.com/pubnub/swift/compare/6.0.1...6.0.2
[6.0.1]: https://github.com/pubnub/swift/compare/6.0.0...6.0.1
[6.0.0]: https://github.com/pubnub/swift/compare/5.1.0...6.0.0
[5.1.0]: https://github.com/pubnub/swift/compare/5.0.1...5.1.0
[5.0.1]: https://github.com/pubnub/swift/compare/5.0.0...5.0.1
[5.0.0]: https://github.com/pubnub/swift/compare/4.1.2...5.0.0
[4.1.2]: https://github.com/pubnub/swift/compare/4.1.1...4.1.2
[4.1.1]: https://github.com/pubnub/swift/compare/4.1.0...4.1.1
[4.1.0]: https://github.com/pubnub/swift/compare/4.0.2...4.1.0
