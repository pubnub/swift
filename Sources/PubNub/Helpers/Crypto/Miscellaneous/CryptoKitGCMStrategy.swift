//
//  CryptoKitGCMStrategy.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import CryptoKit
import Foundation

/// Authenticated decryption backed by CryptoKit.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
struct CryptoKitGCMStrategy: AESGCMStrategy {
  func open(key: Data, nonce: Data, ciphertext: Data, tag: Data) -> Data? {
    guard
      let gcmNonce = try? AES.GCM.Nonce(data: nonce),
      let sealedBox = try? AES.GCM.SealedBox(nonce: gcmNonce, ciphertext: ciphertext, tag: tag)
    else {
      return nil
    }
    return try? AES.GCM.open(sealedBox, using: SymmetricKey(data: key))
  }
}
