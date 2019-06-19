//
//  MasterDetailTableViewController.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
//  http://www.pubnub.com/
//  http://www.pubnub.com/terms
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
  let pubnub = PubNub()

  let masterDetailCellID = "MasterDetailCell"

  enum SegueId: String {
    case config = "MasterDetailToConfigDetail"
  }

  enum Section: Int {
    case pubnub = 0
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

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
    switch Section(rawValue: section) {
    case .pubnub?:
      return "PubNub"
    default:
      return nil
    }
  }

  override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch Section(rawValue: section) {
    case .pubnub?:
      return PubNubRow.rowCount
    default:
      return 0
    }
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: masterDetailCellID, for: indexPath)

    switch Section(rawValue: indexPath.section) {
    case .pubnub?:
      cell.textLabel?.text = PubNubRow(rawValue: indexPath.row)?.title

    default:
      break
    }

    return cell
  }

  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch Section(rawValue: indexPath.section) {
    case .pubnub?:
      switch PubNubRow(rawValue: indexPath.row) {
      case .config?:
        performSegue(withIdentifier: SegueId.config.rawValue, sender: self)
      default:
        break
      }

    default:
      break
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
    switch SegueId(rawValue: segue.identifier ?? "") {
    case .config?:
      let configVC = segue.destination as? ConfigDetailTableViewController
      configVC?.config = pubnub.config
    default:
      break
    }
  }
}
