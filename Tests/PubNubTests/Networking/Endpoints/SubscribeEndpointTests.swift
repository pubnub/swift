//
//  SubscribeEndpointTests.swift
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

// swiftlint:disable:next type_body_length
final class SubscribeEndpointTests: XCTestCase {
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")
  let testChannel = "TestChannel"

  // MARK: - Endpoint Tests

  func testSubscribe_Endpoint() {
    let endpoint = Endpoint.subscribe(channels: ["TestChannel"],
                                      groups: [],
                                      timetoken: 0,
                                      region: nil,
                                      state: nil,
                                      heartbeat: nil,
                                      filter: nil)

    XCTAssertEqual(endpoint.description, "Subscribe")
    XCTAssertEqual(endpoint.rawValue, .subscribe)
    XCTAssertEqual(endpoint.operationCategory, .subscribe)
    XCTAssertNil(endpoint.validationError)
  }

  func testSubscribe_Endpoint_ValidationError() {
    let endpoint = Endpoint.subscribe(channels: [],
                                      groups: [],
                                      timetoken: 0,
                                      region: nil,
                                      state: nil,
                                      heartbeat: nil,
                                      filter: nil)

    XCTAssertNotEqual(endpoint.validationError?.pubNubError, PNError.invalidEndpointType(endpoint))
  }

  func testSubscribe_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.subscribe(channels: ["SomeChannel"],
                                      groups: ["SomeGroup"],
                                      timetoken: 0,
                                      region: "1",
                                      state: ["Channel": [:]],
                                      heartbeat: 2,
                                      filter: "Filter")

