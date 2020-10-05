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
import Foundation



import PubNub

// swiftlint:disable:next type_body_length
class MasterDetailTableViewController: UITableViewController {
  var pubnub: PubNub!

  var listener: SubscriptionListener?
  var kvoToken: NSKeyValueObservation?


  let masterDetailCellID = "MasterDetailCell"

  enum SegueId: String {
    case config = "MasterDetailToConfigDetail"
  }

  enum Section: Int, CaseIterable {
    case pubnub = 0
    case endpoints = 1
    case presence = 2
    case groups = 3
    case history = 4
    case push = 5
    case file = 6

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
      case .file:
        return "File"
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
      case .file:
        return FileRow.allCases.count
      }
    }
  }

  enum PubNubRow: Int, CaseIterable {
    case config = 0

    var title: String {
      switch self {
      case .config:
        return "Configuration"
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
  
  enum FileRow: Int, CaseIterable {
    case list
    case send
    case download
    case remove
    case publishFileMessage

    var title: String {
      switch self {
      case .list:
        return "File List"
      case .send:
        return "Send File"
      case .download:
        return "Download File"
      case .remove:
        return "Remove File"
      case .publishFileMessage:
        return "Publish File Message"
      }
    }
  }

  // swiftlint:disable:next cyclomatic_complexity function_body_length
  override func viewDidLoad() {
    super.viewDidLoad()

    var config = PubNubConfiguration()
//    config.cipherKey = Crypto(key: "MyCoolCipherKey")
    config.automaticRetry = AutomaticRetry(retryLimit: 500, policy: .linear(delay: 0.25))

    pubnub = PubNub(configuration: config)

    let listener = SubscriptionListener(queue: .main)
    self.listener = listener
    pubnub.subscription.add(listener)

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
        case .fileUploaded(let file):
          print("A file was uplaoded \(file)")
        case let .subscribeError(error):
          print("The following error was generated during subscription \(error.localizedDescription)")
          print("If `disconnectedUnexpectedly` also occurred then subscription has stopped, and needs to be restarted")
        }
      }
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
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
    case .some(.file):
      cell.textLabel?.text = FileRow(rawValue: indexPath.row)?.title
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
    case .some(.file):
      didSelectFileSection(at: indexPath.row)
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
    pubnub.subscribe(to: ["channelSwift", "file_channel"], withPresence: true)
  }

  func performUnsubscribeRequest() {
    pubnub.unsubscribe(from: ["channelSwift", "file_channel"])
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
    pubnub.fetchMessageHistory(for: ["channelSwift", "file_channel"]) { result in
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
  
  // MARK: File Endpoints
  
  func didSelectFileSection(at row: Int) {
    switch FileRow(rawValue: row) {
    case .some(.list):
      performFileList()
    case .some(.send):
      performFileSend()
    case .some(.download):
      performFileDownload()
    case .some(.remove):
      perfromFileRemove()
    case .some(.publishFileMessage):
      performPublishFileMessage()
    case .none:
      return
    }
  }
  
  func performFileList() {
    pubnub.listFiles(channel: "file_channel") { result in
      switch result {
      case .success((let files, let next)):
        print("File List result:")
        files.forEach { print($0) }
        print("File List next page: \(next ?? "nil")")
      case .failure(let error):
        print("File List error: \(error)")
      }
    }
  }
      
  func performFileSend() {
    // Upload
    guard let fileURL = Bundle.main.url(forResource: "sample", withExtension: "txt") else {
      print("Couldn't find file!")
      return
    }

    pubnub.send(
      local: fileURL,
      channel: "file_channel",
      replacingFilename: "sample.txt"
    ) { [unowned self] (task) in
      print("File upload task \(task)")

      self.present(
        self.progressAlertView(for: task.progress), animated: true, completion: nil
      )

    } completion: { result in
      print("File upload result \(result)")
      self.dismiss(animated: true, completion: nil)
    }
  }
  
  func performFileDownload() {
    // Download
    guard var documentsURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
      print("Could not generate download URL for file")
      return
    }
    documentsURL.appendPathComponent("sample.txt")
    
    // NOTE: Swap out for the correct ID or connect to listFiles
    let file = PubNubLocalFileBase(localFileURL: documentsURL, channel: "file_channel", fileId: "089ac9ab-2d97-42f7-af1c-0c840ccbace4")
    
    pubnub.download(
      file: file, downloadTo: file.localFileURL
    ) { task in
      print("Download \(task)")
      
      self.present(self.progressAlertView(for: task.progress), animated: true, completion: nil)

    } completion: {  result in
      
      self.dismiss(animated: true, completion: nil)
      
      switch result {
      case let .success(localFile):
        print("Finished Downloading \(localFile)")
        let documentViewr = UIDocumentInteractionController(url: localFile.localFileURL)
        documentViewr.delegate = self
        documentViewr.presentPreview(animated: true)
      case let .failure(error):
        print("Failed to download \(error)")
      }
    }
  }
  
  func perfromFileRemove() {
    // Remove
    pubnub.remove(channel: "file_channel", fileId: "49e34e3f-883d-49e0-9508-356cf2261673", filename: "sample.txt") { result in
      print("Remove \(result)")
    }
  }
  
  func performPublishFileMessage() {
    guard let fileURL = Bundle.main.url(forResource: "sample", withExtension: "pdf") else {
      print("Couldn't find file!")
      return
      // we found the file in our bundle!
    }
    
    // NOTE: Swap out for the correct ID or connect to listFiles
    let localFile = PubNubLocalFileBase(
      localFileURL: fileURL,
      channel: "file_channel",
      fileId: "1018d848-bdf2-4e6a-a332-7ddcf1301390"
    )
    pubnub.publish(
      file: localFile,
      request: .init(additionalMessage: "This is a sample document")
    ) { result in
      print("File Message result \(result)")
    }
  }
  
  func progressAlertView(for progress: Progress) -> UIAlertController {
    let alert = UIAlertController(title: "File Status", message: "Transferring...", preferredStyle: .alert)
    let progressView = UIProgressView(progressViewStyle: .default)
    progressView.setProgress(0.0, animated: true)
    progressView.frame = CGRect(x: 10, y: 70, width: 250, height: 0)
    progressView.observedProgress = progress
    alert.view.addSubview(progressView)
    return alert
  }
}

extension MasterDetailTableViewController: UIDocumentInteractionControllerDelegate {
  func documentInteractionControllerViewControllerForPreview(
    _ controller: UIDocumentInteractionController
  ) -> UIViewController {
    return self
  }
}

// swiftlint:endable file_length
