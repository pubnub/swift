## [11.1.0] - 2026-10-29

### Added
- Raise minimum deployment targets to iOS 13, tvOS 13, and watchOS 6. Since September 9, 2026, iOS and iPadOS apps uploaded to App Store Connect must target iOS 13 or later. tvOS and watchOS minimums are raised to the matching OS generation. macOS is unchanged.

- Decrypt AES-GCM payloads in `CryptoModule.aesCbcCryptoModule` and `CryptoModule.legacyCryptoModule`. Both factory methods can now read AES-GCM payloads published by other PubNub SDKs, with no configuration change. What these modules encrypt is unchanged.

### Fixed
- Signals are no longer encrypted when published or decrypted when received. Signals were previously sent through the encryption path when a `CryptoModule` was configured, which is a bug: the signal payload is not encrypted by other PubNub SDKs, so it could not be read by them and failed to decode when received from them.
- Read and write cryptor header metadata of 255 bytes or more.
- Accept cryptor header metadata ending exactly at the buffer end in stream decryption.
- Include default cryptor and keys in `CryptoModule` equality and hashing.
- Print secondary cryptors in `CryptoModule.description`.
- Allow empty plaintext when decrypting data and files.

## [11.0.1] - 2026-10-16

### Fixed
- Fix KMP DataSync bridge ObjC header parsing (internal use)

## [11.0.0] - 2026-10-12

