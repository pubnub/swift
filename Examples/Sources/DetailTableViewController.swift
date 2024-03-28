//
//  MasterDetailTableViewController.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import UIKit

import PubNub
import PubNubMembership
import PubNubSpace
import PubNubUser

// swiftlint:disable:next type_body_length
class DetailTableViewController: UITableViewController {
  var pubnub: PubNub!

  var listener: SubscriptionListener?
  var userListener: PubNubUserListener?
  var spaceListener: PubNubSpaceListener?
  var membershipListener: PubNubMembershipListener?

  let detailCellID = "MasterDetailCell"

  enum SegueId: String {
    case config = "MasterDetailToConfigDetail"
    case fileAPI = "MasterDetailToFileAPI"
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    super.prepare(for: segue, sender: sender)

    switch SegueId(rawValue: segue.identifier ?? "") {
    case .some(.config):
      let configVC = segue.destination as? ConfigDetailTableViewController
      configVC?.config = pubnub.configuration
    case .some(.fileAPI):
      let fileAPIController = segue.destination as? FileAPIViewController
      fileAPIController?.pubnub = pubnub
    default:
      break
    }
  }

  enum Section: Int, CaseIterable {
    case pubnub = 0
    case endpoints = 1
    case presence = 2
    case groups = 3
    case history = 4
    case push = 5

    var title: String {
      switch self {
      case .pubnub:
        return "PubNub"
      case .endpoints:
        return "Endpoints"
      case .presence:
        return "Presence Endpoints"
      case .groups:
        return "Channel Groups"
      case .history:
        return "Message History"
      case .push:
        return "Push Notifications"
      }
    }

    var rowCount: Int {
      switch self {
      case .pubnub:
        return PubNubRow.allCases.count
      case .endpoints:
        return EndpointRow.allCases.count
      case .presence:
        return PresenceRow.allCases.count
      case .groups:
        return ChannelGroupRow.allCases.count
      case .history:
        return HistoryRow.allCases.count
      case .push:
        return PushRow.allCases.count
      }
    }
  }

  enum PubNubRow: Int, CaseIterable {
    case config = 0
    case file = 1

    var title: String {
      switch self {
      case .config:
        return "Configuration"
      case .file:
        return "File"
      }
    }
  }

  enum EndpointRow: Int, CaseIterable {
    case time = 0
    case publish = 1
    case signal = 2
    case subscribe = 3
    case unsubscribe = 4
    case getState = 5
    case setState = 6

    var title: String {
      switch self {
      case .time:
        return "Time"
      case .publish:
        return "Publish"
      case .signal:
        return "Signal"
      case .subscribe:
        return "Subscribe"
      case .unsubscribe:
        return "Unsubscribe"
      case .getState:
        return "Get State"
      case .setState:
        return "Set State"
      }
    }
  }

  enum PresenceRow: Int, CaseIterable {
    case hereNow = 0
    case whereNow = 1

    var title: String {
      switch self {
      case .hereNow:
        return "Here Now"
      case .whereNow:
        return "Where Now"
      }
    }
  }

  enum ChannelGroupRow: Int, CaseIterable {
    case listGroups = 0
    case listChannels = 1
    case addChannels = 2
    case removeChannels = 3
    case deleteGroup = 4

    var title: String {
      switch self {
      case .listGroups:
        return "List Groups"
      case .listChannels:
        return "List Channels"
      case .addChannels:
        return "Add Channels"
      case .removeChannels:
        return "Remove Channels"
      case .deleteGroup:
        return "Delete Group"
      }
    }
  }

  enum PushRow: Int, CaseIterable {
    case listPushChannels
    case modifyPushChannels
    case deletePushChannels

    var title: String {
      switch self {
      case .listPushChannels:
        return "List Push Channels"
      case .modifyPushChannels:
        return "Modify Push Channels"
      case .deletePushChannels:
        return "Delete Push Channels"
      }
    }
  }

  enum HistoryRow: Int, CaseIterable {
    case messageCount
    case fetchMessageHistory
    case deleteMessageHistory

    var title: String {
      switch self {
      case .messageCount:
        return "Message Count"
      case .fetchMessageHistory:
        return "Fetch Message History"
      case .deleteMessageHistory:
        return "Delete Message History"
      }
    }
  }

