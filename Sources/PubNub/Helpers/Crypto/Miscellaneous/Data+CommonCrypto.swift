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

/// Helpers shared by the AES-CBC decrypt paths
enum CBCDecrypt {
  /// A single, uniform decryption failure that never exposes an underlying decryption error.
  static var failure: PubNubError {
    PubNubError(.decryptionFailure, additional: ["Decryption failed"])
  }

  /// Returns `true` when the IV and ciphertext are valid inputs for an AES-CBC decrypt.
  ///
  /// Rejects a wrong-length IV, empty ciphertext, and ciphertext that is not a whole number of
  /// blocks — preventing invalid input from reaching `CCCrypt` where the status would differ.
  static func isValidInput(iv: Data, cipherText: Data, blockSize: Int) -> Bool {
    iv.count == blockSize && !cipherText.isEmpty && cipherText.count % blockSize == 0
  }
}

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