**This version introduces breaking changes. Please visit [PubNub 11.0 Migration Guide](https://github.com/pubnub/swift/blob/master/Documentation/PubNub_11_0_Migration_Guide.md) for detailed information and instructions**

### Added
- Adds the `pubnub.dataSync` namespace with paged fetch, create, replace, update, and remove operations for entities, users, channels, memberships, and relationships. Object changes are delivered to subscribe listeners as `PubNubDataSyncEvent`, and DataSync subscribe targets support both base and projection subscriptions.

- Access Manager tokens now parse DataSync resource permissions and expose the new `create` permission alongside the existing ones.

- `PubNubConfiguration.init(bundle:)` accepts an `originAt:` plist key, defaulting to `PubNubOrigin`.

### Removed
- `PubNubUser`, `PubNubSpace`, and `PubNubMembership` are no longer built or distributed via SPM

### Changed
- `entity` now means a DataSync record, so the subscribe API uses `target` instead; the subscribe target types drop the `Representation` suffix, and `Subscription` / `SubscriptionSet` are created only through the `PubNub` factory methods.

- The legacy `SubscriptionListener` emits the same `PubNubEvent` type as the modern listener API, and the catch-all event callbacks are deprecated in favor of the granular per-type ones. `PubNubEvent` gains a `dataSyncChanged` case.

- `BaseSubscriptionListener.queue` and `supressCancellationErrors` are now passed to the initializer, removing a data race when they were mutated on a live listener.

### Fixed
- `yyyy-MM-dd` values now decode as dates, as an ISO 8601 fallback.

- Fixes an issue where a dictionary compared equal to any superset of itself, because only the left operand's keys were checked. Key counts are now compared first.

- The SDK now skips subscribe messages whose `e` value it does not recognize. Messages that omit `e` preserve current inference behavior, while malformed entries no longer disrupt delivery of the remaining batch.

## [10.2.0] - 2026-09-03

### Added
- Add an optional `pushType` property that maps to the `apns-push-type` header required for non-alert notifications such as VoIP. When omitted, the payload excludes the key, and APNs defaults to alert.

## [10.1.8] - 2026-07-08

### Fixed
- Validate IV length and ciphertext block-alignment before decrypting.
- Return a uniform .decryptionFailure that never exposes the underlying CommonCrypto status.
- Guard LegacyCryptor random-IV path against payloads too short to contain an IV.
- Map encrypt-path errors to .encryptionFailure instead of .decryptionFailure .
- Redact authKey and authToken in instance logs instead of emitting them in cleartext.
- Use .none as the default log level for the PubNubLogger public initializer to avoid an insecure default.
- Make message action add/remove fire completion only once on error.

### Modified
- Warn that verbose log levels may expose sensitive data and recommend long, high-entropy cipher keys.
- Make every PubNub instance manage its own presence-state container.

## [10.1.7] - 2026-06-15

### Fixed
- Improve inline docs for CryptoModule and LegacyCryptor APIs.

## [10.1.6] - 2026-05-12

### Added
- Log negotiated transport protocol from `URLSessionTaskMetrics` for network diagnostics.

### Fixed
- Pretty-print `SubscribeMessagePayload` and `EmitMessagesEffect` descriptions with multi-line formatting.
- Adds `CustomStringConvertible` conformance to `RequestConfiguration` for improved debug output.

## [10.1.5] - 2026-04-23

### Fixed
- Forward missing `category` parameter when PubNub internally logs a warning message.
- Fix wrong channel groups reported in the local `subscriptionChanged(.subscribed)` event.
- Rename `URL.appending(queryItems:)` to `appendingQueryItems(_:)` to resolve ambiguity with the same method Apple added to Foundation.

## [10.1.4] - 2026-04-20

### Fixed
- Fixed an issue where message actions were silently dropped from history responses when CryptoModule was enabled.

## [10.1.3] - 2026-04-08

### Fixed
- Added a `didSet` observer on the strategy's `configuration` property to immediately refresh Subscribe & Presence workflow dependencies on any config change. Made `EventEngine.dependencies` thread-safe with the existing recursive lock.

## [10.1.2] - 2026-01-22

### Fixed
- Pass limit and offset parameters in KMP hereNow Presence call (internal use).

## [10.1.1] - 2025-12-11

### Added
- Expose logLevel property in the Objective-C layer for KMP (internal use).

## [10.1.0] - 2025-11-13

### Modified
- Remove MPNS (Microsoft Push Notification Service) support due to its end-of-life.

## [10.0.1] - 2025-10-23

### Fixed
- Remove redundant string joining in subscription logging.

## [10.0.0] - 2025-10-21

**This version introduces breaking changes. Please visit [PubNub 10.0 Migration Guide](https://github.com/pubnub/swift/blob/10.0.0/Documentation/PubNub_10_0_Migration_Guide.md) for detailed information and instructions**

### Added
- The `LogWriter` protocol method signature has been refined to accept a `LogMessage` object representing the logged content. It now also takes a `LogMetadata` parameter, allowing logging decisions to be made without evaluating the message itself.

### Removed
- Logging methods such as `debug`, `warning`, etc, are no longer public. They are now internal as part of the logging encapsulation improvements.

- The static `log` and `logLog` properties have been removed from the PubNub instance. You can now attach a logger instance via the PubNub initializer instead.

### Changed
- The `HereNow` method now returns a maximum of 1,000 occupants per channel. Previously, it would return all occupants regardless of count. If you have channels with more than 1,000 occupants, you must use pagination to retrieve the complete list.

## [9.3.5] - 2025-10-16

### Fixed
- Update underlying string values for `PubNub.PushService`. This change updates .fcm to return "fcm" instead of "gcm", while the deprecated .gcm continues to return "gcm" for backward compatibility.

## [9.3.4] - 2025-09-15

### Fixed
- Handle missing `limit` and `next` parameters in the `listFiles(channel:limit:next:custom:completion:)` method.

## [9.3.3] - 2025-08-07

### Fixed
- APM libraries crash fix: Removed `deinit` methods that were calling `session.invalidateAndCancel()` from `PresenceEffectFactory` and `SubscribeEffectFactory` to prevent race conditions with Application Performance Monitoring libraries. Session cleanup now happens exclusively in [HTTPSession.deinit](https://github.com/pubnub/swift/blob/9.3.2/Sources/PubNub/Networking/HTTPSession.swift#L96-L99), which ensures request cancellation before invalidation. This prevents crashes from occurring inside APM libraries when they intercept network operations during session invalidation.

## [9.3.2] - 2025-08-06

### Fixed
- Implement missing token parsing logic in KMP layer (internal use).

## [9.3.1] - 2025-07-31

### Fixed
- Fix the issue with recursive locking introduced in 9.3.0 when disposing a SubscriptionSet.

## [9.3.0] - 2025-07-29

### Added
- Add the ability to subscribe to presence channels only, without their main counterparts.

This version introduces presence-only subscription support, allowing users to subscribe to presence channels/channel groups without requiring their main channel/channel groups counterparts. Also, the `unsubscribe(from:and:)` method in a PubNub class has been simplified by removing the `presenceOnly:` parameter. If you were using `presenceOnly: true`, pass presence channels or channel groups explicitly as parameters instead.

## [9.2.3] - 2025-07-29

### Fixed
- Fix WeakBox hash stability.

## [9.2.2] - 2025-07-18

### Fixed
- Add a wrapper around the reconnecting method for KMP (internal use).

## [9.2.1] - 2025-06-20

### Fixed
- Add missing heartbeat call when changing channels or channel groups.

## [9.2.0] - 2025-05-15

### Added
- The `encryptStream(from:)` convenience method in CryptoModule is designed to encrypt a local file. It eliminates the need for the caller to provide an `InputStream` and its content length - these are handled internally. You only need to pass a local file URL.

## [9.1.0] - 2025-05-13

### Added
- The `encrypt(stream:contentLength:)` method in `CryptoModule` now returns an `EncryptedStreamResult` containing both the encrypted stream and its total content length

```swift
// Before
if case .success(let result) = cryptoModule.encrypt(stream: fileStream, contentLength: fileSize) {
  // The `result` variable is of type `InputStream` representing an encoded stream.
  // There's no information about the total length of the encoded stream
}

// Now
if case .success(let result) = cryptoModule.encrypt(stream: fileStream, contentLength: fileSize) {
  // The `result` variable is of type `EncryptedStreamResult`, containing both the encrypted stream 
  // and its content length:
  let stream = result.stream 
  let totalLength = result.contentLength
}
```

- The new `decryptStream(from:to:)` method in `CryptoModule` simplifies file decryption by accepting two local file URLs - one for the source and one for the destination - and automatically handling the low-level details, unlike `decrypt(stream:contentLength:to:)`, which required manually creating an InputStream and specifying the content length

## [9.0.1] - 2025-03-20

### Fixed
- Include endpoint error message in PubNubError's `details` property.
- Defer computing the textual representation of EventEngine's current and previous states until needed.

## [9.0.0] - 2025-03-06

**This version introduces breaking changes when providing a custom `LogWriter`. Please visit [PubNub 9.0 Migration Guide](https://github.com/pubnub/swift/blob/9.0.0/Documentation/PubNub_9_0_Migration_Guide.md) for detailed information and instructions**

### Added
- Add `OSLogWriter` as the recommended `LogWriter` to use.
- Refine `LogWriter` protocol signature to support built-in `Logger` from the `os` framework.
- Enhance object descriptions with `CustomStringConvertible`.
- Add explanatory documentation for debug-level logging messages.

## [8.3.1] - 2025-01-24

### Fixed
- Fix the issue where the request's completion handler is not invoked in certain scenarios.

## [8.3.0] - 2025-01-20

### Added
- Add `ETag` support for setting Channel and User metadata.

## [8.2.5] - 2025-01-16

### Fixed
- Fix the crash issue caused by multiple accesses to the `state` property in multithreaded scenarios.

## [8.2.4] - 2025-01-10

### Fixed
- Fix the issue of passing an invalid value for the `storeTTL` parameter in the KMP layer (internal use).
- Handle `shouldCompress` parameter in the KMP layer (internal use).

## [8.2.3] - 2025-01-03

### Added
- Handle all possible values for the `include` field in the KMP layer (internal usage).

## [8.2.2] - 2024-12-11

### Fixed
- Fix excessive memory usage in the high-volume messages use case.
- Add missing `customMessageType` in `PubNubFileEvent`.

## [8.2.1] - 2024-12-09

### Added
- Add support for`customMessageType` in the KMP layer (internal usage).

## [8.2.0] - 2024-12-04

### Added
- Add the `type` field in `PubNubMembershipMetadata`
- Deprecate the methods of AppContext that contain `uuid` or `uuids` in their signatures,  introduce new versions.
- Deprecate the methods of AppContext that contain `include` parameter of the `Bool` type, introduce new versions.
- Deprecate `remove(channel:custom:completion:)`, introduce new version.
- Deprecate `uuidMetadataId` and `uuid` in `PubNubMembershipMetadata`, introduce new properties.
- Deprecate `PubNub.IncludeFields`, introduce `PubNub.ChannelIncludeFields` and `PubNub.UserIncludeFields` instead
- Replace `PubNubUUIDMetadata` with `PubNubUserMetadata`.
- Replace `PubNubUUIDMetadataBase` with `PubNubUserMetadataBase`.
- Add an alias for backward compatibility with the customer code using `PubNubUUIDMetadata`.
- Add an alias for backward compatibility with the customer code using `PubNubUUIDMetadataBase`.
- Replace `PubNubUUIDMetadataChangeset` with `PubNubUserMetadataChangeset`.
- Add an alias for backward compatibility with the customer code using `PubNubUUIDMetadataChangeset`.

## [8.1.0] - 2024-11-18

### Added
- Add custom message type support for the following APIs: publish, signal, share file, subscribe, and history.

## [8.0.1] - 2024-10-17

### Added
- Add getToken() method for KMPPubNub (internal usage).

## [8.0.0] - 2024-09-23

**This version introduces breaking changes. Please visit [PubNub 8.0 Migration Guide](https://github.com/pubnub/swift/blob/8.0.0/Documentation/PubNub_8_0_Migration_Guide.md) for detailed information and instructions**

### Added
- Replace module name with `PubNubSDK` due to compiler error when a public type shares the same name as the module.
-  Add new `subscriptionChanged(channels, groups)` connection status and remove previously deprecated `connecting` and `reconnecting` cases.
- Remove previously deprecated `.legacyExponential(base, scale, maxDelay)` reconnection policy.
- Added additional fields to fetch in `PubNub.MembershipInclude` and `PubNub.MemberInclude`.
- Set default `AutomaticRetry` for retrying subscribe requests with exponential reconnection policy.
- Add support for attaching additional listeners to `Subscription` and `SubscriptionSet`.

### Fixed
- Ensure that subscriptions are always internally stored as weak references.

## [7.3.3] - 2024-09-13

### Fixed
- Added synchronized access inside `WeakSet` and for global subscriptions. Fixed the following issues reported by @cmriboldi: #186.

## [7.3.2] - 2024-07-25

### Fixed
- Add missing public initializers for `EncryptedData` and `EncryptedStreamData`. Fixed the following issues reported by @OwenHarper1: #182.

## [7.3.1] - 2024-06-18

### Fixed
- Calling .leave request in missing cases.

## [7.3.0] - 2024-06-12

### Added
- Adjusting to FCM HTTP v1 API.

## [7.2.1] - 2024-05-09

### Added
- Adding support for visionOS.

### Fixed
- Updating EventEngine dependencies after adding a new listener.

## [7.2.0] - 2024-04-16

### Added
- Adding PrivacyInfo.xcprivacy.
- Moving retry logic away from EventEngine.

### Modified
- Removing SubscribeSessionFactory with SubscriptionConfiguration.
- Making SubscriptionSession class an internal.

## [7.1.0] - 2024-03-18

### Fixed
- Preventing disconnection when subscribing via `PubNub` to a channel that was already subscribed to.
- Fixes for computing a hash value in `CryptoModule`.

## [7.0.0] - 2024-02-21

### Added
- Adding the new Listeners API.
- Enabling EventEngine by default.

## [6.3.0] - 2024-01-22

### Added
- Introducing Subscribe & Presence EventEngine.

## [6.2.3] - 2023-11-28

### Fixed
- Handle unencrypted message while getting it with CryptoModule configured.

## [6.2.2] - 2023-10-30

### Changed
Changed license type to `PubNub Software Development Kit License`

## [6.2.1] - 2023-10-23

### Fixed
Renaming `CryptorModule` with `CryptoModule`

## [6.2.0] - 2023-10-16

### Fixed
Improved security of crypto implementation by adding `AESCBCCryptor`

### Added
`CryptorModule` that allows configuring SDK to encrypt and decrypt messages

## [6.1.0] - 2023-08-30

### Added
- To make client integration more flexible for different projects setup, the `$PubNubAsStaticFramework` flag has been added to `PubNubSwift.podspec`.  With `$PubNubAsStaticFramework = true` in `Podfile` SDK will be integrated as a static library. Fixed the following issues reported by @Krisztiaan: #142.

## [6.0.5] - 2023-05-18

### Fixed
- Uppercasing of the `excluded_devices` field to match the format expected by the REST API.

## [6.0.4] - 2023-03-16

### Modified
- Change the settings for subscribe `URLSession` and limit the number of concurrent connections per host.
- Call presence leave using subscribe `URLSession` to avoid potential presence race of condition.

## [6.0.3] - 2023-01-05

### Fixed
- Fix issue because of which listener wasn't `deinit` even when reference on it has been nullified. Fixed the following issues reported by @AirBlack: #92.

## [6.0.2] - 2022-12-14

### Fixed
- Fix memory leak within Subscription Session.

### Modified
- Use specific GitHub action for `.pubnub.yml` validation.

## [6.0.1] - 2022-09-05

### Fixed
- Fix issue because of which `Example` project didn't built with missing `swift` reference error. Fixed the following issues reported by @SSheldon: #113.
- Fix issue because of which Carthage was unable to build caused by schemas without targets. Fixed the following issues reported by @SSheldon: #111 and #112.

## [6.0.0] - 2022-07-05

### Added
- VSP methods and models have been exposed via modules on the PubNub instance.
- `FlatJSONCodable` replaces `[String: JSONCodableScalar]` inside the VSP models.

### Modified
- PubNub instances has been changed from a `struct` to a `class`.
- `HTTPSession` has been made public for easier per-request overrides of the Network Session.

## [5.1.0] - 2022-02-02

### Added
- Add affected channels and groups under `affected` resources list.

## [5.0.1] - 2022-01-19

### Fixed
- Fix issue because of which access token not updated in subscription session.

## [5.0.0] - 2022-01-12

### Modified
- BREAKING CHANGES: Disable automated `uuid` generation and make it mandatory to specify during PubNubConfiguration instance creation.

## [4.1.2] - 2021-11-08

### Fixed
- Make `name` field optional for channel and UUID metadata.

## [4.1.1] - 2021-11-05

### Fixed
- Fix issue because of which request with applied mutators not used.

## [4.1.0] - 2021-09-16

### Added
- Add ability to parse permissions from token provided by servers.
- Make it possible to add component identifiers for requests.

### Fixed
- Fix `bufferTooSmall` and make temporary buffers for files encryption / decryption adaptive in size to provided stream buffer size.
- Don't perform HEX-encoding of `Data` with FCM token which should be used as-is.

### Modified
- Use `token` instead of `authKey` (if specified) for query `auth`.
