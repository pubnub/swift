//
//  MasterDetailTableViewController.swift
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
// swiftlint:disable file_length

import UIKit

import PubNub

// swiftlint:disable:next type_body_length
class MasterDetailTableViewController: UITableViewController {
  var pubnub: PubNub!

  var listener: SubscriptionListener?

  let masterDetailCellID = "MasterDetailCell"

  enum SegueId: String {
    case config = "MasterDetailToConfigDetail"
  }

  enum Section: Int {
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
        return PubNubRow.rowCount
      case .endpoints:
        return EndpointRow.rowCount
      case .presence:
        return PresenceRow.rowCount
      case .groups:
        return ChannelGroupRow.rowCount
      case .history:
        return HistoryRow.rowCount
      case .push:
        return PushRow.rowCount
      }
    }

    static var sectionCount: Int {
      return 6
    }
  }

  enum PubNubRow: Int {
    case config = 0

    var title: String {
      switch self {
      case .config:
        return "Configuration"
      }
    }

    static var rowCount: Int {
      return 1
    }
  }

  enum EndpointRow: Int {
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

    static var rowCount: Int {
      return 7
    }
  }

  enum PresenceRow: Int {
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

    static var rowCount: Int {
      return 2
    }
  }

  enum ChannelGroupRow: Int {
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

    static var rowCount: Int {
      return 5
    }
  }

  enum PushRow: Int {
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

    static var rowCount: Int {
      return 3
    }
  }

  enum HistoryRow: Int {
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

    static var rowCount: Int {
      return 3
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    var config = PubNubConfiguration()
    config.cipherKey = Crypto(key: "MyCoolCipherKey")
    config.automaticRetry = AutomaticRetry(retryLimit: 500, policy: .linear(delay: 0.25))

    pubnub = PubNub(configuration: config)

    let listener = SubscriptionListener(queue: .main)
    self.listener = listener
    pubnub.subscription.add(listener)

    self.listener?.didReceiveMessage = { message in
      print("Message Received: \(message)")
    }

    self.listener?.didReceiveSignal = { signal in
      print("Signal Received: \(signal)")
    }

    self.listener?.didReceiveStatus = { result in
      print("Status Received: \(result)")
    }

    self.listener?.didReceivePresence = { result in
      print("Presence Received: \(result)")
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    super.numberOfSections(in: tableView)

    return Section.sectionCount
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

    let cell = tableView.dequeueReusableCell(withIdentifier: masterDetailCellID, for: indexPath)

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

    pubnub.publish(channel: "channelSwift", message: true, shouldCompress: false) { result in
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
    pubnub.subscribe(to: ["channelSwift"], withPresence: true, setting: ["channelSwift": ["SubKey": "SubValue"]])
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
    pubnub.hereNow(on: ["channelSwift"], and: ["demo"], also: true) { result in
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
    pubnub.delete(channelGroup: "SwiftGroup") { result in
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
    pubnub.fetchMessageHistory(for: ["channelSwift"],
                               max: 25,
                               start: nil,
                               end: nil) { result in
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
    pubnub.modifyPushChannelRegistrations(
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

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    super.prepare(for: segue, sender: sender)

    switch SegueId(rawValue: segue.identifier ?? "") {
    case .config?:
      let configVC = segue.destination as? ConfigDetailTableViewController
      configVC?.config = pubnub.configuration
    default:
      break
    }
  }
}

// swiftlint:endable file_length
