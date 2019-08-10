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

import UIKit

import PubNub

class MasterDetailTableViewController: UITableViewController {
  var pubnub: PubNub!

  let masterDetailCellID = "MasterDetailCell"

  enum SegueId: String {
    case config = "MasterDetailToConfigDetail"
  }

  enum Section: Int {
    case pubnub = 0
    case endpoints = 1
    case presence = 2

    var title: String {
      switch self {
      case .pubnub:
        return "PubNub"
      case .endpoints:
        return "Endpoints"
      case .presence:
        return "Presence Endpoints"
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
      }
    }

    static var sectionCount: Int {
      return 3
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

    var title: String {
      switch self {
      case .time:
        return "Time"
      case .publish:
        return "Publish"
      }
    }

    static var rowCount: Int {
      return 2
    }
  }

  enum PresenceRow: Int {
    case hereNow = 0

    var title: String {
      switch self {
      case .hereNow:
        return "Here Now"
      }
    }

    static var rowCount: Int {
      return 1
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let config = PubNubConfiguration()

    pubnub = PubNub(configuration: config)
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
    case .none:
      break
    }
  }

  func didSelectPresenceSection(at row: Int) {
    switch PresenceRow(rawValue: row) {
    case .some(.hereNow):
      performHereNowRequest()
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
    pubnub.publish(channel: "channelSwift", message: true, shouldCompress: false) { result in
      switch result {
      case let .success(response):
        print("Successful Publish Response: \(response)")
      case let .failure(error):
        print("Failed Publish Response: \(error.localizedDescription)")
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
