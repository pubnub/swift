//
//  01-misc.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

// snippet.import
import PubNubSDK
import Foundation

// snippet.end

// snippet.pubnub
// Initializes a PubNub object with the configuration
let pubnub = PubNub(
  configuration: PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "myUniqueUserId"
  )
)

// snippet.end

// snippet.encrypt-data
func encryptDataExample() throws {
  // Initialize the crypto module with a cipher key
  let cryptoModule = CryptoModule.aesCbcCryptoModule(with: "pubnubenigma")
  // The message to encrypt
  let messageToEncrypt = "this is message".data(using: .utf8) ?? Data()
  // Encrypt the message
  let encryptedMessage: Data = try cryptoModule.encrypt(data: messageToEncrypt).get()
  // Proceed with encrypted message
}
// snippet.end

// snippet.decrypt-data
func decryptDataExample() throws {
  // Initialize the crypto module with a cipher key
  let cryptoModule = CryptoModule.aesCbcCryptoModule(with: "pubnubenigma")
  // Encrypt a message to demonstrate its decryption later
  let messageToEncrypt = "this is message".data(using: .utf8) ?? Data()
  let encryptedMessage = try cryptoModule.encrypt(data: messageToEncrypt).get()
  // Decrypt data
  let decryptedData: Data = try cryptoModule.decrypt(data: encryptedMessage).get()
  // Proceed with decrypted data
}
// snippet.end

// snippet.pubnub-disconnect
pubnub.disconnect()
// snippet.end

// snippet.pubnub-reconnect
pubnub.reconnect()
// snippet.end
