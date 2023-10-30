// swift-tools-version:5.0
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
  name: "PubNub",
  platforms: [
    .iOS(.v9),
    .macOS(.v10_11),
    .tvOS(.v9),
    .watchOS(.v2)
  ],
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(
      name: "PubNub",
      targets: ["PubNub"]
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
      name: "PubNub",
      path: "Sources/PubNub"
    ),
    .target(
      name: "PubNubUser",
      dependencies: ["PubNub"],
      path: "PubNubUser/Sources"
    ),
    .target(
      name: "PubNubSpace",
      dependencies: ["PubNub"],
      path: "PubNubSpace/Sources"
    ),
    .target(
      name: "PubNubMembership",
      dependencies: ["PubNub", "PubNubUser", "PubNubSpace"],
      path: "PubNubMembership/Sources"
    ),
    .testTarget(
      name: "PubNubTests",
      dependencies: ["PubNub"]
    )
  ],
  swiftLanguageVersions: [.v5]
)
