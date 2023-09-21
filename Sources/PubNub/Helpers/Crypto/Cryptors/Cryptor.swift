//
//  CryptoAlgorithm.swift
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

public struct EncryptedData {
  let metadata: Data
  let data: Data
}

public struct EncryptedStreamData {
  let stream: InputStream
  let contentLength: Int
  let metadata: Data
}

public typealias CryptorId = [UInt8]

public protocol Cryptor {
  var id: CryptorId { get }
  
  func encrypt(data: Data) -> Result<EncryptedData, Error>
  func decrypt(data: EncryptedData) -> Result<Data, Error>
  func encrypt(stream: InputStream, contentLength: Int) -> Result<EncryptedStreamData, Error>
  func decrypt(data: EncryptedStreamData, outputPath: URL) -> Result<InputStream, Error>
}
