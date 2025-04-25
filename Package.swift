// swift-tools-version:5.9
//
//  Package.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PackageDescription

let package = Package(
  name: "PubNubSDK",
  platforms: [
    .iOS(.v13),
    .macOS(.v11),
    .tvOS(.v13),
    .watchOS(.v6),
    .visionOS(.v1)
  ],
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(
      name: "PubNubSDK",
      targets: ["PubNubSDK"]
    ),
    .library(
      name: "PubNubUser",
      targets: ["PubNubUser"]
    ),
    .library(
      name: "PubNubSpace",
      targets: ["PubNubSpace"]
    ),
    .library(
      name: "PubNubMembership",
      targets: ["PubNubMembership"]
    )
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .target(
      name: "PubNubSDK",
      path: "Sources/PubNub",
      resources: [.copy("PrivacyInfo.xcprivacy")]
    ),
    .target(
      name: "PubNubUser",
      dependencies: ["PubNubSDK"],
      path: "PubNubUser/Sources"
    ),
    .target(
      name: "PubNubSpace",
      dependencies: ["PubNubSDK"],
      path: "PubNubSpace/Sources"
    ),
    .target(
      name: "PubNubMembership",
      dependencies: ["PubNubSDK", "PubNubUser", "PubNubSpace"],
      path: "PubNubMembership/Sources"
    ),
    .testTarget(
      name: "PubNubTests",
      dependencies: ["PubNubSDK"]
    )
  ],
  swiftLanguageVersions: [.v5]
)
