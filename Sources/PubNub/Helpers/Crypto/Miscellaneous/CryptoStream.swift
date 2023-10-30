//
//  CryptoStream.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import CommonCrypto
import Foundation

/// Encrypts of Decrypts a stream of data
public class CryptoStream {
  /// A pointer to the returned CCCryptorRef.
  private var context = UnsafeMutablePointer<CCCryptorRef?>.allocate(capacity: 1)

  /// Create a cryptographic context.
  ///
  /// - Parameters:
  ///   - operation: The operation that will be performed
  ///   - algorithm: The algorithm that will be used
  ///   - options: Optionals values that will be used
  ///   - keyBuffer: Raw key material, length `keyLength` bytes
  ///   - keyLength: Length of key material.
  ///   - ivBuffer: Initialization vector material
  public init(
    operation: CCOperation, algorithm: CCAlgorithm, options: CCOptions,
    keyBuffer: UnsafeRawPointer, keyLength: Int, ivBuffer: UnsafeRawPointer
  ) throws {
    let status = CCCryptorCreate(
      operation,
      algorithm,
      options,
      keyBuffer,
      keyLength,
      ivBuffer,
      context
    )

    if status != kCCSuccess {
      throw CryptoError(from: status)
    }
  }

  //// Process (encrypt, decrypt) some data. The result, if any, is written to a caller-provided buffer.
  ///
  /// This routine can be called multiple times. The caller does not need to align input data lengths to block sizes; input is bufferred as necessary for block ciphers.
  ///
  /// When performing symmetric encryption with block ciphers, and padding is enabled via kCCOptionPKCS7Padding, the total number of bytes provided by all the calls to this function when encrypting can be arbitrary (i.e., the total number of bytes does not have to be block aligned). However if padding is disabled, or when decrypting, the total number of bytes does have to be aligned to the block size; otherwise CCCryptFinal() will return kCCAlignmentError.
  ///
  /// A general rule for the size of the output buffer which must be provided by the caller is that for block ciphers, the output length is never larger than the input length plus the block size. For stream ciphers, the output length is always exactly the same as the input length. See the discussion for CCCryptorGetOutputLength() for more information on this topic.
  ///
  /// Generally, when all data has been processed, call CCCryptorFinal().
  ///
  /// In the following cases, the CCCryptorFinal() is superfluous as it will not yield any data nor return an error: 1. Encrypting or decrypting with a block cipher with padding disabled, when the total amount of data provided to CCCryptorUpdate() is an integral multiple of the block size. 2. Encrypting or decrypting with a stream cipher.
  ///
  /// - Parameters:
  ///   - bufferIn:pointer to input buffer
  ///   - byteCountIn: number of bytes contained in input buffer
  ///   - bufferOut: pointer to output buffer
  ///   - byteCapacityOut: capacity of the output buffer in bytes
  ///   - byteCountOut: on successful completion, the number of bytes written to the output buffer
  /// - Throws: The non-success CCCryptorStatus as a `CryptoError`
  public func update(
    bufferIn: UnsafeRawPointer, byteCountIn: Int,
    bufferOut: UnsafeMutableRawPointer, byteCapacityOut: Int,
    byteCountOut: inout Int
  ) throws {
    let status = CCCryptorUpdate(context.pointee, bufferIn, byteCountIn, bufferOut, byteCapacityOut, &byteCountOut)

    if status != kCCSuccess {
      throw CryptoError(from: status)
    }
  }

  /// Finish an encrypt or decrypt operation, and obtain the (possible) final data output.
  ///
  ///  - Parameters:
  ///    - dataOut: Result is written here. Allocated by caller.
  ///    - maxLength: The size of the `dataOut` buffer in bytes.
  ///    - cryptedBytes: On successful return, the number of bytes written to `dataOut`.
  public func final(_ dataOut: UnsafeMutableRawPointer, maxLength: Int, cryptedBytes: inout Int) throws {
    let status = CCCryptorFinal(context.pointee, dataOut, maxLength, &cryptedBytes)

    if status != kCCSuccess {
      throw CryptoError(from: status)
    }
  }

  /// Determine output buffer size required to process a given input size.
  ///
  /// - Parameters:
  ///   - byteCount:  The length of data which will be crypted
  ///   - isFinal: When 'final' is true, the returned value will indicate the total combined buffer space needed when 'inputLength' bytes are provided to `update()` and then `final()` is called.
  public func getOutputLength(inputLength: Int = 0, isFinal: Bool = true) -> Int {
    return CCCryptorGetOutputLength(context.pointee, inputLength, isFinal)
  }

  deinit {
    let rawStatus = CCCryptorRelease(context.pointee)

    if rawStatus != kCCSuccess {
      PubNub.log.error("CryptoStream CCCryptoRelease failed with status \(rawStatus).")
    }

    context.deallocate()
  }
}
