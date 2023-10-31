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

class SubscribeRouterTests: XCTestCase {
  var config: PubNubConfiguration!
  var eventEngineEnabledConfig: PubNubConfiguration!
  
  let testChannel = "TestChannel"
  let testAction = PubNubMessageActionBase(
    actionType: "reaction", actionValue: "winky_face",
    actionTimetoken: 15_725_459_793_173_220, messageTimetoken: 15_725_459_448_096_144,
    publisher: "SomeUser", channel: "TestChannel", published: 15_725_459_794_105_070
  )
  
  // MARK: - Set Up
  
  override func setUp() {
    super.setUp()
    
    config = PubNubConfiguration(
      publishKey: "FakeTestString",
      subscribeKey: "FakeTestString",
      userId: UUID().uuidString,
      enableEventEngine: false
    )
    eventEngineEnabledConfig = PubNubConfiguration(
      publishKey: "FakeTestString",
      subscribeKey: "FakeTestString",
      userId: UUID().uuidString,
      enableEventEngine: true
    )
  }
  
  override func tearDown() {
    config = nil
    eventEngineEnabledConfig = nil
    
    super.tearDown()
  }
}

// MARK: - Endpoint Tests

extension SubscribeRouterTests {
  func testSubscribe_Router() {
    testSubscribe_Router(config: config)
    testSubscribe_Router(config: eventEngineEnabledConfig)
  }
  
  func testSubscribe_Router_ValidationError() {
    testSubscribe_Router_ValidationError(config: config)
    testSubscribe_Router_ValidationError(config: eventEngineEnabledConfig)
  }
}

// MARK: - Message Response

extension SubscribeRouterTests {
  func testSubscribe_Message() {
    testSubscribe_Message(config: config)
    testSubscribe_Message(config: eventEngineEnabledConfig)
  }
}

// MARK: - Presence Response

extension SubscribeRouterTests {
  func testSubscribe_Presence() {
    testSubscribe_Presence(config: config)
    testSubscribe_Presence(config: eventEngineEnabledConfig)
  }
}

// MARK: - Signal Response

extension SubscribeRouterTests {
  func testSubscribe_Signal() {
    testSubscribe_Signal(config: config)
    testSubscribe_Signal(config: eventEngineEnabledConfig)
  }
}

// MARK: - User Object Response

extension SubscribeRouterTests {
  func testSubscribe_UUIDMetadata_Set() {
    testSubscribe_UUIDMetadata_Set(config: config)
    testSubscribe_UUIDMetadata_Set(config: eventEngineEnabledConfig)
  }
  
  func testSubscribe_UUIDMetadata_Removed() {
    testSubscribe_UUIDMetadata_Removed(config: config)
    testSubscribe_UUIDMetadata_Removed(config: eventEngineEnabledConfig)
  }
  
  func testSubscribe_ChannelMetadata_Set() {
    testSubscribe_ChannelMetadata_Set(config: config)
    testSubscribe_ChannelMetadata_Set(config: eventEngineEnabledConfig)
  }
  
  func testSubscribe_ChannelMetadata_Removed() {
    testSubscribe_ChannelMetadata_Removed(config: config)
    testSubscribe_ChannelMetadata_Removed(config: eventEngineEnabledConfig)
  }
  
  func testSubscribe_Membership_Set() {
    testSubscribe_Membership_Set(config: config)
    testSubscribe_Membership_Set(config: eventEngineEnabledConfig)
  }
  
  func testSubscribe_Membership_Removed() {
    testSubscribe_Membership_Removed(config: config)
    testSubscribe_Membership_Removed(config: eventEngineEnabledConfig)
  }
}

// MARK: - Message Action

extension SubscribeRouterTests {
  func testSubscribe_MessageAction_Added() {
    testSubscribe_MessageAction_Added(config: config)
    testSubscribe_MessageAction_Added(config: eventEngineEnabledConfig)
  }
  
