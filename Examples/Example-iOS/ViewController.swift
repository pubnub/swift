//
//  ViewController.swift
//  swiftSdkiOS
//
//  Created by Craig Lane on 6/17/19.
//  Copyright © 2019 PubNub. All rights reserved.
//

import UIKit

import PubNub

class ViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.title = PubNub().text
  }
}
