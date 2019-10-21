//
//  Data+PubNub.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
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
  static let utf8HexDigits: [String.UTF8View.Element] = {
    Array("0123456789ABCDEF".utf8)
  }()

  /// A utf-16 lookup array of all valid Hex characters
  static let utf16HexDigits: [UTF16.CodeUnit] = {
    Array("0123456789ABCDEF".utf16)
  }()

  static let byteMap: [UInt8] = {
    [
      0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, // 01234567
      0x08, 0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 89:;<=>?
      0x00, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x00, // @ABCDEFG
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 // HIJKLMNO
    ]
  }()
}
