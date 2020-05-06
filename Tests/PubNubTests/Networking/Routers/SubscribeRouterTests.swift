//
//  SubscribeRouterTests.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

@testable import PubNub
import XCTest

final class SubscribeRouterTests: XCTestCase {
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")
  let testChannel = "TestChannel"

  let testAction = MessageActionEvent(type: "reaction", value: "winky_face", uuid: "SomeUser", channel: "TestChannel",
                                      actionTimetoken: 15_725_459_793_173_220, messageTimetoken: 15_725_459_448_096_144)

  // MARK: - Endpoint Tests

  func testSubscribe_Router() {
    let router = SubscribeRouter(.subscribe(channels: ["TestChannel"], groups: [], timetoken: 0,
                                            region: nil, state: nil, heartbeat: nil, filter: nil),
                                 configuration: config)

    XCTAssertEqual(router.endpoint.description, "Subscribe")
    XCTAssertEqual(router.category, "Subscribe")
    XCTAssertEqual(router.service, .subscribe)
  }

  func testSubscribe_Router_ValidationError() {
    let router = SubscribeRouter(.subscribe(channels: [], groups: [], timetoken: 0,
                                            region: nil, state: nil, heartbeat: nil, filter: nil),
                                 configuration: config)

    XCTAssertNotEqual(router.validationError?.pubNubError, PubNubError(.invalidEndpointType, router: router))
  }
}

// MARK: - Message Response

extension SubscribeRouterTests {
  func testSubscribe_Message() {
    let messageExpect = XCTestExpectation(description: "Message Event")
    let statusExpect = XCTestExpectation(description: "Status Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_message_success",
                                                              "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveMessage = { [weak self] message in
      XCTAssertEqual(message.channel, self?.testChannel)
      XCTAssertEqual(message.messageType, .message)
      XCTAssertEqual(message.payload.stringOptional, "Test Message")

      subscription.unsubscribeAll()

      messageExpect.fulfill()
    }
    listener.didReceiveStatus = { status in
      if let status = try? status.get(), status == .disconnected {
        statusExpect.fulfill()
      }
    }
    subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { listener.cancel() }
    wait(for: [messageExpect, statusExpect], timeout: 1.0)
  }
}

// MARK: - Presence Response

extension SubscribeRouterTests {
  func testSubscribe_Presence() {
    let presenceExpect = XCTestExpectation(description: "Presence Event")
    let statusExpect = XCTestExpectation(description: "Status Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_presence_success",
                                                              "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceivePresence = { [weak self] presence in
      XCTAssertEqual(presence.channel, self?.testChannel)
      XCTAssertEqual(presence.event, .interval)
      XCTAssertEqual(presence.join, ["db9c5e39-7c95-40f5-8d71-125765b6f561"])

      subscription.unsubscribeAll()

      presenceExpect.fulfill()
    }
    listener.didReceiveStatus = { status in
      if let status = try? status.get(), status == .disconnected {
        statusExpect.fulfill()
      }
    }
    subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { listener.cancel() }
    wait(for: [presenceExpect, statusExpect], timeout: 1.0)
  }
}

// MARK: - Signal Response

extension SubscribeRouterTests {
  func testSubscribe_Signal() {
    let signalExpect = XCTestExpectation(description: "Signal Event")
    let statusExpect = XCTestExpectation(description: "Status Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_signal_success",
                                                              "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveSignal = { [weak self] signal in
      XCTAssertEqual(signal.channel, self?.testChannel)
      XCTAssertEqual(signal.messageType, .signal)
      XCTAssertEqual(signal.publisher, "TestUser")
      XCTAssertEqual(signal.payload.stringOptional, "Test Signal")

      subscription.unsubscribeAll()

      signalExpect.fulfill()
    }
    listener.didReceiveStatus = { status in
      if let status = try? status.get(), status == .disconnected {
        statusExpect.fulfill()
      }
    }
    subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { listener.cancel() }
    wait(for: [signalExpect, statusExpect], timeout: 1.0)
  }
}

// MARK: - User Object Response

