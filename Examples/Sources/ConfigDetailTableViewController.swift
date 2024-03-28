//
//  ConfigDetailTableViewController.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

import PubNub

class ConfigDetailTableViewController: UITableViewController {

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
        return config.cryptoModule?.description ?? "CryptoModule Not Found"
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
