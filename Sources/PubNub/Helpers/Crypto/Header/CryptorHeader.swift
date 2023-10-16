//
//  CryptorHeader.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2023 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
