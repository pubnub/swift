//
//  Data+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

extension Data {
  /// A Boolean value indicating whether the collection is empty and also not a stringified empty collection
  public var trulyEmpty: Bool {
    return isEmpty || String(bytes: self, encoding: .utf8) == "{}"
  }

  /// A `String` of the Hexidecimal representation of this `Data` object
  public var hexEncodedString: String {
    // Reserver enough memory to hold all the elements
    var chars: [unichar] = []
    chars.reserveCapacity(2 * count)

    // Convert the byte data into its corresponding hex value
    for byte in self {
      chars.append(Data.utf16HexDigits[Int(byte / 16)])
      chars.append(Data.utf16HexDigits[Int(byte % 16)])
    }

    return String(utf16CodeUnits: chars, count: chars.count)
  }

  /// Initialize a `Data` object from a Hexidecimal encoded `String`
  public init?(hexEncodedString: String) {
    // Ensure that we have an even number of Hex values
    guard hexEncodedString.count % 2 == 0 else {
      return nil
    }

    // Get the UTF8 characters of this string
    let chars = Array(hexEncodedString.uppercased().utf8)

    // Keep the bytes in an UInt8 array and later convert it to Data
    var bytes = [UInt8]()
    bytes.reserveCapacity(hexEncodedString.count / 2)

    // It is a lot faster to use a lookup map instead of strtoul
    let map = Data.byteMap

    // Grab two characters at a time, map them and turn it into a byte
    for index in stride(from: 0, to: hexEncodedString.count, by: 2) {
      if !Data.utf8HexDigits.contains(chars[index]) || !Data.utf8HexDigits.contains(chars[index + 1]) {
        return nil
      }
      let firstByte = Int(chars[index] & 0x1F ^ 0x10)
      let secondByte = Int(chars[index + 1] & 0x1F ^ 0x10)
      bytes.append(map[firstByte] << 4 | map[secondByte])
    }

    self.init(bytes)
  }

  /// A utf-8 lookup array of all valid Hex characters
  static let utf8HexDigits: [String.UTF8View.Element] = Array("0123456789ABCDEF".utf8)

  /// A utf-16 lookup array of all valid Hex characters
  static let utf16HexDigits: [UTF16.CodeUnit] = Array("0123456789ABCDEF".utf16)

  static let byteMap: [UInt8] = {
    [
      0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, // 01234567
      0x08, 0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 89:;<=>?
      0x00, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x00, // @ABCDEFG
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 // HIJKLMNO
    ]
  }()

  mutating func append(_ string: String) {
    if let data = string.data(using: .utf8) {
      append(data)
    }
  }
}
