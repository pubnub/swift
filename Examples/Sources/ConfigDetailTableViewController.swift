//
//  ConfigDetailTableViewController.swift
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

class ConfigDetailTableViewController: UITableViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
  }

  let configCellID = "PubNubConfigDetailCell"

  var config: PubNubConfiguration!

  enum ConfigProperties: Int {
    case publishKey
    case subscribeKey
    case cipherKey
    case authKey
    case uuid
    case useSecureConnections
    case origin
    case presenceTimeout
    case heartbeatInterval
    case supressLeaveEvents
    case requestMessageCountThreshold

    static var rowCount: Int {
      return 11
    }

    var title: String {
      switch self {
      case .publishKey:
        return "Publish Key"
      case .subscribeKey:
        return "Subscribe Key"
      case .cipherKey:
        return "Cipher Key"
      case .authKey:
        return "Auth Key"
      case .uuid:
        return "UUID"
      case .useSecureConnections:
        return "Use Secure Connections (https)?"
      case .origin:
        return "Origin Hostname"
      case .presenceTimeout:
        return "Presence Timeout"
      case .heartbeatInterval:
        return "Heartbeat Interval"
      case .supressLeaveEvents:
        return "Supress Leave Events"
      case .requestMessageCountThreshold:
        return "Request Message Threshold"
      }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func value(from config: PubNubConfiguration) -> String? {
      switch self {
      case .publishKey:
        return config.publishKey
      case .subscribeKey:
        return config.subscribeKey
      case .cipherKey:
        return config.cipherKey?.key.description
      case .authKey:
        return config.authKey
      case .uuid:
        return config.uuid
      case .useSecureConnections:
        return config.useSecureConnections.description
      case .origin:
        return config.origin
      case .presenceTimeout:
        return config.durationUntilTimeout.description
      case .heartbeatInterval:
        return config.heartbeatInterval.description
      case .supressLeaveEvents:
        return config.supressLeaveEvents.description
      case .requestMessageCountThreshold:
        return config.requestMessageCountThreshold.description
      }
    }
  }

  override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    return ConfigProperties.rowCount
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: configCellID, for: indexPath)

    cell.textLabel?.text = ConfigProperties(rawValue: indexPath.row)?.title
    cell.detailTextLabel?.text = ConfigProperties(rawValue: indexPath.row)?.value(from: config)

    return cell
  }
}