    XCTAssertEqual(endpoint.associatedValue["channels"] as? [String], ["SomeChannel"])
    XCTAssertEqual(endpoint.associatedValue["groups"] as? [String], ["SomeGroup"])
    XCTAssertEqual(endpoint.associatedValue["timetoken"] as? Timetoken, 0)
    XCTAssertEqual(endpoint.associatedValue["region"] as? String, "1")
    XCTAssertNotNil(endpoint.associatedValue["state"] as? ChannelPresenceState)
    XCTAssertEqual(endpoint.associatedValue["heartbeat"] as? Int, 2)
    XCTAssertEqual(endpoint.associatedValue["filter"] as? String, "Filter")
  }

  // MARK: - Message Response

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
      messageExpect.fulfill()
    }
    listener.didReceiveStatus = { status in
      if let status = try? status.get(), status == .cancelled {
        statusExpect.fulfill()
      }
    }
    let token = subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { token.cancel() }
    wait(for: [messageExpect, statusExpect], timeout: 1.0)
  }

  // MARK: - Presence Response

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
      presenceExpect.fulfill()
    }
    listener.didReceiveStatus = { status in
      if let status = try? status.get(), status == .cancelled {
        statusExpect.fulfill()
      }
    }
    let token = subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { token.cancel() }
    wait(for: [presenceExpect, statusExpect], timeout: 1.0)
  }

  func testSubscribe_Presence_Failure() {}

  // MARK: - Signal Response

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
      signalExpect.fulfill()
    }
    listener.didReceiveStatus = { status in
      if let status = try? status.get(), status == .cancelled {
        statusExpect.fulfill()
      }
    }
    let token = subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { token.cancel() }
    wait(for: [signalExpect, statusExpect], timeout: 1.0)
  }

  // MARK: - User Object Response

  func testSubscribe_User_Update() {
    let objectExpect = XCTestExpectation(description: "Object Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_userUpdate_success",
                                                              "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveSubscription = { event in
      switch event {
      case let .connectionStatusChanged(status):
        if status == .cancelled {
          statusExpect.fulfill()
        }
      case let .userUpdated(user):
        XCTAssertEqual(user.id, "TestUserID")
        XCTAssertEqual(user.name, "Test Name")
        XCTAssertEqual(user.externalId, nil)
        XCTAssertEqual(user.profileURL, nil)
        XCTAssertEqual(user.email, nil)
        XCTAssertEqual(user.custom.isEmpty, true)
        XCTAssertEqual(user.updated, Constant.iso8601DateFormatter.date(from: "2019-10-06T01:55:50.645685Z"))
        XCTAssertEqual(user.eTag, "UserUpdateEtag")

        objectExpect.fulfill()
      default:
        print(event)
      }
    }
    listener.didReceiveUserEvent = { event in
      switch event {
      case let .updated(user):
        XCTAssertEqual(user.id, "TestUserID")
        objectListenerExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    let token = subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { token.cancel() }
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
        if status == .cancelled {
          statusExpect.fulfill()
        }
      case let .userDeleted(user):
        XCTAssertEqual(user.id, "TestUserID")
        objectExpect.fulfill()
      default:
        print(event)
      }
    }
    listener.didReceiveUserEvent = { event in
      switch event {
      case let .deleted(user):
        XCTAssertEqual(user.id, "TestUserID")
        objectListenerExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    let token = subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { token.cancel() }
    wait(for: [objectExpect, statusExpect, objectListenerExpect], timeout: 1.0)
  }

  func testSubscribe_Space_Update() {
    let objectExpect = XCTestExpectation(description: "Object Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_spaceUpdate_success",
                                                              "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveSubscription = { event in
      switch event {
      case let .connectionStatusChanged(status):
        if status == .cancelled {
          statusExpect.fulfill()
        }
      case let .spaceUpdated(space):
        XCTAssertEqual(space.id, "TestSpaceID")
        XCTAssertEqual(space.name, "Test Name")
        XCTAssertEqual(space.spaceDescription, nil)
        XCTAssertEqual(space.custom.isEmpty, true)
        XCTAssertEqual(space.updated, Constant.iso8601DateFormatter.date(from: "2019-10-06T01:55:50.645685Z"))
        XCTAssertEqual(space.eTag, "SpaceUpdateEtag")

        objectExpect.fulfill()
      default:
        print(event)
      }
    }
    listener.didReceiveSpaceEvent = { event in
      switch event {
      case let .updated(space):
        XCTAssertEqual(space.id, "TestSpaceID")
        objectListenerExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    let token = subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { token.cancel() }
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
        if status == .cancelled {
          statusExpect.fulfill()
        }
      case let .spaceDeleted(user):
        XCTAssertEqual(user.id, "TestSpaceID")
        objectExpect.fulfill()
      default:
        print(event)
      }
    }
    listener.didReceiveSpaceEvent = { event in
      switch event {
      case let .deleted(space):
        XCTAssertEqual(space.id, "TestSpaceID")
        objectListenerExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    let token = subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { token.cancel() }
    wait(for: [objectExpect, statusExpect, objectListenerExpect], timeout: 1.0)
  }

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
    listener.didReceiveSubscription = { event in
      switch event {
      case let .connectionStatusChanged(status):
        if status == .cancelled {
          statusExpect.fulfill()
        }
      case let .membershipAdded(membership):
        XCTAssertEqual(membership.userId, "TestUserID")
        XCTAssertEqual(membership.spaceId, "TestSpaceID")
        XCTAssertEqual(membership.custom["something"]?.boolValue, true)
        XCTAssertEqual(membership.updated, Constant.iso8601DateFormatter.date(from: "2019-10-05T23:35:38.457823306Z"))
        XCTAssertEqual(membership.eTag, "TestETag")

        objectExpect.fulfill()
      default:
        print(event)
      }
    }
    listener.didReceiveMembershipEvent = { event in
      switch event {
      case let .userAddedOnSpace(membership):
        XCTAssertEqual(membership.userId, "TestUserID")
        XCTAssertEqual(membership.spaceId, "TestSpaceID")
        objectListenerExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    let token = subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { token.cancel() }
    wait(for: [objectExpect, statusExpect, objectListenerExpect], timeout: 1.0)
  }

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
    listener.didReceiveSubscription = { event in
      switch event {
      case let .connectionStatusChanged(status):
        if status == .cancelled {
          statusExpect.fulfill()
        }
      case let .membershipUpdated(membership):
        XCTAssertEqual(membership.userId, "TestUserID")
        XCTAssertEqual(membership.spaceId, "TestSpaceID")
        XCTAssertEqual(membership.custom.isEmpty, true)
        XCTAssertEqual(membership.updated, Constant.iso8601DateFormatter.date(from: "2019-10-05T23:35:38.457823306Z"))
        XCTAssertEqual(membership.eTag, "TestETag")
        objectExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    listener.didReceiveMembershipEvent = { event in
      switch event {
      case let .userUpdatedOnSpace(membership):
        XCTAssertEqual(membership.userId, "TestUserID")
        XCTAssertEqual(membership.spaceId, "TestSpaceID")
        objectListenerExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    let token = subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { token.cancel() }
    wait(for: [objectExpect, statusExpect, objectListenerExpect], timeout: 1.0)
  }

  func testSubscribe_Membership_Delete() {
    let objectExpect = XCTestExpectation(description: "Object Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_membershipDelete_success",
                                                              "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveSubscription = { event in
      switch event {
      case let .connectionStatusChanged(status):
        if status == .cancelled {
          statusExpect.fulfill()
        }
      case let .membershipDeleted(membership):
        XCTAssertEqual(membership.userId, "TestUserID")
        XCTAssertEqual(membership.spaceId, "TestSpaceID")
        objectExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    listener.didReceiveMembershipEvent = { event in
      switch event {
      case let .userDeletedFromSpace(membership):
        XCTAssertEqual(membership.userId, "TestUserID")
        XCTAssertEqual(membership.spaceId, "TestSpaceID")
        objectListenerExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    let token = subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { token.cancel() }
    wait(for: [objectExpect, statusExpect, objectListenerExpect], timeout: 1.0)
  }

  // MARK: - Mixed Response

  func testSubscribe_Mixed() {
    let messageExpect = XCTestExpectation(description: "Message Event")
    let presenceExpect = XCTestExpectation(description: "Presence Event")
    let signalExpect = XCTestExpectation(description: "Signal Event")
    let statusExpect = XCTestExpectation(description: "Status Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_mixed_success", "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
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
      if let status = try? status.get(), status == .cancelled {
        statusExpect.fulfill()
      }
    }
    let token = subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { token.cancel() }
    wait(for: [signalExpect, statusExpect], timeout: 1.0)
  }

  // MARK: - Unsubscribe

  func testUnsubscribe() {
    let statusExpect = XCTestExpectation(description: "Status Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_mixed_success", "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveStatus = { status in
      if let status = try? status.get(), status == .connected {
        statusExpect.fulfill()
      }
    }
    let token = subscription.add(listener)

    subscription.subscribe(to: [testChannel])
    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    subscription.unsubscribe(from: [testChannel])
    XCTAssertEqual(subscription.subscribedChannels, [])

    defer { token.cancel() }
    wait(for: [statusExpect], timeout: 1.0)
  }

  func testUnsubscribeAll() {
    let statusExpect = XCTestExpectation(description: "Status Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_mixed_success", "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveStatus = { status in
      if let status = try? status.get(), status == .connected {
        statusExpect.fulfill()
      }
    }
    let token = subscription.add(listener)

    subscription.subscribe(to: [testChannel, "OtherChannel"])
    let diff = subscription.subscribedChannels
      .symmetricDifference([testChannel, "OtherChannel"])
    XCTAssertTrue(diff.isEmpty)

    subscription.unsubscribeAll()
    XCTAssertEqual(subscription.subscribedChannels, [])

    defer { token.cancel() }
    wait(for: [statusExpect], timeout: 1.0)
  }

  // swiftlint:disable:next file_length
}