  func testSubscribe_MessageAction_Removed() {
    testSubscribe_MessageAction_Removed(config: config)
    testSubscribe_MessageAction_Removed(config: eventEngineEnabledConfig)
  }
}

// MARK: - Mixed Response

extension SubscribeRouterTests {
  func testSubscribe_Mixed() {
    testSubscribe_Mixed(config: config)
    testSubscribe_Mixed(config: eventEngineEnabledConfig)
  }
}

// MARK: - Error Handling

extension SubscribeRouterTests {
  func testInvalidJSONResponse() {
    testInvalidJSONResponse(config: config)
    testInvalidJSONResponse(config: eventEngineEnabledConfig)
  }
}

// MARK: - Unsubscribe

extension SubscribeRouterTests {
  func testUnsubscribe() {
    testUnsubscribe(config: config)
    testUnsubscribe(config: eventEngineEnabledConfig)
  }
  
  func testUnsubscribeAll() {
    testUnsubscribeAll(config: config)
    testUnsubscribeAll(config: eventEngineEnabledConfig)
  }
}

// MARK: - Endpoint Tests (Implementation)

extension SubscribeRouterTests {
  func testSubscribe_Router(config: PubNubConfiguration) {
    let router = SubscribeRouter(.subscribe(
      channels: ["TestChannel"], groups: [], timetoken: 0,
      region: nil, heartbeat: nil, filter: nil, eventEngineEnabled: config.enableEventEngine
    ), configuration: config)
    
    XCTAssertEqual(router.endpoint.description, "Subscribe")
    XCTAssertEqual(router.category, "Subscribe")
    XCTAssertEqual(router.service, .subscribe)
  }
  
  func testSubscribe_Router_ValidationError(config: PubNubConfiguration) {
    let router = SubscribeRouter(.subscribe(
      channels: [], groups: [], timetoken: 0,
      region: nil, heartbeat: nil, filter: nil, eventEngineEnabled: config.enableEventEngine
    ), configuration: config)
    
    XCTAssertNotEqual(
      router.validationError?.pubNubError,
      PubNubError(.invalidEndpointType, router: router)
    )
  }
}

// MARK: - Message Response (Implementation)

