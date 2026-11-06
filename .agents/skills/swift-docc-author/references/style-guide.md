# PubNub DocC Style Guide

Use this guide when creating or reviewing inline documentation comments for the PubNub Swift SDK.

## Contract-first test

Include information when it helps answer:

- What does this API represent or do?
- When should a caller use it?
- What changes or happens after using it?
- What do special values such as `nil`, zero, or an empty collection mean?
- Which queue or actor delivers a callback?
- Can the operation be repeated, cancelled, restarted, or disposed?
- Is data retained, restored, stored, removed, or delivered later?
- Which condition enables or disables the behavior?
- Which related API provides a meaningfully different behavior?

Usually exclude a fact when the implementation could change without changing anything callers observe.

For example, document that a callback runs on a particular queue. Do not document which internal adapter forwards it to that queue.

## Comment shape

Use only the sections that add useful information:

```swift
/// <One sentence describing the symbol's role or observable effect.>
///
/// <When to use it and caller-visible behavior that needs explanation.>
///
/// <Defaults, special values, conditions, lifecycle, side effects, or alternatives.>
///
/// - Parameters:
///   - parameter: <Its purpose and how it affects behavior.>
/// - Returns: <The meaning, ownership, or lifetime of the result.>
/// - Throws: <Concrete circumstances that cause failure.>
/// - Important: <A requirement whose violation makes usage incorrect.>
/// - Note: <Useful supplemental information.>
/// - Warning: <A meaningful security, data-loss, compatibility, or lifecycle risk.>
```

The abstract is the first paragraph and must work by itself in Quick Help.

## Abstract conventions

Types use a noun phrase:

```swift
/// A subscription that receives events for a single ``Subscribable``.
```

Functions and methods use third-person present tense:

```swift
/// Publishes a message to a channel.
```

Properties describe their meaning:

```swift
/// The queue on which the subscription invokes event handlers.
```

Boolean properties state what `true` means:

```swift
/// A Boolean value that indicates whether the subscription has been disposed.
```

Enum cases describe their meaning or effect:

```swift
/// Delivers content silently and wakes the app in the background.
case background
```

Avoid empty summaries such as "The channel", "Message callback", "Default initializer", or "Whether the option is enabled".

## Parameters, returns, and errors

Describe a parameter's purpose and behavioral impact rather than repeating its type:

```swift
/// - Parameter queue: The queue on which the subscription delivers events.
```

Document special values where they change behavior:

```swift
/// - Parameter timetoken: The point from which to resume receiving events. Pass `nil` to receive events from the current point in time.
```

Describe what a returned value means to the caller:

```swift
/// - Returns: A subscription that manages the supplied subscriptions as one unit.
```

For throwing APIs, document verified failure conditions instead of saying only "An error describing the failure":

```swift
/// - Throws: An encoding error if `message` can't be represented as JSON.
```

Do not invent an exhaustive error list when the implementation does not guarantee one.

## Shared callback behavior

Put behavior shared by a callback family on its protocol or owning type:

```swift
/// A type that receives events from a PubNub subscription.
///
/// The receiver invokes event handlers asynchronously on ``queue``. Assigning
/// a new closure replaces the previous handler for that event type. Set a
/// handler to `nil` to stop receiving that type of event.
public protocol EventListenerInterface: AnyObject {
  /// The queue on which the receiver invokes event handlers.
  var queue: DispatchQueue { get }

  /// A closure the receiver invokes when it receives a message.
  var onMessage: ((PubNubMessage) -> Void)? { get set }

  /// A closure the receiver invokes when it receives a signal.
  var onSignal: ((PubNubMessage) -> Void)? { get set }

  /// A closure the receiver invokes when presence changes.
  var onPresence: ((PubNubPresenceChange) -> Void)? { get set }
}
```

Expand an individual callback only when it has distinct semantics:

```swift
/// A closure the subscription invokes when it receives a file event.
///
/// The event identifies the uploaded file and the channel on which PubNub announced it.
var onFileEvent: ((PubNubFileChangeEvent) -> Void)? { get set }
```

Before promising callback queue, ordering, frequency, lifetime, or retention behavior, trace the implementation and tests.

## Configuration properties

Configuration documentation should cover the effect of enabling the option, relevant conditions, and the disabled behavior when that distinction matters.

Do not determine the public default from the stored-property declaration alone. Inspect all public initializers and decoding paths.

Example:

```swift
/// A Boolean value that determines whether PubNub preserves channel presence state.
///
/// When enabled, PubNub retains the most recent channel state successfully set
/// with ``PubNub/setPresence(state:on:and:custom:completion:)`` and includes it
/// in subsequent subscribe and presence heartbeat operations.
///
/// This setting has an effect only when ``enableEventEngine`` is `true`. When
/// disabled, setting presence state still updates it for that request, but the
/// SDK doesn't preserve the state for subsequent operations.
public var maintainPresenceState: Bool
```

This example includes the Event Engine condition because it changes observable behavior. Removing that condition for brevity would make the documentation incorrect.

## Lifecycle methods

Describe the state transition and what callers can do afterward:

```swift
/// Permanently stops the subscription.
///
/// Disposing the subscription stops event delivery and removes its event
/// handlers and additional listeners. You can't restart a disposed
/// subscription; create a new subscription instead.
public func dispose()
```

Avoid vague statements such as "cleans up resources" when more useful observable consequences are available.

## Related APIs and alternatives

Link to another symbol when it helps callers make a choice:

```swift
/// Stops receiving events without disposing the subscription.
///
/// You can call ``subscribe(with:)`` to start receiving events again. To permanently stop the subscription, call ``dispose()``.
public func unsubscribe()
```

Use DocC symbol links with the least qualification that resolves unambiguously. Verify links against the compiled module when possible.

## Before and after

Weak:

```swift
/// Adds additional subscription listener.
public func addEventListener(_ listener: EventListener)
```

Contract-first:

```swift
/// Adds a listener that receives events from this subscription.
///
/// The subscription delivers events to the listener in addition to invoking
/// its directly assigned event handlers.
///
/// - Parameter listener: The listener to add.
public func addEventListener(_ listener: EventListener)
```

Implementation-focused:

```swift
/// Registers the listener in the internal listeners container.
public func addEventListener(_ listener: EventListener)
```

The internal container is irrelevant to callers and must not appear in public documentation.

## Review checklist

Before finishing, confirm:

- The abstract communicates purpose or effect without the declaration.
- Every behavioral claim is supported by source, tests, or established public documentation.
- Conditions that enable or disable behavior remain explicit.
- Public initializer defaults were inspected where defaults are mentioned.
- `nil`, zero, and empty-value behavior is documented when significant.
- Shared behavior is documented once at the nearest common abstraction.
- Callback-specific comments contain the trigger and delivered value.
- Parameters match the declaration exactly.
- Returns and throws sections describe semantics rather than types.
- Internal mechanisms and unreleased features are absent.
- DocC links resolve or are reported as unverified.
