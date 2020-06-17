# PubNub 3.0 Migration Guide
PubNub Native Swift SDK v3.0 is the latest major release of the PubNub SDK for iOS, tvOS, macOS and watchOS written in Swift. As a major release, following [Semantic Versioning](https://semver.org/) conventions, 3.0 introduces API-breaking changes.

This guide is meant to ease the transition to the 3.0 version of the SDK, but is not meant to be a complete guide to all changes made. To read the full set of documentation, please head over to our official [docs page](https://www.pubnub.com/docs/swift-native/pubnub-swift-sdk)

## Breaking API Changes
___

### Objects
* `PubNubUser` and `UserObject` have been replaced with `PubNubUUIDMetadata` and `PubNubUUIDMetadataBase` respectively
* `PubNubSpace` and `SpaceObject` have been replaced with `PubNubUUIDMetadata` and `PubNubUUIDMetadataBase` respectively
* `PubNubMembership` and `UserObjectMembership` have been replaced with `PubNubMembershipMetadata` and `PubNubMembershipMetadataBase`
* `PubNubMember` and `SpaceObjectMember` have also been replaced with `PubNubMembershipMetadata` and `PubNubMembershipMetadataBase`
* PubNub Object APIs have been replaced with `all`, `fetch`, `set`, and `remove` versions for each Metadata type

### Subscribe and Events
* A new `SubscriptionChangeEvent` is emitted every time subscribe response is received, even if it doesn't contain any new messages
* `SubscriptionListener` now has a `didReceiveBatchSubscription` event handler that emits a batched event containing a list of `SubscriptionEvent` objects.  Previously is a subscribe response contained multiple events, they would be emitted individually.
* `MessageEvent` has been replaced by the `PubNubMessage` protocol
* `PresenceEvent` has been replaced by the `PubNubPresenceChange` protocol
* `MembershipEvent` and `MembershipIdentifiable` have been replaced by `PubNubMembershipMetadata`
* `UserEvent` has been replaced by `PubNubUUIDMetadataChangeset`
* `SpaceEvent` has been replaced by `PubNubChannelMetadataChangeset`
* The access control for many Classes, Struct, and methods have been reduced.

### PubNub and Configuration
* All `PubNubConfiguration` properties can now be set through the default initializer
* `NetworkConfiguration` has been replaced with `RequestConfiguration`.  Now allows for Configuration and Network Session overrides per request.
* The `Result` of each PubNub API completion handler now has inline documentation
* APIs with pagination capabilities (`fetchHistory`, `fetchMessageActions`, etc) now take a `Page` parameter instead of individual `start` and `end` values
* Removed the ability to set presence state directly through subscribe.  Instead, use `setPresence` to set the user state on channels and channel-groups.
* Filter-expression can now be set directly through subscribe, or the `pubnub.subscribeFilterExpression` property
* The `also` parameter on `hereNow` has been renamed to `includeState`
* `delete(channelGroup:with:respondOn:completion)` has been renamed to `remove(channelGroup:custom:completion)`
* `modifyPushChannelRegistrations` has been renamed to `managePushChannelRegistrations`
* `modifyAPNSPushChannelRegistrations` has been renamed to `manageAPNSPushChannelRegistrations`
* `removeAPNSPushDevice` has been renamed to `removeAllAPNSPushDevice`
* The `max` parameter on `fetchMessageHistory` has been renamed `limit` to match other APIs
* `addMessageAction` now takes the `value` and `type` properties directly, instead of the full `MessageAction` object

### PubNub API Response Changes
* The custom objects found inside the success Results for many APIs have been replaced with primitives or common protocols
* Most of the protocol provided as responses or events can be converted directly into their custom object using the `transcode()` function
