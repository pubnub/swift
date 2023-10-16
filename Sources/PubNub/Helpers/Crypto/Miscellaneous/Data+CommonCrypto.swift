//
//  Data+CommonCrypto.swift
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

extension Data {
  func crypt(
    operation: CCOperation,
    algorithm: CCAlgorithm,
    options: CCOptions,
    blockSize: Int,
    key: Data,
    initializationVector: Data,
    messageData dataIn: Data,
    dataMovedOut _: Int = 0
  ) throws -> Data {
    return try key.withUnsafeBytes { keyUnsafeRawBufferPointer in
      try dataIn.withUnsafeBytes { dataInUnsafeRawBufferPointer in
        try initializationVector.withUnsafeBytes { ivUnsafeRawBufferPointer in
          let paddingSize = operation == kCCEncrypt ? blockSize : 0
          let dataOutSize: Int = dataIn.count + paddingSize
          let dataOut = UnsafeMutableRawPointer.allocate(byteCount: dataOutSize, alignment: 1)
          defer { dataOut.deallocate() }
          var dataOutMoved: Int = 0
          let status = CCCrypt(
            operation,
            algorithm,
            options,
            keyUnsafeRawBufferPointer.baseAddress,
            key.count,
            ivUnsafeRawBufferPointer.baseAddress,
            dataInUnsafeRawBufferPointer.baseAddress,
            dataIn.count,
            dataOut,
            dataOutSize,
            &dataOutMoved
          )
          if let error = CryptoError(rawValue: status) {
            if error == .bufferTooSmall {
              return try crypt(
                operation: operation, algorithm: algorithm, options: options,
                blockSize: blockSize, key: key,
                initializationVector: initializationVector, messageData: dataIn,
                dataMovedOut: dataOutMoved
              )
            }
            throw error
          }
          return Data(bytes: dataOut, count: dataOutMoved)
        }
      }
    }
  }
}
