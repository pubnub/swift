//
//  Data+CommonCrypto.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
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
