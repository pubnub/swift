//
//  MyApp.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import SwiftUI

@main
struct MyApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(PubNubViewModel())
    }
  }
}
