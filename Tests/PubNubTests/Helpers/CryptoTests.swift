//
//  CryptoTests.swift
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

import CommonCrypto
@testable import PubNub
import XCTest

class CryptoTests: XCTestCase {
  func testEncryptDecrypt_Data() {
    let crypto = Crypto(key: "SomeTestString")
    let testMessage = "Test Message To Be Encrypted"
    guard let testData = testMessage.data(using: .utf8) else {
      return XCTFail("Could not create Data from test string")
    }
    guard let encryptedData = try? crypto?.encrypt(utf8Encoded: testData).get() else {
      return XCTFail("Encrypted Data should not be nil")
    }
    guard let decryptedData = try? crypto?.decrypt(encrypted: encryptedData).get() else {
      return XCTFail("Decrypted Data should not be nil")
    }
    let decryptedString = String(bytes: decryptedData, encoding: .utf8)
    XCTAssertEqual(testMessage, decryptedString)
  }

  func testEncryptDecrypt_String() {
    let crypto = Crypto(key: "SomeTestString")
    let testMessage = true.description
    guard let encryptedString = try? crypto?.encrypt(plaintext: testMessage).get() else {
      return XCTFail("Encrypted Data should not be nil")
    }

    guard let decryptedString = try? crypto?.decrypt(base64Encoded: encryptedString).get() else {
      return XCTFail("Decrypted Data should not be nil")
    }
    XCTAssertEqual(testMessage, decryptedString)
  }

  func testEncryptDecrypt_JSONString() {
    //
    let crypto = Crypto(key: "SomeTestString")
    let testMessage = "Test Message To Be Encrypted"
    let jsonMessage = testMessage.jsonDescription
    guard let testData = jsonMessage.data(using: .utf8) else {
      return XCTFail("Could not create Data from test string")
    }
    guard let encryptedData = try? crypto?.encrypt(utf8Encoded: testData).get() else {
      return XCTFail("Encrypted Data should not be nil")
    }
    guard let decryptedData = try? crypto?.decrypt(encrypted: encryptedData).get() else {
      return XCTFail("Decrypted Data should not be nil")
    }
    let decryptedString = String(bytes: decryptedData, encoding: .utf8)?.reverseJSONDescription
    XCTAssertEqual(testMessage, decryptedString)
  }

  func testOtherSDKContractTest() {
    guard let crypto = Crypto(key: "MyCoolCipherKey") else {
      return XCTFail("Could not create crypto instance")
    }

    // Validate common key value
    XCTAssertEqual("NTQ5YzNlNGZjOGEzNDRmZThhNzMxOTQ3ODg4ZTRhMDE=",
                   crypto.key?.base64EncodedString())

    let message = "\"Hello there!\""
    guard let messageData = message.data(using: .utf8) else {
      return XCTFail("Could not create message data")
    }

    do {
      // Validate Common IV
      let ivData = try Crypto.initializationVector.get()
      XCTAssertEqual(ivData.base64EncodedString(), "MDEyMzQ1Njc4OTAxMjM0NQ==")

      let encryptedMessage = try crypto.encrypt(utf8Encoded: messageData).get()

      XCTAssertEqual(encryptedMessage.base64EncodedString(),
                     "Ej+YVJcPtbDrY2fM4OhaLQ==")

      let decrypted = try crypto.decrypt(encrypted: encryptedMessage).get()

      XCTAssertEqual(message,
                     String(bytes: decrypted, encoding: .utf8))
    } catch {
      XCTFail("Crypto failed due to \(error.localizedDescription)")
    }
  }

  // MARK: - Cipher

  func testValidateKeySize() {
    let aesCipher = Crypto.Cipher.aes

    XCTAssertNil(aesCipher.validate(keySize: kCCKeySizeAES128))
  }

  func testValidateKeySize_Failure() {
    let aesCipher = Crypto.Cipher.aes

    XCTAssertNotNil(aesCipher.validate(keySize: 0))
  }

  // MARK: - CryptoError

  func testRawValue_Nil() {
    XCTAssertNil(CryptoError(rawValue: CCCryptorStatus(kCCSuccess)))
  }

  func testRawValue_IllegalParameter() {
    XCTAssertEqual(CryptoError.illegalParameter,
                   CryptoError(rawValue: CCCryptorStatus(kCCParamError)))
  }

  func testRawValue_BufferTooSmall() {
    XCTAssertEqual(CryptoError.bufferTooSmall,
                   CryptoError(rawValue: CCCryptorStatus(kCCBufferTooSmall)))
  }

  func testRawValue_MemoryFailure() {
    XCTAssertEqual(CryptoError.memoryFailure,
                   CryptoError(rawValue: CCCryptorStatus(kCCMemoryFailure)))
  }

  func testRawValue_AlignmentError() {
    XCTAssertEqual(CryptoError.alignmentError,
                   CryptoError(rawValue: CCCryptorStatus(kCCAlignmentError)))
  }

  func testRawValue_DecodeError() {
    XCTAssertEqual(CryptoError.decodeError,
                   CryptoError(rawValue: CCCryptorStatus(kCCDecodeError)))
  }

  func testRawValue_Overflow() {
    XCTAssertEqual(CryptoError.overflow,
                   CryptoError(rawValue: CCCryptorStatus(kCCOverflow)))
  }

  func testRawValue_RNGFailure() {
    XCTAssertEqual(CryptoError.rngFailure,
                   CryptoError(rawValue: CCCryptorStatus(kCCRNGFailure)))
  }

  func testRawValue_CallSequenceError() {
    XCTAssertEqual(CryptoError.callSequenceError,
                   CryptoError(rawValue: CCCryptorStatus(kCCCallSequenceError)))
  }

  func testRawValue_KeySizeError() {
    XCTAssertEqual(CryptoError.keySizeError,
                   CryptoError(rawValue: CCCryptorStatus(kCCKeySizeError)))
  }

  func testRawValue_Unimplemented() {
    XCTAssertEqual(CryptoError.unimplemented,
                   CryptoError(rawValue: CCCryptorStatus(kCCUnimplemented)))
  }

  func testRawValue_UnspecifiedError() {
    XCTAssertEqual(CryptoError.unspecifiedError,
                   CryptoError(rawValue: CCCryptorStatus(kCCUnspecifiedError)))
  }

  func testRawValue_Unknown() {
    XCTAssertEqual(CryptoError.unknown,
                   CryptoError(rawValue: CCCryptorStatus(1_240_124)))
  }
}