  // swiftlint:disable:next cyclomatic_complexity function_body_length
  override func viewDidLoad() {
    super.viewDidLoad()

    var config = PubNubConfiguration(
      publishKey: "demo", subscribeKey: "demo", userId: UUID().uuidString
    )
    // Uncomment the next line to encrypt messages/files
//    config.cipherKey = Crypto(key: "MyCoolCipherKey")
    config.automaticRetry = AutomaticRetry(retryLimit: 500, policy: .linear(delay: 0.25))

    pubnub = PubNub(configuration: config)

    let listener = SubscriptionListener(queue: .main)
    let userEvents = PubNubUserListener(queue: .main)
    let spaceEvents = PubNubSpaceListener(queue: .main)
    let membershipEvents = PubNubMembershipListener(queue: .main)

    self.listener = listener
    userListener = userEvents
    spaceListener = spaceEvents
    membershipListener = membershipEvents

    pubnub.add(listener)
    pubnub.add(userEvents)
    pubnub.add(spaceEvents)
    pubnub.add(membershipEvents)

    self.listener?.didReceiveBatchSubscription = { events in
      for event in events {
        switch event {
        case let .messageReceived(message):
          print("The \(message.channel) channel received a message at \(message.published)")
          if let subscription = message.subscription {
            print("The channel-group or wildcard that matched this channel was \(subscription)")
          }
          print("The message is \(message.payload) and was sent by \(message.publisher ?? "")")
        case let .signalReceived(signal):
          print("The \(signal.channel) channel received a message at \(signal.published)")
          if let subscription = signal.subscription {
            print("The channel-group or wildcard that matched this channel was \(subscription)")
          }
          print("The signal is \(signal.payload) and was sent by \(signal.publisher ?? "")")
        case let .connectionStatusChanged(connectionChange):
          switch connectionChange {
          case .connecting:
            print("Status connecting...")
          case .connected:
            print("Status connected!")
          case .reconnecting:
            print("Status reconnecting...")
          case .disconnected:
            print("Status disconnected")
          case .disconnectedUnexpectedly:
            print("Status disconnected unexpectedly!")
          case .connectionError:
            print("Cannot establish initial conection to the remote system")
          }
        case let .subscriptionChanged(subscribeChange):
          switch subscribeChange {
          case let .subscribed(channels, groups):
            print("\(channels) and \(groups) were added to subscription")
          case let .responseHeader(channels, groups, previous, next):
            print("\(channels) and \(groups) recevied a response at \(previous?.timetoken ?? 0)")
            print("\(next?.timetoken ?? 0) will be used as the new timetoken")
          case let .unsubscribed(channels, groups):
            print("\(channels) and \(groups) were removed from subscription")
          }
        case let .presenceChanged(presenceChange):
          print("The channel \(presenceChange.channel) has an updated occupancy of \(presenceChange.occupancy)")
          for action in presenceChange.actions {
            switch action {
            case let .join(uuids):
              print("The following list of occupants joined at \(presenceChange.timetoken): \(uuids)")
            case let .leave(uuids):
              print("The following list of occupants left at \(presenceChange.timetoken): \(uuids)")
            case let .timeout(uuids):
              print("The following list of occupants timed-out at \(presenceChange.timetoken): \(uuids)")
            case let .stateChange(uuid, state):
              print("\(uuid) changed their presence state to \(state) at \(presenceChange.timetoken)")
            }
          }

        case let .uuidMetadataSet(uuidMetadataChange):
          print("Changes were made to \(uuidMetadataChange.metadataId) at \(uuidMetadataChange.updated)")
          print("To apply the change, fetch a matching object and call uuidMetadataChange.apply(to: otherUUIDMetadata)")
        case let .uuidMetadataRemoved(metadataId):
          print("Metadata for the uuid \(metadataId) has been removed")
        case let .channelMetadataSet(channelMetadata):
          print("Changes were made to \(channelMetadata.metadataId) at \(channelMetadata.updated)")
          print("To apply the change, fetch a matching object and call channelMetadata.apply(to: otherUUIDMetadata)")
        case let .channelMetadataRemoved(metadataId):
          print("Metadata for the channel \(metadataId) has been removed")
        case let .membershipMetadataSet(membership):
          print("A membership was set between \(membership.uuidMetadataId) and \(membership.channelMetadataId)")
        case let .membershipMetadataRemoved(membership):
          print("A membership was removed between \(membership.uuidMetadataId) and \(membership.channelMetadataId)")

        case let .messageActionAdded(messageAction):
          print("The \(messageAction.channel) channel received a message at \(messageAction.messageTimetoken)")
          print("This action was created at \(messageAction.actionTimetoken)")
          print("This action has a type of \(messageAction.actionType) and has a value of \(messageAction.actionValue)")
        case let .messageActionRemoved(messageAction):
          print("The \(messageAction.channel) channel received a message at \(messageAction.messageTimetoken)")
          print("A message action with the timetoken of \(messageAction.actionTimetoken) has been removed")
        case let .fileUploaded(file):
          print("A file was uplaoded \(file)")
        case let .subscribeError(error):
          print("The following error was generated during subscription \(error.localizedDescription)")
          error.affected.forEach {
            switch $0 {
            case let .channels(affectedChannels):
              print("Affected channels: \(affectedChannels)")
            case let .channelGroups(affectedChannelGroups):
              print("Affected channel groups: \(affectedChannelGroups)")
            default:
              break
            }
          }
          print("If `disconnectedUnexpectedly` also occurred then subscription has stopped, and needs to be restarted")
        }
      }
    }

    userListener?.didReceiveUserEvents = { events in
      for event in events {
        switch event {
        case let .userUpdated(patch):
          print("Changes were made to \(patch.id) at \(patch.updated)")
          print("To apply the change, fetch a matching User and call user.apply(patch)")
        case let .userRemoved(user):
          print("The User for the userId \(user.id) has been removed")
        }
      }
    }

    spaceListener?.didReceiveSpaceEvents = { events in
      for event in events {
        switch event {
        case let .spaceUpdated(patch):
          print("Changes were made to \(patch.id) at \(patch.updated)")
          print("To apply the change, fetch a matching Space and call space.apply(patch)")
        case let .spaceRemoved(space):
          print("The User for the spaceId \(space.id) has been removed")
        }
      }
    }

    membershipListener?.didReceiveMembershipEvents = { events in
      for event in events {
        switch event {
        case let .membershipUpdated(patch):
          print("Membership updated between User.id \(patch.userId) and Space.id \(patch.spaceId)) at \(patch.updated)")
          print("To apply the change, fetch a matching Membership and call membership.apply(patch)")
        case let .membershipRemoved(membership):
          print("A membership was removed between userId \(membership.user.id) and spaceId \(membership.space.id)")
        }
      }
    }
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    super.numberOfSections(in: tableView)

    return Section.allCases.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    super.tableView(tableView, titleForHeaderInSection: section)

    return Section(rawValue: section)?.title
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    super.tableView(tableView, numberOfRowsInSection: section)

    return Section(rawValue: section)?.rowCount ?? 0
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    super.tableView(tableView, cellForRowAt: indexPath)

    let cell = tableView.dequeueReusableCell(withIdentifier: detailCellID, for: indexPath)

    switch Section(rawValue: indexPath.section) {
    case .some(.pubnub):
      cell.textLabel?.text = PubNubRow(rawValue: indexPath.row)?.title
    case .some(.endpoints):
      cell.textLabel?.text = EndpointRow(rawValue: indexPath.row)?.title
    case .some(.presence):
      cell.textLabel?.text = PresenceRow(rawValue: indexPath.row)?.title
    case .some(.groups):
      cell.textLabel?.text = ChannelGroupRow(rawValue: indexPath.row)?.title
    case .some(.history):
      cell.textLabel?.text = HistoryRow(rawValue: indexPath.row)?.title
    case .some(.push):
      cell.textLabel?.text = PushRow(rawValue: indexPath.row)?.title
    default:
      break
    }

    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)

