//
//  CryptorHeaderTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import XCTest

@testable import PubNubSDK

class CryptorHeaderTests: XCTestCase {
  private let cryptorId: CryptorId = [0x41, 0x42, 0x43, 0x44]

  // MARK: - Writer

  func test_ToData_WithSingleByteLength_EncodesLengthInOneByte() {
    let data = CryptorHeader.v1(cryptorId: cryptorId, dataLength: 254).toData()

    XCTAssertEqual(Array(data.suffix(1)), [254])
  }

  func test_ToData_WithLengthOf255_EncodesMarkerAndBigEndianLength() {
    let data = CryptorHeader.v1(cryptorId: cryptorId, dataLength: 255).toData()

    XCTAssertEqual(Array(data.suffix(3)), [0xFF, 0x00, 0xFF])
  }

  func test_ToData_WithTwoByteLength_EncodesMarkerAndBigEndianLength() {
    let data = CryptorHeader.v1(cryptorId: cryptorId, dataLength: 0x0102).toData()

    XCTAssertEqual(Array(data.suffix(3)), [0xFF, 0x01, 0x02])
  }

  // MARK: - Parser round trip

  func test_Parse_RoundTripsMetadataLengths() throws {
    for length in [0, 1, 254, 255, 256, 513, 65535] {
      let header = CryptorHeader.v1(cryptorId: cryptorId, dataLength: length)
      let parsed = try CryptorHeader.from(data: header.toData())

      XCTAssertEqual(parsed, header, "Round trip failed for metadata length \(length)")
    }
  }

  func test_Parse_WithTruncatedLengthBytes_Throws() {
    let truncated = CryptorHeader.v1(cryptorId: cryptorId, dataLength: 300).toData().dropLast()

    XCTAssertThrowsError(try CryptorHeader.from(data: Data(truncated)))
  }

  // MARK: - Stream finder

  func test_FindHeader_RoundTripsMetadataLengths() throws {
    // The finder reads at most 1024 bytes, so header and metadata have to fit in that window
    for length in [0, 254, 255, 256, 900] {
      let metadata = Data((0..<length).map { UInt8($0 % 251) })
      let content = Data("file content".utf8)
      let header = CryptorHeader.v1(cryptorId: cryptorId, dataLength: length)
      let source = header.toData() + metadata + content

      let result = try CryptorHeaderWithinStreamFinder(stream: InputStream(data: source)).findHeader()

      XCTAssertEqual(result.header, header, "Header mismatch for metadata length \(length)")
      XCTAssertEqual(result.cryptorDefinedData, metadata, "Metadata mismatch for length \(length)")
      XCTAssertEqual(try readAll(result.continuationStream), content, "Content mismatch for length \(length)")
    }
  }

  private func readAll(_ stream: InputStream) throws -> Data {
    if stream.streamStatus == .notOpen {
      stream.open()
    }
    var result = Data()
    var buffer = [UInt8](repeating: 0, count: 256)

    while stream.hasBytesAvailable {
      let count = stream.read(&buffer, maxLength: buffer.count)
      guard count > 0 else { break }
      result.append(contentsOf: buffer[0..<count])
    }
    return result
  }
}
