//
//  PubNubObjectsTestHelpers.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import PubNub

extension PubNubContractTestCase {
  /// Use entity name to compose path on JSON with it's representation.
  ///
  /// - Parameter name: Entity name which is the same as name of file in which it is stored.
  /// - Returns: Full path to the file with entity information.
  private func entityDataPathByName(_ name: String) -> String {
    let filePath = "Features/data/\(name).json"
    let bundle = Bundle(for: PubNubContractTestCase.self)
    return (bundle.bundlePath as NSString).appendingPathComponent(filePath)
  }

  /// Load entity entity information from file.
  ///
  /// - Parameter filePath: Full path to the file with entity information.
  /// - returns: An updated `PubNubSpace` with the patched values, or the same object if no patch was applied.
  private func loadDataFile(_ filePath: String) -> Data? {
    guard let loadedData = try? NSData(contentsOfFile: filePath) as Data else {
      XCTAssert(false, "Unable to load data from: \(filePath)")
      return nil
    }

    return loadedData
  }

  /// Retrieve `UUID metadata` object information using owner name.
  ///
  /// - Parameter name: Entity name which is the same as name of file in which it is stored.
  /// - Returns: Parsed `PubNubUUIDMetadata` object or `nil` in case of parse / load error.
  func uuidMetadata(with name: String) -> PubNubUUIDMetadata? {
    guard let uuidData = loadDataFile(entityDataPathByName(name)) else { return nil }
    guard let uuidMetadata = try? Constant.jsonDecoder.decode(PubNubUUIDMetadataBase.self, from: uuidData) else {
      XCTAssert(false, "Unable to load / parse data for '\(name)' persona.")
      return nil
    }

    return uuidMetadata
  }

  /// Retrieve `membership metadata` object information using owner name.
  ///
  /// - Parameter name: Entity name which is the same as name of file in which it is stored.
  /// - Parameter entity: Identifier of entity for which membership is retrieved.
  /// - Returns: Parsed `ObjectMetadataPartial` object or `nil` in case of parse / load error.
  func membership(with name: String, for entity: String) -> PubNubMembershipMetadata? {
    guard let membershipData = loadDataFile(entityDataPathByName(name)) else { return nil }
    guard let partialMembershipMetadata = try? Constant.jsonDecoder.decode(ObjectMetadataPartial.self, from: membershipData) else {
      XCTAssert(false, "Unable to load / parse data for '\(name)' partial membership.")
      return nil
    }
    guard let membershipMetadata = PubNubMembershipMetadataBase(from: partialMembershipMetadata, other: entity) else {
      XCTAssert(false, "Unable create membership metadata for '\(name)' membership.")
      return nil
    }

    return membershipMetadata
  }

  /// Retrieve `channel metadata` object information using owner name.
  ///
  /// - Parameter name: Entity name which is the same as name of file in which it is stored.
  /// - Returns: Parsed `PubNubChannelMetadata` object or `nil` in case of parse / load error.
  func channelMetadata(with name: String) -> PubNubChannelMetadata? {
    guard let channelData = loadDataFile(entityDataPathByName(name)) else { return nil }
    guard let channelMetadata = try? Constant.jsonDecoder.decode(PubNubChannelMetadataBase.self, from: channelData) else {
      XCTAssert(false, "Unable to load / parse data for '\(name)' channel.")
      return nil
    }

    return channelMetadata
  }
}