    switch Section(rawValue: indexPath.section) {
    case .some(.pubnub):
      didSelectPubNubSection(at: indexPath.row)
    case .some(.endpoints):
      didSelectEndpointSection(at: indexPath.row)
    case .some(.presence):
      didSelectPresenceSection(at: indexPath.row)
    case .some(.groups):
      didSelectGroupsSection(at: indexPath.row)
    case .some(.history):
      didSelectHistorySection(at: indexPath.row)
    case .some(.push):
      didSelectPushSection(at: indexPath.row)
    default:
      break
    }
  }

  func didSelectPubNubSection(at row: Int) {
    switch PubNubRow(rawValue: row) {
    case .some(.config):
      performSegue(withIdentifier: SegueId.config.rawValue, sender: self)
    case .some(.file):
      performSegue(withIdentifier: SegueId.fileAPI.rawValue, sender: self)
    case .none:
      break
    }
  }

  func didSelectEndpointSection(at row: Int) {
    switch EndpointRow(rawValue: row) {
    case .some(.time):
      performTimeRequest()
    case .some(.publish):
      performPublishRequest()
    case .some(.signal):
      performSignalRequest()
    case .some(.subscribe):
      performSubscribeRequest()
    case .some(.unsubscribe):
      performUnsubscribeRequest()
    case .some(.getState):
      performGetState()
    case .some(.setState):
      performSetState()
    case .none:
      break
    }
  }

  func didSelectPresenceSection(at row: Int) {
    switch PresenceRow(rawValue: row) {
    case .some(.hereNow):
      performHereNowRequest()
    case .some(.whereNow):
      performWhereNowRequest()
    case .none:
      break
    }
  }

  func didSelectGroupsSection(at row: Int) {
    switch ChannelGroupRow(rawValue: row) {
    case .some(.listGroups):
      performListGroupsRequest()
    case .some(.listChannels):
      performListChannelsRequest()
    case .some(.addChannels):
      performAddChannelsRequest()
    case .some(.removeChannels):
      performRemoveChannelsRequest()
    case .some(.deleteGroup):
      performDeleteGroupRequest()
    case .none:
      break
    }
  }

  func didSelectHistorySection(at row: Int) {
    switch HistoryRow(rawValue: row) {
    case .some(.messageCount):
      performMessageCount()
    case .some(.fetchMessageHistory):
      performHistoryFetch()
    case .some(.deleteMessageHistory):
      performHistoryDeletion()
    case .none:
      break
    }
  }

  func didSelectPushSection(at row: Int) {
    let deviceToken = UserDefaults.standard.value(forKey: "DeviceToken") as? Data ?? Data()
    switch PushRow(rawValue: row) {
    case .some(.listPushChannels):
      performListPush(deviceToken)
    case .some(.modifyPushChannels):
      performModifyPush(deviceToken)
    case .some(.deletePushChannels):
      performDeletePush(deviceToken)
    case .none:
      break
    }
  }

  func performTimeRequest() {
    pubnub.time { result in
      switch result {
      case let .success(response):
        print("Successful Time Response: \(response)")
      case let .failure(error):
        print("Failed Time Response: \(error.localizedDescription)")
      }
    }
  }

  func performPublishRequest() {
    let payload = PubNubPushMessage(
      apns: PubNubAPNSPayload(
        aps: APSPayload(alert: .object(.init(title: "Chat invite")), sound: .string("default")),
        pubnub: [.init(targets: [.init(topic: "com.example.chat", environment: .production)])],
        payload: ""
      ),
      fcm: PubNubFCMPayload(
        payload: "",
        target: .topic("com.example.chat"),
        notification: FCMNotificationPayload(title: "Chat invite"),
        android: FCMAndroidPayload(notification: FCMAndroidNotification(sound: "default"))
      )
    )

    pubnub.publish(channel: "channelSwift", message: payload) { result in
      switch result {
      case let .success(response):
        print("Successful Publish Response: \(response)")
      case let .failure(error):
        print("Failed Publish Response: \(error.localizedDescription)")
      }
    }
  }

  func performSignalRequest() {
    pubnub.signal(channel: "channelSwift", message: "Test Signal") { result in
      switch result {
      case let .success(response):
        print("Successful Signal Response: \(response)")
      case let .failure(error):
        print("Failed Signal Response: \(error.localizedDescription)")
      }
    }
  }

  func performSubscribeRequest() {
    pubnub.subscribe(to: ["channelSwift"], withPresence: true)
  }

  func performUnsubscribeRequest() {
    pubnub.unsubscribe(from: ["channelSwift"])
  }

  func performSetState() {
    pubnub.setPresence(
      state: ["New": "State"],
      on: ["channelSwift"],
      and: ["demo"]
    ) { result in
      switch result {
      case let .success(response):
        print("Successful Set State Response: \(response)")
      case let .failure(error):
        print("Failed Set State Response: \(error.localizedDescription)")
      }
    }
  }

  func performGetState() {
    pubnub.getPresenceState(
      for: pubnub.configuration.uuid,
      on: ["channelSwift"],
      and: ["demo"]
    ) { result in
      switch result {
      case let .success(response):
        print("Successful Get State Response: \(response)")
      case let .failure(error):
        print("Failed Get State Response: \(error.localizedDescription)")
      }
    }
  }

  func performHereNowRequest() {
    pubnub.hereNow(on: ["channelSwift"], and: ["demo"], includeState: true) { result in
      switch result {
      case let .success(response):
        print("Successful HereNow Response: \(response)")
      case let .failure(error):
        print("Failed HereNow Response: \(error.localizedDescription)")
      }
    }
  }

  func performWhereNowRequest() {
    pubnub.whereNow(for: "db9c5e39-7c95-40f5-8d71-125765b6f561") { result in
      switch result {
      case let .success(response):
        print("Successful WhereNow Response: \(response)")
      case let .failure(error):
        print("Failed WhereNow Response: \(error.localizedDescription)")
      }
    }
  }

  func performListGroupsRequest() {
    pubnub.listChannelGroups { result in
      switch result {
      case let .success(response):
        print("Successful List Channel Groups Response: \(response)")
      case let .failure(error):
        print("Failed Channel Groups Response: \(error.localizedDescription)")
      }
    }
  }

  func performListChannelsRequest() {
    pubnub.listChannels(for: "SwiftGroup") { result in
      switch result {
      case let .success(response):
        print("Successful List Channels Response: \(response)")
      case let .failure(error):
        print("Failed List Channels Response: \(error.localizedDescription)")
      }
    }
  }

  func performAddChannelsRequest() {
    pubnub.add(channels: ["channelSwift", "otherChannel"], to: "SwiftGroup") { result in
      switch result {
      case let .success(response):
        print("Successful Add Channels Response: \(response)")
      case let .failure(error):
        print("Failed Add Channels Response: \(error.localizedDescription)")
      }
    }
  }

  func performRemoveChannelsRequest() {
    pubnub.remove(channels: ["channelSwift, otherChannel"], from: "SwiftGroup") { result in
      switch result {
      case let .success(response):
        print("Successful Remove Channels Response: \(response)")
      case let .failure(error):
        print("Failed Remove Channels Response: \(error.localizedDescription)")
      }
    }
  }

  func performDeleteGroupRequest() {
    pubnub.remove(channelGroup: "SwiftGroup") { result in
      switch result {
      case let .success(response):
        print("Successful Delete Group Response: \(response)")
      case let .failure(error):
        print("Failed Delete Group Response: \(error.localizedDescription)")
      }
    }
  }

  func performMessageCount() {
    pubnub.messageCounts(channels: ["channelSwift"]) { result in
      switch result {
      case let .success(response):
        print("Successful Message Count Response: \(response)")
      case let .failure(error):
        print("Failed Message Count Response: \(error.localizedDescription)")
      }
    }
  }

  func performHistoryFetch() {
    pubnub.fetchMessageHistory(for: ["channelSwift"]) { result in
      switch result {
      case let .success(response):
        print("Successful History Fetch Response: \(response)")
      case let .failure(error):
        print("Failed History Fetch Response: \(error.localizedDescription)")
      }
    }
  }

  func performHistoryDeletion() {
    pubnub.deleteMessageHistory(from: "channelSwift") { result in
      switch result {
      case let .success(response):
        print("Successful Message Deletion Response: \(response)")
      case let .failure(error):
        print("Failed Message Deletion Response: \(error.localizedDescription)")
      }
    }
  }

  func performListPush(_ deviceToken: Data) {
    pubnub.listPushChannelRegistrations(for: deviceToken) { result in
      switch result {
      case let .success(response):
        print("Successful Push List Response: \(response)")
      case let .failure(error):
        print("Failed Push List Response: \(error.localizedDescription)")
      }
    }
  }

  func performModifyPush(_ deviceToken: Data) {
    pubnub.managePushChannelRegistrations(
      byRemoving: ["channelSwift"],
      thenAdding: ["channelSwift"],
      for: deviceToken
    ) { result in
      switch result {
      case let .success(response):
        print("Successful Push Modification Response: \(response)")
      case let .failure(error):
        print("Failed Push Modification Response: \(error.localizedDescription)")
      }
    }
  }

  func performDeletePush(_ deviceToken: Data) {
    pubnub.removeAllPushChannelRegistrations(for: deviceToken) { result in
      switch result {
      case let .success(response):
        print("Successful Push Deletion Response: \(response)")
      case let .failure(error):
        print("Failed Push Deletion Response: \(error.localizedDescription)")
      }
    }
  }

  // swiftlint:disable:next file_length
}
