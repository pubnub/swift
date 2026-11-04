# Changelog

All notable public changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## 11.1.0 - 2026-10-29

> **Upgrade required:** This release raises the minimum supported versions of
> iOS, tvOS, and watchOS.

### Added

- Decrypt AES-GCM payloads with `aesCbcCryptoModule(with:withRandomIV:)` and `legacyCryptoModule(with:withRandomIV:)`, improving compatibility with payloads produced by other PubNub SDKs without changing their encryption formats.

### Changed

- **Breaking:** Require iOS 13, tvOS 13, and watchOS 6 or later while retaining macOS 10.15 support; applications must raise the affected deployment targets before upgrading.

### Fixed

- Prevent `signal(channel:message:customMessageType:custom:completion:)` payloads from being encrypted when published or decrypted when received, restoring interoperability with other PubNub SDKs.
- Read and write cryptor-header metadata of 255 bytes or more, including metadata ending exactly at the end of a stream.
- Decrypt empty data and files without rejecting the plaintext as malformed.
- Include default and secondary cryptors when comparing, hashing, and describing `CryptoModule` values.

## 11.0.0 - 2026-10-12

> **Upgrade required:** This release contains breaking changes. See the
> [PubNub 11.0 Migration Guide](https://github.com/pubnub/swift/blob/11.0.0/Documentation/PubNub_11_0_Migration_Guide.md)
> for detailed migration instructions.

### Added

- Perform paginated create, fetch, replace, update, and remove operations through `PubNub.dataSync` for entities, users, channels, memberships, and relationships.
- Receive DataSync object changes as `PubNubDataSyncEvent` values through subscription listeners, including base and projection subscriptions.
- Parse DataSync resource permissions from Access Manager tokens, including the `create` permission.
- Configure `PubNubConfiguration` from a bundle containing an `originAt` key, falling back to `PubNubOrigin`.

### Changed

- **Breaking:** Rename `ChannelRepresentation`, `ChannelGroupRepresentation`, `UserMetadataRepresentation`, and `ChannelMetadataRepresentation` to `Channel`, `ChannelGroup`, `UserMetadata`, and `ChannelMetadata`.
- **Breaking:** Rename `Subscription.entity` to `Subscription.target` and replace `entities:` labels with `targets:` in subscription APIs.
- **Breaking:** Require `Subscription` and `SubscriptionSet` instances to be created through their `PubNub` factory methods instead of direct initialization.
- For applications using the legacy `SubscriptionListener`, emit the same `PubNubEvent` values as the modern listener API, including `dataSyncChanged(PubNubDataSyncEvent)`.
- Make `BaseSubscriptionListener.queue` and `BaseSubscriptionListener.supressCancellationErrors` immutable after initialization.

### Deprecated

- Deprecate `onEvent`, `onEvents`, `didReceiveSubscription`, and `didReceiveBatchSubscription` in favor of granular callbacks such as `onMessage`, `onSignal`, and `onPresence`.

### Removed

- **Breaking:** Remove the `PubNubUser`, `PubNubSpace`, and `PubNubMembership` products from Swift Package Manager distribution; their corresponding APIs remain available through `PubNubSDK`.

### Fixed

- Decode `yyyy-MM-dd` values as dates when a full ISO 8601 representation is unavailable.
- Prevent dictionaries from comparing equal to supersets containing additional keys.
- Ignore unrecognized subscribe-event types without interrupting delivery of valid events from the same response.

## 10.2.0 - 2026-09-03

### Added

- Configure non-alert APNs notifications with `PubNubAPNSPayload.pushType`; when omitted, APNs continues to treat the notification as an alert.

## 10.1.8 - 2026-07-08

### Changed

- For applications using multiple `PubNub` instances, keep each client's presence state isolated.

### Fixed

- Invoke message-action add and remove completion handlers only once when an error occurs.

### Security

- Reject invalid initialization-vector lengths, misaligned ciphertext, and legacy random-IV payloads too short to contain an IV before decryption.
- Return uniform `encryptionFailure` and `decryptionFailure` errors without exposing CommonCrypto status details.
- Redact authentication keys and tokens from logs.
- Default `PubNubLogger` to the `.none` log level and warn that verbose logging can expose sensitive data.

## 10.1.6 - 2026-05-12

### Added

- Log the negotiated transport protocol from `URLSessionTaskMetrics` for network diagnostics.
- Expose readable diagnostic output by adding `CustomStringConvertible` conformance to `RequestConfiguration`.

### Fixed

- Format `SubscribeMessagePayload.description` as readable multiline output.

## 10.1.5 - 2026-04-23

> **Upgrade required:** This release renames the public URL query-item helper.

### Changed

- **Breaking:** Rename `URL.appending(queryItems:)` to `URL.appendingQueryItems(_:)`, avoiding ambiguity with the Foundation API of the same name.

### Fixed

- Preserve the warning category when forwarding SDK log messages.
- Report the correct channel groups in local `subscriptionChanged(.subscribed)` events.

## 10.1.4 - 2026-04-20

### Fixed

- Preserve message actions in history responses when `CryptoModule` is enabled.

## 10.1.3 - 2026-04-08

### Fixed

- Apply configuration changes immediately and safely to active Subscribe and Presence workflows.

## 10.1.0 - 2025-11-13

> **Upgrade required:** This release removes support for Microsoft Push
> Notification Service.

### Removed

- **Breaking:** Remove Microsoft Push Notification Service support following its end of life; applications must use APNs or FCM for mobile push notifications.

## 10.0.0 - 2025-10-21

> **Upgrade required:** This release contains breaking changes. See the
> [PubNub 10.0 Migration Guide](https://github.com/pubnub/swift/blob/10.0.0/Documentation/PubNub_10_0_Migration_Guide.md)
> for detailed migration instructions.

### Changed

- **Breaking:** For custom `LogWriter` implementations, replace `send(message:withType:withCategory:)` with `send(message:metadata:)`, which receives `LogMessage` and `LogMetadata`.
- **Breaking:** Rename `LogType` to `LogLevel` and add the `.trace` level.
- **Breaking:** Add `limit` and `offset` to `hereNow`; results are limited to 1,000 occupants per channel, so applications must paginate larger channel populations.

### Removed

- **Breaking:** Remove public `PubNubLogger.debug`, `info`, `event`, `warn`, and `error` methods; applications must use their own logging API for application messages.
- **Breaking:** Remove `PubNub.log` and `PubNub.logLog`; configure SDK logging through `PubNub.init(configuration:logger:)`.

## 9.3.5 - 2025-10-16

### Fixed

- Return `"fcm"` from `PubNub.PushService.fcm` while preserving the deprecated `.gcm` value as `"gcm"` for compatibility.

## 9.3.4 - 2025-09-15

### Fixed

- Handle history file-list responses that omit `limit` or `next` in `listFiles(channel:limit:next:custom:completion:)`.

## 9.3.3 - 2025-08-07

### Fixed

- For applications using performance-monitoring libraries that intercept URL sessions, prevent crashes during session invalidation.

## 9.3.1 - 2025-07-31

### Fixed

- Prevent recursive locking when disposing a `SubscriptionSet`.

## 9.3.0 - 2025-07-29

> **Upgrade required:** This release changes the presence unsubscription API.

### Added

- Subscribe directly to presence channels and channel groups without subscribing to their main counterparts.

### Changed

- **Breaking:** Remove the `presenceOnly` parameter from `PubNub.unsubscribe(from:and:)`; pass presence channels or channel groups explicitly.

## 9.2.1 - 2025-06-20

### Fixed

- Send a heartbeat after changing subscribed channels or channel groups, keeping presence state current.

## 9.2.0 - 2025-05-15

### Added

- Encrypt a local file with `encryptStream(from:)` without manually creating an `InputStream` or calculating its content length.

## 9.1.0 - 2025-05-13

### Added

- Return both the encrypted stream and its content length from `encrypt(stream:contentLength:)`.
- Decrypt local files with `decryptStream(from:to:)` without manually creating an input stream or specifying its content length.

## 9.0.1 - 2025-03-20

### Fixed

- Include the endpoint error message in `PubNubError.details`.

## 9.0.0 - 2025-03-06

> **Upgrade required:** Custom `LogWriter` implementations must be updated. See
> the [PubNub 9.0 Migration Guide](https://github.com/pubnub/swift/blob/9.0.0/Documentation/PubNub_9_0_Migration_Guide.md)
> for detailed migration instructions.

### Added

- Provide `OSLogWriter` as the recommended adapter for Apple unified logging.
- Provide readable object diagnostics through `CustomStringConvertible`.

### Changed

- **Breaking:** For custom `LogWriter` implementations, replace `send(message:)` with `send(message:withType:withCategory:)`.

## 8.3.1 - 2025-01-24

### Fixed

- Return a `PubNubError` with reason `.clientCancelled` through the request completion handler when a session is invalidated before its initialized task starts.

## 8.3.0 - 2025-01-20

### Added

- Support `ETag` values when setting channel and user metadata.

## 8.2.5 - 2025-01-16

### Fixed

- Prevent crashes caused by concurrent access to subscription state.

## 8.2.2 - 2024-12-11

### Fixed

- Reduce excessive memory usage when processing high message volumes.
- Populate `PubNubFileEvent.customMessageType` in received file events.

## 8.2.0 - 2024-12-04

### Added

- Expose the `type` field on `PubNubMembershipMetadata`.
- Provide `PubNub.ChannelIncludeFields` and `PubNub.UserIncludeFields` for type-safe App Context include options.

### Deprecated

- Deprecate App Context methods whose signatures use `uuid`, `uuids`, or Boolean `include` parameters in favor of their user-oriented and typed-include replacements.
- Deprecate `remove(channel:custom:completion:)` in favor of its replacement overload.
- Deprecate `uuidMetadataId` and `uuid` on `PubNubMembershipMetadata` in favor of the corresponding user-oriented properties.
- Deprecate `PubNubUUIDMetadata`, `PubNubUUIDMetadataBase`, and `PubNubUUIDMetadataChangeset` in favor of `PubNubUserMetadata`, `PubNubUserMetadataBase`, and `PubNubUserMetadataChangeset`; compatibility aliases remain available.

## 8.1.0 - 2024-11-18

### Added

- Add `customMessageType` to publish, signal, and file-sharing requests and expose it on received `PubNubMessage` and `PubNubFileEvent` values, including history results.

## 8.0.0 - 2024-09-23

> **Upgrade required:** This release contains breaking changes. See the
> [PubNub 8.0 Migration Guide](https://github.com/pubnub/swift/blob/8.0.0/Documentation/PubNub_8_0_Migration_Guide.md)
> for detailed migration instructions.

### Added

- Attach additional listeners to `Subscription` and `SubscriptionSet`.
- Fetch additional fields through `PubNub.MembershipInclude` and `PubNub.MemberInclude`.

### Changed

- **Breaking:** Rename the imported module from `PubNub` to `PubNubSDK`, requiring applications to update their import.
- Enable automatic retry for subscribe requests by default using an exponential reconnection policy.

### Removed

- **Breaking:** Remove the deprecated `connecting` and `reconnecting` connection statuses in favor of `subscriptionChanged(channels:groups:)`.
- **Breaking:** Remove `.legacyExponential(base:scale:maxDelay:)` in favor of the supported automatic-retry policies.

### Fixed

- Prevent the SDK from retaining subscriptions after application references are released.

## 7.3.3 - 2024-09-13

### Fixed

- Prevent inconsistent subscription state when applications update subscriptions concurrently.

## 7.3.2 - 2024-07-25

### Fixed

- Allow applications to construct `EncryptedData` and `EncryptedStreamData` through their public initializers.

## 7.3.1 - 2024-06-18

### Fixed

- Send presence leave requests when unsubscribing, including when heartbeat processing is inactive or stopped.

## 7.3.0 - 2024-06-12

### Changed

- Send Firebase Cloud Messaging notifications through the FCM HTTP v1 API.

## 7.2.1 - 2024-05-09

### Added

- Support visionOS.

### Fixed

- Ensure subscription listeners added after Event Engine initialization receive subsequent events.

## 7.2.0 - 2024-04-16

### Added

- Bundle `PrivacyInfo.xcprivacy` so applications can include the SDK's required privacy declarations.

## 7.1.0 - 2024-03-18

### Fixed

- Keep an active subscription connected when subscribing through `PubNub` to an already-subscribed channel.
- Compute stable and consistent hash values for `CryptoModule`.

## 7.0.0 - 2024-02-21

> **Upgrade required:** This release enables Event Engine subscription handling
> by default.

### Added

- Add `EventListener` and `StatusListener` APIs for receiving subscription events and connection-status changes.

### Changed

- **Breaking:** Enable Event Engine as the default Subscribe and Presence implementation.

## 6.3.0 - 2024-01-22

### Added

- Allow applications to opt into the experimental Subscribe and Presence Event Engine with `PubNubConfiguration.enableEventEngine`.

## 6.2.3 - 2023-11-28

### Fixed

- Receive unencrypted messages when `CryptoModule` is configured.

## 6.2.2 - 2023-10-30

### Changed

- Change the project license to the PubNub Software Development Kit License.

## 6.2.1 - 2023-10-23

> **Upgrade required:** This release renames the public crypto module.

### Changed

- **Breaking:** Rename `CryptorModule` to `CryptoModule`, requiring references to use the new name.

## 6.2.0 - 2023-10-16

### Added

- Configure message and file encryption through `PubNubConfiguration.cryptorModule` using `CryptorModule`, `AESCBCCryptor`, `LegacyCryptor`, or a custom `Cryptor`.

### Deprecated

- Deprecate `PubNubConfiguration.cipherKey` in favor of `PubNubConfiguration.cryptorModule`.

### Security

- Use `AESCBCCryptor` to strengthen the default cryptographic implementation.

## 6.1.0 - 2023-08-30

### Added

- Set `$PubNubAsStaticFramework` in a Podfile to choose whether CocoaPods integrates `PubNubSwift` as a static framework.

## 6.0.5 - 2023-05-18

### Fixed

- Send the `excluded_devices` field using the uppercase format expected by the push-notification API.

## 6.0.4 - 2023-03-16

### Changed

- Limit concurrent subscribe connections per host.
- Send presence leave requests through the subscribe URL session, reducing presence race conditions.

## 6.0.3 - 2023-01-04

### Fixed

- Release subscription listeners after applications remove their final strong reference.

## 6.0.2 - 2022-12-14

### Fixed

- Release subscription sessions when they are no longer in use.

## 6.0.1 - 2022-09-05

### Fixed

- Build the SDK through Carthage without schemes that reference missing targets.

## 6.0.0 - 2022-07-05

> **Upgrade required:** This release changes `PubNub` from a value type to a
> reference type.

### Added

- Add App Context APIs for UUID metadata, channel metadata, memberships, and members, including `allUUIDMetadata`, `allChannelMetadata`, `fetchMemberships`, and `fetchMembers`.
- Add `FlatJSONCodable` and `OptionalChange` for App Context custom fields and partial updates.
- Expose `HTTPSession` and `HTTPSessionDelegate` for per-request network-session overrides.

### Changed

- **Breaking:** Change `PubNub` from a `struct` to a `class`; applications that copy `PubNub` values can no longer rely on value semantics.
- **Breaking:** Replace `[String: JSONCodableScalar]` custom fields with `FlatJSONCodable` in App Context models.

## 5.1.0 - 2022-02-02

### Added

- Include affected channels and channel groups in `PubNubError.affected`.

## 5.0.1 - 2022-01-19

### Fixed

- Apply updated access tokens to active subscription sessions.

## 5.0.0 - 2022-01-12

> **Upgrade required:** Applications must now provide a UUID explicitly.

### Changed

- **Breaking:** Stop generating UUIDs automatically in `PubNubConfiguration`, requiring applications to supply the `uuid` parameter when creating the configuration.

## 4.1.2 - 2021-11-09

### Changed

- Make `PubNubChannelMetadata.name` and `PubNubUUIDMetadata.name` optional, with a default value of `nil` in their base-model initializers.

## 4.1.1 - 2021-11-05

### Fixed

- Send the mutated `URLRequest` returned by a `RequestOperator` instead of the original request.

## 4.1.0 - 2021-09-17

### Added

- Parse `PAMToken.authorizedUUID`, UUID resources, and `PAMPermission.get`, `update`, and `join` from Access Manager tokens.
- Add component identifiers to the `pnsdk` request parameter with `PubNub.setConsumer(identifier:value:)` or `PubNubConfiguration.consumerIdentifiers`.

### Changed

- Prefer an access token over `authKey` when both are configured.

### Fixed

- Resize temporary file-encryption buffers when the configured stream buffer is too small.
- Send FCM device tokens as raw data instead of hexadecimal text.
