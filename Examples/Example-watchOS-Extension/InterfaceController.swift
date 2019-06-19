//
//  InterfaceController.swift
//  swiftSdkWatchOS Extension
//
//  Created by Craig Lane on 6/17/19.
//  Copyright © 2019 PubNub. All rights reserved.
//

import Foundation
import WatchKit

class InterfaceController: WKInterfaceController {
  override func awake(withContext context: Any?) {
    super.awake(withContext: context)

    // Configure interface objects here.
  }

  override func willActivate() {
    // This method is called when watch view controller is about to be visible to user
    super.willActivate()
  }

  override func didDeactivate() {
    // This method is called when watch view controller is no longer visible
    super.didDeactivate()
  }
}
