//
//  CryptorHeader.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import CommonCrypto

private let sentinel = "PNED"

enum CryptorHeader: Equatable {
  case none
  case v1(cryptorId: CryptorId, dataLength: Int)
      
  func length() -> Int {
    toData().count
  }
    
  func cryptorId() -> CryptorId {
    switch self {
    case .none:
      return LegacyCryptor.ID
    case .v1(let cryptorId, _):
      return cryptorId
    }
  }
  
  func toData() -> Data {
    guard case .v1(let cryptorId, let dataLength) = self else {
      return Data()
    }
    
    var finalData = sentinel.data(using: .ascii) ?? Data()
    finalData += Data(bytes: [1], count: 1)
    finalData += Data(bytes: cryptorId, count: cryptorId.count)
    
    if dataLength < 255 {
      finalData += Data(bytes: [dataLength], count: 1)
    } else {
      finalData += Data(bytes: [0xFF, dataLength >> 8, dataLength & 0xFF], count: 3)
    }
    return finalData
  }
  
  static func from(data: Data) throws -> Self {
    try CryptorHeaderParser(data: data).parse()
  }
}

fileprivate class CryptorHeaderDataScanner {
  private(set) var nextIndex: Int = 0
  private let data: Data
  
  init(data: Data) {
    self.data = data
  }
    
  func nextBytes(_ count: Int) -> Data? {
    let previousValue = nextIndex
    let newValue = nextIndex + count
    
    guard newValue <= data.count else { return nil }
    nextIndex = newValue
    
    return data.subdata(in: previousValue..<newValue)
  }
  
  func nextByte() -> UInt8? {
    nextBytes(1)?.first
  }
  
  func bytesRead() -> Data {
    data.suffix(nextIndex)
  }
}

struct CryptorHeaderParser {
  private let scanner: CryptorHeaderDataScanner
  private let supportedVersionsRange: ClosedRange<UInt8> = (1...1)
  
  init(data: Data) {
    self.scanner = CryptorHeaderDataScanner(data: data)
  }
  
  func parse() throws -> CryptorHeader {
    guard let possibleSentinelBytes = scanner.nextBytes(4) else {
      return .none
    }
    guard let sentinelString = String(data: possibleSentinelBytes, encoding: .ascii) else {
      return .none
    }
    guard sentinelString == sentinel else {
      return .none
    }
    guard let headerVersion = scanner.nextByte() else {
      throw PubNubError(.decryptionFailure, additional: ["Could not find CryptorHeader version"])
    }
    guard supportedVersionsRange.contains(headerVersion) else {
      throw PubNubError(.unknownCryptorFailure, additional: ["Unsupported or invalid CryptorHeader version \(headerVersion)"])
    }
    guard let cryptorId = scanner.nextBytes(4) else {
      throw PubNubError(.decryptionFailure, additional: ["Could not find Cryptor identifier"])
    }
    guard let cryptorDataSizeByte = scanner.nextByte() else {
      throw PubNubError(.decryptionFailure, additional: ["Could not find Cryptor data size byte"])
    }
    guard let finalCryptorDataSize = try? computeCryptorDataSize(with: Int(cryptorDataSizeByte)) else {
      throw PubNubError(.decryptionFailure, additional: ["Could not retrieve Cryptor defined data size"])
    }
    return .v1(
      cryptorId: cryptorId.map { $0 },
      dataLength: Int(finalCryptorDataSize)
    )
  }
  
  private func computeCryptorDataSize(with sizeIndicator: Int) throws -> UInt16 {
    guard sizeIndicator > 255 else {
      return UInt16(sizeIndicator)
    }
    guard let nextBytes = scanner.nextBytes(2) else {
      throw PubNubError(.unknownCryptorFailure, additional: ["Could not find next Cryptor data size bytes"])
    }
    return nextBytes.withUnsafeBytes {
      $0.load(as: UInt16.self)
    }
  }
}
