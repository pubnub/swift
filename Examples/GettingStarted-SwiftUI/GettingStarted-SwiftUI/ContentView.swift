//
//  ContentView.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import SwiftUI
import PubNubSDK

struct ContentView: View {
  @EnvironmentObject var pubNubViewModel: PubNubViewModel

  var body: some View {
    List(pubNubViewModel.messages, id: \.self) { message in
      Text(message)
    }
    .onAppear {
      pubNubViewModel.subscription?.subscribe()
    }
    .onDisappear {
      pubNubViewModel.subscription?.unsubscribe()
    }
  }
}
