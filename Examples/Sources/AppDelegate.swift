//
//  AppDelegate.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

import PubNub

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  // swiftlint:disable:next discouraged_optional_collection
  func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    UIApplication.shared.registerForRemoteNotifications()

    PubNub.log.levels = [.all]

    return true
  }

  func applicationWillResignActive(_: UIApplication) {}

  func applicationDidEnterBackground(_: UIApplication) {}

  func applicationWillEnterForeground(_: UIApplication) {}

  func applicationDidBecomeActive(_: UIApplication) {}

  func applicationWillTerminate(_: UIApplication) {}

  func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    UserDefaults.standard.set(deviceToken, forKey: "DeviceToken")
  }

  func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError _: Error) {
    // Example push token for use in simulator
    let exampleToken = Data(hexEncodedString: "740f4707bebcf74f9b7c25d48e3358945f6aa01da5ddb387462c7eaf61bb78ad")
    UserDefaults.standard.set(exampleToken, forKey: "DeviceToken")
  }

  func application(
    _: UIApplication, handleEventsForBackgroundURLSession identifier: String,
    completionHandler _: @escaping () -> Void
  ) {
    print("Background requests can be possibly resumed by creating a URLSession with this identifier \(identifier)")
  }
}