extension SubscribeRouterTests {
  func testSubscribe_Message(config: PubNubConfiguration) {
    let messageExpect = XCTestExpectation(description: "Message Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    
    guard let session = try? MockURLSession.mockSession(
      for: ["subscription_handshake_success", "subscription_message_success", "cancelled"]
    ).session else {
      return XCTFail("Could not create mock url session")
    }
    
    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)
    let listener = SubscriptionListener()
    
    listener.didReceiveMessage = { [weak self] message in
      XCTAssertEqual(message.channel, self?.testChannel)
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

// MARK: - Presence Response (Implementation)

extension SubscribeRouterTests {
  func testSubscribe_Presence(config: PubNubConfiguration) {
    let presenceExpect = XCTestExpectation(description: "Presence Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    
    guard let session = try? MockURLSession.mockSession(
      for: ["subscription_handshake_success", "subscription_presence_success","cancelled"]
    ).session else {
      return XCTFail("Could not create mock url session")
    }
    
    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)
    let listener = SubscriptionListener()
    
    listener.didReceivePresence = { [weak self] presence in
      XCTAssertEqual(presence.channel, self?.testChannel)
      XCTAssertEqual(presence.actions, [
        .join(uuids: ["db9c5e39-7c95-40f5-8d71-125765b6f561", "vqwqvae39-7c95-40f5-8d71-25234165142"]),
        .leave(uuids: ["234vq2343-7c95-40f5-8d71-125765b6f561", "42vvsge39-7c95-40f5-8d71-25234165142"])
      ])
      
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
 
// MARK: - Signal Response (Implementation)

extension SubscribeRouterTests {
  func testSubscribe_Signal(config: PubNubConfiguration) {
    let signalExpect = XCTestExpectation(description: "Signal Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    
    guard let session = try? MockURLSession.mockSession(
      for: ["subscription_handshake_success", "subscription_signal_success", "cancelled"]
    ).session else {
      return XCTFail("Could not create mock url session")
    }
    
    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)
    let listener = SubscriptionListener()
    
    listener.didReceiveSignal = { [weak self] signal in
      XCTAssertEqual(signal.channel, self?.testChannel)
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
  
// MARK: - User Object Response (Implementation)

extension SubscribeRouterTests {
  // swiftlint:disable:next function_body_length cyclomatic_complexity
  func testSubscribe_UUIDMetadata_Set(config: PubNubConfiguration) {
    let objectExpect = XCTestExpectation(description: "Object Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")
    
    guard let session = try? MockURLSession.mockSession(
      for: ["subscription_handshake_success", "subscription_uuidSet_success", "cancelled"]
    ).session else {
      return XCTFail("Could not create mock url session")
    }
    
    let baseUser = PubNubUUIDMetadataBase(metadataId: "TestUserID", name: "Not Real Name")
    let patchedObjectUser = PubNubUUIDMetadataBase(
      metadataId: "TestUserID",
      name: "Test Name", type: "Test Type", status: "Test Status",
      updated: DateFormatter.iso8601.date(from: "2019-10-06T01:55:50.645685Z"),
      eTag: "UserUpdateEtag"
    )
    
    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)
    let listener = SubscriptionListener()
    
    listener.didReceiveSubscription = { event in
      switch event {
      case let .connectionStatusChanged(status):
        if status == .disconnected {
          statusExpect.fulfill()
        }
      case let .uuidMetadataSet(changeset):
        XCTAssertEqual(
          try? changeset.apply(to: baseUser).transcode(),
          patchedObjectUser
        )
        objectExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received \(event)")
      }
    }
    
    listener.didReceiveObjectMetadataEvent = { event in
      switch event {
      case let .setUUID(changeset):
        XCTAssertEqual(changeset.metadataId, "TestUserID")
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
  
  // swiftlint:disable:next cyclomatic_complexity
  func testSubscribe_UUIDMetadata_Removed(config: PubNubConfiguration) {
    let objectExpect = XCTestExpectation(description: "Object Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")
    
    guard let session = try? MockURLSession.mockSession(
      for: ["subscription_handshake_success", "subscription_uuidRemove_success", "cancelled"]
    ).session else {
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
      case let .uuidMetadataRemoved(metadataId):
        XCTAssertEqual(metadataId, "TestUserID")
        objectExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    
    listener.didReceiveObjectMetadataEvent = { event in
      switch event {
      case let .removedUUID(metadataId):
        XCTAssertEqual(metadataId, "TestUserID")
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
  func testSubscribe_ChannelMetadata_Set(config: PubNubConfiguration) {
    let objectExpect = XCTestExpectation(description: "Object Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")
    
    guard let session = try? MockURLSession.mockSession(
      for: ["subscription_handshake_success", "subscription_channelSet_success", "cancelled"]
    ).session else {
      return XCTFail("Could not create mock url session")
    }
    
    let baseChannel = PubNubChannelMetadataBase(
      metadataId: "TestSpaceID", name: "Not Real Name", type: "someType"
    )
    let patchedChannel = PubNubChannelMetadataBase(
      metadataId: "TestSpaceID",
      name: "Test Name",
      type: "Test Type", status: "Test Status",
      updated: DateFormatter.iso8601.date(from: "2019-10-06T01:55:50.645685Z"),
      eTag: "SpaceUpdateEtag"
    )
    
    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)
    let listener = SubscriptionListener()
    
    listener.didReceiveSubscription = { event in
      switch event {
      case let .connectionStatusChanged(status):
        if status == .disconnected {
          statusExpect.fulfill()
        }
      case let .channelMetadataSet(changeset):
        print("Channel Changeset \(changeset)")
        XCTAssertEqual(
          try? changeset.apply(to: baseChannel).transcode(), patchedChannel
        )
        objectExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    
    listener.didReceiveObjectMetadataEvent = { event in
      switch event {
      case let .setChannel(changeset):
        XCTAssertEqual(changeset.metadataId, "TestSpaceID")
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
  
  // swiftlint:disable:next cyclomatic_complexity
  func testSubscribe_ChannelMetadata_Removed(config: PubNubConfiguration) {
    let objectExpect = XCTestExpectation(description: "Object Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")
    
    guard let session = try? MockURLSession.mockSession(
      for: ["subscription_handshake_success", "subscription_channelRemove_success", "cancelled"]
    ).session else {
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
      case let .channelMetadataRemoved(metadataId):
        XCTAssertEqual(metadataId, "TestSpaceID")
        objectExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    
    listener.didReceiveObjectMetadataEvent = { event in
      switch event {
      case let .removedChannel(metadataId: metadataId):
        XCTAssertEqual(metadataId, "TestSpaceID")
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
  
  // swiftlint:disable:next function_body_length cyclomatic_complexity
  func testSubscribe_Membership_Set(config: PubNubConfiguration) {
    let objectExpect = XCTestExpectation(description: "Object Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")
    
    guard let session = try? MockURLSession.mockSession(
      for: ["subscription_handshake_success", "subscription_membershipSet_success", "cancelled"]
    ).session else {
      return XCTFail("Could not create mock url session")
    }
    
    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)
    let channel = PubNubChannelMetadataBase(metadataId: "TestSpaceID")
    let uuid = PubNubUUIDMetadataBase(metadataId: "TestUserID")
    let testMembership = PubNubMembershipMetadataBase(
      uuidMetadataId: "TestUserID", channelMetadataId: "TestSpaceID", uuid: uuid, channel: channel, custom: ["something": true],
      updated: DateFormatter.iso8601.date(from: "2019-10-05T23:35:38.457823306Z"), eTag: "TestETag"
    )
    
    let listener = SubscriptionListener()
    
    listener.didReceiveSubscription = { event in
      switch event {
      case let .connectionStatusChanged(status):
        if status == .disconnected {
          statusExpect.fulfill()
        }
      case let .membershipMetadataSet(membership):
        XCTAssertEqual(try? membership.transcode(), testMembership)
        objectExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received \(event)")
      }
    }
    
    listener.didReceiveObjectMetadataEvent = { event in
      switch event {
      case let .setMembership(membership):
        XCTAssertEqual(try? membership.transcode(), testMembership)
        subscription.unsubscribeAll()
        objectListenerExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received \(event)")
      }
    }
    subscription.add(listener)
    subscription.subscribe(to: [testChannel])
    
    XCTAssertEqual(subscription.subscribedChannels, [testChannel])
    
    defer { listener.cancel() }
    wait(for: [objectExpect, statusExpect, objectListenerExpect], timeout: 1.0)
  }
  
  // swiftlint:disable:next function_body_length cyclomatic_complexity
  func testSubscribe_Membership_Removed(config: PubNubConfiguration) {
    let objectExpect = XCTestExpectation(description: "Object Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")
    
    guard let session = try? MockURLSession.mockSession(
      for: ["subscription_handshake_success", "subscription_membershipRemove_success", "cancelled"]
    ).session else {
      return XCTFail("Could not create mock url session")
    }
    
    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)
    let channel = PubNubChannelMetadataBase(metadataId: "TestSpaceID")
    let uuid = PubNubUUIDMetadataBase(metadataId: "TestUserID")
    let testMembership = PubNubMembershipMetadataBase(
      uuidMetadataId: "TestUserID", channelMetadataId: "TestSpaceID", uuid: uuid, channel: channel,
      updated: DateFormatter.iso8601.date(from: "2019-10-05T23:35:38.457823306Z"), eTag: "TestETag"
    )
    
    let listener = SubscriptionListener()
    
    listener.didReceiveSubscription = { event in
      switch event {
      case let .connectionStatusChanged(status):
        if status == .disconnected {
          statusExpect.fulfill()
        }
      case let .membershipMetadataRemoved(membership):
        XCTAssertEqual(try? membership.transcode(), testMembership)
        objectExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received \(event)")
      }
    }
    
    listener.didReceiveObjectMetadataEvent = { event in
      switch event {
      case let .removedMembership(membership):
        XCTAssertEqual(try? membership.transcode(), testMembership)
        subscription.unsubscribeAll()
        objectListenerExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received \(event)")
      }
    }
    subscription.add(listener)
    subscription.subscribe(to: [testChannel])
    
    XCTAssertEqual(subscription.subscribedChannels, [testChannel])
    
    defer { listener.cancel() }
    wait(for: [objectExpect, statusExpect, objectListenerExpect], timeout: 1.0)
  }
}
 
// MARK: - Message Action (Implementation)

extension SubscribeRouterTests {
  // swiftlint:disable:next cyclomatic_complexity
  func testSubscribe_MessageAction_Added(config: PubNubConfiguration) {
    let actionExpect = XCTestExpectation(description: "Message Action Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let actionListenerExpect = XCTestExpectation(description: "Action Listener Event")
    
    guard let session = try? MockURLSession.mockSession(
      for: ["subscription_handshake_success", "subscription_addMessageAction_success", "cancelled"]
    ).session else {
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
        XCTAssertEqual(try? action.transcode(), self?.testAction)
        actionExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received \(event)")
      }
    }
    
    listener.didReceiveMessageAction = { [weak self] event in
      switch event {
      case let .added(action):
        XCTAssertEqual(try? action.transcode(), self?.testAction)
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
  
  // swiftlint:disable:next cyclomatic_complexity function_body_length
  func testSubscribe_MessageAction_Removed(config: PubNubConfiguration) {
    let actionExpect = XCTestExpectation(description: "Message Action Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let actionListenerExpect = XCTestExpectation(description: "Action Listener Event")
    
    guard let session = try? MockURLSession.mockSession(
      for: ["subscription_handshake_success", "subscription_removeMessageAction_success", "cancelled"]
    ).session else {
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
        XCTAssertEqual(try? action.transcode(), self?.testAction)
        actionExpect.fulfill()
      default:
        XCTFail("Incorrect Event Received")
      }
    }
    listener.didReceiveMessageAction = { [weak self] event in
      switch event {
      case let .removed(action):
        XCTAssertEqual(try? action.transcode(), self?.testAction)
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

// MARK: - Mixed Response (Implementation)
  
extension SubscribeRouterTests {
  func testSubscribe_Mixed(config: PubNubConfiguration) {
    let messageExpect = XCTestExpectation(description: "Message Event")
    let presenceExpect = XCTestExpectation(description: "Presence Event")
    let signalExpect = XCTestExpectation(description: "Signal Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    
    guard let session = try? MockURLSession.mockSession(
      for: ["subscription_handshake_success", "subscription_mixed_success", "cancelled"]
    ).session else {
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
      XCTAssertEqual(message.payload.stringOptional, "Test Message")
      messageExpect.fulfill()
    }
    listener.didReceivePresence = { [weak self] presence in
      XCTAssertEqual(presence.channel, self?.testChannel)
      XCTAssertEqual(presence.actions, [.join(uuids: ["db9c5e39-7c95-40f5-8d71-125765b6f561"])])
      presenceExpect.fulfill()
    }
    listener.didReceiveSignal = { [weak self] signal in
      XCTAssertEqual(signal.channel, self?.testChannel)
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
  
// MARK: - Error Handling (Implementation)

extension SubscribeRouterTests {
  func testInvalidJSONResponse(config: PubNubConfiguration) {
    // swiftlint:disable:next line_length
    let corruptBase64Response = "eyJ0Ijp7InQiOiIxNTkxMjE4MzQ0MTUyNjM1MCIsInIiOjF9LCJtIjpbeyJhIjoiMyIsImYiOjUxMiwicCI6eyJ0IjoiMTU5MTIxODM0NDE1NTQyMDAiLCJyIjoxfSwiayI6ImRlbW8tMzYiLCJjIjoic3dpZnRJbnZhbGlkSlNPTi7/IiwiZCI6ImhlbGxvIiwiYiI6InN3aWZ0SW52YWxpZEpTT04uKiJ9XX0="
    
    guard let corruptedData = Data(base64Encoded: corruptBase64Response) else {
      return XCTFail("Could not create Data from String")
    }
    
    let errorExpect = XCTestExpectation(description: "Error Event")
    
    guard let session = try? MockURLSession.mockSession(
      for: ["cancelled"],
      raw: [corruptedData]
    ).session else {
      return XCTFail("Could not create mock url session")
    }
    
    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)
    let listener = SubscriptionListener()
    
    listener.didReceiveSubscription = { event in
      if case let .subscribeError(error) = event {
        XCTAssertEqual(error.reason, .jsonDataDecodingFailure)
        subscription.unsubscribeAll()
        errorExpect.fulfill()
      }
    }
    subscription.add(listener)
    subscription.subscribe(to: [testChannel])
    
    XCTAssertEqual(subscription.subscribedChannels, [testChannel])
    
    defer { listener.cancel() }
    wait(for: [errorExpect], timeout: 1.0)
  }
}
  
// MARK: - Unsubscribe (Implementation)

extension SubscribeRouterTests {
  func testUnsubscribe(config: PubNubConfiguration) {
    let statusExpect = XCTestExpectation(description: "Status Event")
    statusExpect.expectedFulfillmentCount = 2
    
    guard let session = try? MockURLSession.mockSession(
      for: ["subscription_handshake_success", "subscription_mixed_success", "cancelled"]
    ).session else {
      return XCTFail("Could not create mock url session")
    }
    
    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)
    let listener = SubscriptionListener()
    
    listener.didReceiveSubscription = { [unowned self] event in
      switch event {
      case let .connectionStatusChanged(status):
        switch status {
        case .connected:
          subscription.unsubscribe(from: [self.testChannel])
          XCTAssertEqual(subscription.subscribedChannels, [])
          
          statusExpect.fulfill()
        case .connectionError:
          statusExpect.fulfill()
        case .disconnected:
          statusExpect.fulfill()
        case .disconnectedUnexpectedly:
          statusExpect.fulfill()
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
  
  func testUnsubscribeAll(config: PubNubConfiguration) {
    let statusExpect = XCTestExpectation(description: "Status Event")
    
    guard let session = try? MockURLSession.mockSession(
      for: ["subscription_handshake_success", "subscription_mixed_success", "cancelled"]
    ).session else {
      return XCTFail("Could not create mock url session")
    }
    
    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)
    let otherChannel = "OtherChannel"
    let listener = SubscriptionListener()
    
    listener.didReceiveSubscription = { event in
      switch event {
      case let .connectionStatusChanged(status):
        switch status {
        case .connected:
          subscription.unsubscribeAll()
          XCTAssertEqual(subscription.subscribedChannels, [])
          statusExpect.fulfill()
        case .connectionError:
          statusExpect.fulfill()
        case .disconnected:
          statusExpect.fulfill()
        case .disconnectedUnexpectedly:
          statusExpect.fulfill()
        }
      default:
        break
      }
    }
    subscription.add(listener)
    subscription.subscribe(to: [testChannel, otherChannel])
    
    XCTAssertTrue(subscription.subscribedChannels.contains(testChannel))
    XCTAssertTrue(subscription.subscribedChannels.contains(otherChannel))
    
    defer { listener.cancel() }
    wait(for: [statusExpect], timeout: 1.0)
  }
  
  // swiftlint:disable:next file_length
}