extension SubscribeRouterTests {
  // swiftlint:disable:next function_body_length
  func testSubscribe_User_Update() {
    let objectExpect = XCTestExpectation(description: "Object Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_userUpdate_success",
                                                              "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let baseUser = UserObject(name: "Not Real Name", id: "TestUserID")

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveSubscription = { event in
      switch event {
      case let .connectionStatusChanged(status):
        if status == .disconnected {
          statusExpect.fulfill()
        }
      case let .userUpdated(patch):
        let updated = try? patch.update(baseUser)

        XCTAssertEqual(updated?.id, "TestUserID")
        XCTAssertEqual(updated?.name, "Test Name")
        XCTAssertNil(updated?.custom)
        XCTAssertEqual(updated?.updated, DateFormatter.iso8601.date(from: "2019-10-06T01:55:50.645685Z"))
        XCTAssertEqual(updated?.eTag, "UserUpdateEtag")

        objectExpect.fulfill()
      case let .subscriptionChanged(change):
        switch change {
        case let .subscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self.testChannel)
        case let .unsubscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self.testChannel)
        }
      default:
        XCTFail("Incorrect Event Received \(event)")
      }
    }
    listener.didReceiveUserEvent = { event in
      switch event {
      case let .updated(user):
        XCTAssertEqual(user.id, "TestUserID")

        subscription.unsubscribeAll()

        objectListenerExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { listener.cancel() }
    wait(for: [objectExpect, statusExpect, objectListenerExpect], timeout: 1.0)
  }

  func testSubscribe_User_Delete() {
    let objectExpect = XCTestExpectation(description: "Object Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_userDelete_success",
                                                              "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveSubscription = { event in
      switch event {
      case let .connectionStatusChanged(status):
        if status == .disconnected {
          statusExpect.fulfill()
        }
      case let .userDeleted(user):
        XCTAssertEqual(user.id, "TestUserID")
        objectExpect.fulfill()
      case let .subscriptionChanged(change):
        switch change {
        case let .subscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self.testChannel)
        case let .unsubscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self.testChannel)
        }
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    listener.didReceiveUserEvent = { event in
      switch event {
      case let .deleted(user):
        XCTAssertEqual(user.id, "TestUserID")

        subscription.unsubscribeAll()

        objectListenerExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { listener.cancel() }
    wait(for: [objectExpect, statusExpect, objectListenerExpect], timeout: 1.0)
  }

  // swiftlint:disable:next function_body_length
  func testSubscribe_Space_Update() {
    let objectExpect = XCTestExpectation(description: "Object Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_spaceUpdate_success",
                                                              "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let baseSpace = SpaceObject(name: "Not Real Name", id: "TestSpaceID")

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveSubscription = { event in
      switch event {
      case let .connectionStatusChanged(status):
        if status == .disconnected {
          statusExpect.fulfill()
        }
      case let .spaceUpdated(patch):
        let updated = try? patch.update(baseSpace)

        XCTAssertEqual(updated?.id, "TestSpaceID")
        XCTAssertEqual(updated?.name, "Test Name")
        XCTAssertEqual(updated?.spaceDescription, nil)
        XCTAssertNil(updated?.custom)
        XCTAssertEqual(updated?.updated, DateFormatter.iso8601.date(from: "2019-10-06T01:55:50.645685Z"))
        XCTAssertEqual(updated?.eTag, "SpaceUpdateEtag")

        objectExpect.fulfill()
      case let .subscriptionChanged(change):
        switch change {
        case let .subscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self.testChannel)
        case let .unsubscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self.testChannel)
        }
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    listener.didReceiveSpaceEvent = { event in
      switch event {
      case let .updated(space):
        XCTAssertEqual(space.id, "TestSpaceID")

        subscription.unsubscribeAll()

        objectListenerExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { listener.cancel() }
    wait(for: [objectExpect, statusExpect, objectListenerExpect], timeout: 1.0)
  }

  func testSubscribe_Space_Delete() {
    let objectExpect = XCTestExpectation(description: "Object Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_spaceDelete_success",
                                                              "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveSubscription = { event in
      switch event {
      case let .connectionStatusChanged(status):
        if status == .disconnected {
          statusExpect.fulfill()
        }
      case let .spaceDeleted(user):
        XCTAssertEqual(user.id, "TestSpaceID")
        objectExpect.fulfill()
      case let .subscriptionChanged(change):
        switch change {
        case let .subscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self.testChannel)
        case let .unsubscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self.testChannel)
        }
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    listener.didReceiveSpaceEvent = { event in
      switch event {
      case let .deleted(space):
        XCTAssertEqual(space.id, "TestSpaceID")

        subscription.unsubscribeAll()

        objectListenerExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { listener.cancel() }
    wait(for: [objectExpect, statusExpect, objectListenerExpect], timeout: 1.0)
  }

  // swiftlint:disable:next function_body_length
  func testSubscribe_Membership_Added() {
    let objectExpect = XCTestExpectation(description: "Object Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_membershipCreate_success",
                                                              "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveSubscription = { [unowned self] event in
      switch event {
      case let .connectionStatusChanged(status):
        if status == .disconnected {
          statusExpect.fulfill()
        }
      case let .membershipAdded(membership):
        XCTAssertEqual(membership.userId, "TestUserID")
        XCTAssertEqual(membership.spaceId, "TestSpaceID")
        XCTAssertEqual(membership.custom?["something"]?.boolOptional, true)
        XCTAssertEqual(membership.updated,
                       DateFormatter.iso8601.date(from: "2019-10-05T23:35:38.457823306Z"))
        XCTAssertEqual(membership.eTag, "TestETag")

        objectExpect.fulfill()

      case let .subscriptionChanged(change):
        switch change {
        case let .subscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self.testChannel)
        case let .unsubscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self.testChannel)
        }
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    listener.didReceiveMembershipEvent = { event in
      switch event {
      case let .userAddedOnSpace(membership):
        XCTAssertEqual(membership.userId, "TestUserID")
        XCTAssertEqual(membership.spaceId, "TestSpaceID")

        subscription.unsubscribeAll()

        objectListenerExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { listener.cancel() }
    wait(for: [objectExpect, statusExpect, objectListenerExpect], timeout: 1.0)
  }

  // swiftlint:disable:next function_body_length
  func testSubscribe_Membership_Update() {
    let objectExpect = XCTestExpectation(description: "Object Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_membershipUpdate_success",
                                                              "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveSubscription = { [weak self] event in
      switch event {
      case let .connectionStatusChanged(status):
        if status == .disconnected {
          statusExpect.fulfill()
        }
      case let .membershipUpdated(membership):
        XCTAssertEqual(membership.userId, "TestUserID")
        XCTAssertEqual(membership.spaceId, "TestSpaceID")
        XCTAssertNil(membership.custom)
        XCTAssertEqual(membership.updated,
                       DateFormatter.iso8601.date(from: "2019-10-05T23:35:38.457823306Z"))
        XCTAssertEqual(membership.eTag, "TestETag")
        objectExpect.fulfill()
      case let .subscriptionChanged(change):
        switch change {
        case let .subscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self?.testChannel)
        case let .unsubscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self?.testChannel)
        }
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    listener.didReceiveMembershipEvent = { event in
      switch event {
      case let .userUpdatedOnSpace(membership):
        XCTAssertEqual(membership.userId, "TestUserID")
        XCTAssertEqual(membership.spaceId, "TestSpaceID")

        subscription.unsubscribeAll()

        objectListenerExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { listener.cancel() }
    wait(for: [objectExpect, statusExpect, objectListenerExpect], timeout: 1.0)
  }

  func testSubscribe_Membership_Delete() {
    let objectExpect = XCTestExpectation(description: "Object Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_membershipDelete_success"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveSubscription = { [weak self] event in
      switch event {
      case let .connectionStatusChanged(status):
        if status == .disconnected {
          statusExpect.fulfill()
        }
      case let .membershipDeleted(membership):
        XCTAssertEqual(membership.userId, "TestUserID")
        XCTAssertEqual(membership.spaceId, "TestSpaceID")
        objectExpect.fulfill()
      case let .subscriptionChanged(change):
        switch change {
        case let .subscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self?.testChannel)
        case let .unsubscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self?.testChannel)
        }
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    listener.didReceiveMembershipEvent = { event in
      switch event {
      case let .userDeletedFromSpace(membership):
        XCTAssertEqual(membership.userId, "TestUserID")
        XCTAssertEqual(membership.spaceId, "TestSpaceID")

        subscription.unsubscribeAll()

        objectListenerExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { listener.cancel() }
    wait(for: [objectExpect, statusExpect, objectListenerExpect], timeout: 1.0)
  }
}

// MARK: - Message Action

extension SubscribeRouterTests {
  func testSubscribe_MessageAction_Added() {
    let actionExpect = XCTestExpectation(description: "Message Action Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let actionListenerExpect = XCTestExpectation(description: "Action Listener Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_addMessageAction_success"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveSubscription = { [weak self] event in
      switch event {
      case let .connectionStatusChanged(status):
        if status == .disconnected {
          statusExpect.fulfill()
        }
      case let .messageActionAdded(action):
        XCTAssertEqual(action, self?.testAction)
        actionExpect.fulfill()
      case let .subscriptionChanged(change):
        switch change {
        case let .subscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self?.testChannel)
        case let .unsubscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self?.testChannel)
        }
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    listener.didReceiveMessageAction = { [weak self] event in
      switch event {
      case let .added(action):
        XCTAssertEqual(action, self?.testAction)

        subscription.unsubscribeAll()

        actionListenerExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { listener.cancel() }
    wait(for: [actionExpect, statusExpect, actionListenerExpect], timeout: 1.0)
  }

  func testSubscribe_MessageAction_Removed() {
    let actionExpect = XCTestExpectation(description: "Message Action Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let actionListenerExpect = XCTestExpectation(description: "Action Listener Event")

    guard let session = try? MockURLSession
      .mockSession(for: ["subscription_removeMessageAction_success"])
      .session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveSubscription = { [weak self] event in
      switch event {
      case let .connectionStatusChanged(status):
        if status == .disconnected {
          statusExpect.fulfill()
        }
      case let .messageActionRemoved(action):
        XCTAssertEqual(action, self?.testAction)
        actionExpect.fulfill()
      case let .subscriptionChanged(change):
        switch change {
        case let .subscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self?.testChannel)
        case let .unsubscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self?.testChannel)
        }
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    listener.didReceiveMessageAction = { [weak self] event in
      switch event {
      case let .removed(action):
        XCTAssertEqual(action, self?.testAction)

        subscription.unsubscribeAll()

        actionListenerExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { listener.cancel() }
    wait(for: [actionExpect, statusExpect, actionListenerExpect], timeout: 1.0)
  }
}

// MARK: - Mixed Response

extension SubscribeRouterTests {
  func testSubscribe_Mixed() {
    let messageExpect = XCTestExpectation(description: "Message Event")
    let presenceExpect = XCTestExpectation(description: "Presence Event")
    let signalExpect = XCTestExpectation(description: "Signal Event")
    let statusExpect = XCTestExpectation(description: "Status Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_mixed_success"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    var payloadCount = 0
    listener.didReceiveSubscription = { _ in
      payloadCount += 1
      if payloadCount == 3 {
        subscription.unsubscribeAll()
      }
    }
    listener.didReceiveMessage = { [weak self] message in
      XCTAssertEqual(message.channel, self?.testChannel)
      XCTAssertEqual(message.messageType, .message)
      XCTAssertEqual(message.payload.stringOptional, "Test Message")
      messageExpect.fulfill()
    }
    listener.didReceivePresence = { [weak self] presence in
      XCTAssertEqual(presence.channel, self?.testChannel)
      XCTAssertEqual(presence.join, ["db9c5e39-7c95-40f5-8d71-125765b6f561"])
      presenceExpect.fulfill()
    }
    listener.didReceiveSignal = { [weak self] signal in
      XCTAssertEqual(signal.channel, self?.testChannel)
      XCTAssertEqual(signal.messageType, .signal)
      XCTAssertEqual(signal.payload.stringOptional, "Test Signal")
      signalExpect.fulfill()
    }
    listener.didReceiveStatus = { status in
      if let status = try? status.get(), status == .disconnected {
        statusExpect.fulfill()
      }
    }
    subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { listener.cancel() }
    wait(for: [signalExpect, statusExpect], timeout: 1.0)
  }
}

// MARK: - Unsubscribe

extension SubscribeRouterTests {
  func testUnsubscribe() {
    let statusExpect = XCTestExpectation(description: "Status Event")
    statusExpect.expectedFulfillmentCount = 2

    guard let session = try? MockURLSession.mockSession(for: ["subscription_mixed_success", "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveSubscription = { [unowned self] event in
      switch event {
      case let .subscriptionChanged(change):
        switch change {
        case let .subscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self.testChannel)
        case let .unsubscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self.testChannel)
        }
      case let .connectionStatusChanged(status):
        switch status {
        case .connected:
          subscription.unsubscribe(from: [self.testChannel])
          XCTAssertEqual(subscription.subscribedChannels, [])

          statusExpect.fulfill()
        case .disconnected:
          statusExpect.fulfill()
        default:
          break
        }
      default:
        break
      }
    }
    subscription.add(listener)

    subscription.subscribe(to: [testChannel])
    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { listener.cancel() }
    wait(for: [statusExpect], timeout: 1.0)
  }

  func testUnsubscribeAll() {
    let statusExpect = XCTestExpectation(description: "Status Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_mixed_success", "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let otherChannel = "OtherChannel"

    let listener = SubscriptionListener()
    listener.didReceiveSubscription = { [weak self] event in
      switch event {
      case let .subscriptionChanged(change):
        switch change {
        case let .subscribed(channels, _):
          XCTAssertTrue(channels.contains(where: { $0.id == self?.testChannel }))
          XCTAssertTrue(channels.contains(where: { $0.id == otherChannel }))
        case let .unsubscribed(channels, _):
          XCTAssertTrue(channels.contains(where: { $0.id == self?.testChannel }))
          XCTAssertTrue(channels.contains(where: { $0.id == otherChannel }))
        }
      case let .connectionStatusChanged(status):
        switch status {
        case .connected:
          subscription.unsubscribeAll()
          XCTAssertEqual(subscription.subscribedChannels, [])

          statusExpect.fulfill()
        case .disconnected:
          statusExpect.fulfill()
        default:
          break
        }
      default:
        break
      }
    }
    subscription.add(listener)

    subscription.subscribe(to: [testChannel, otherChannel])
    XCTAssertTrue(subscription.subscribedChannels.contains(testChannel))
    XCTAssertTrue(subscription.subscribedChannels.contains(otherChannel))

    subscription.unsubscribeAll()
    XCTAssertEqual(subscription.subscribedChannels, [])

    defer { listener.cancel() }
    wait(for: [statusExpect], timeout: 1.0)
  }

  // swiftlint:disable:next file_length
}
