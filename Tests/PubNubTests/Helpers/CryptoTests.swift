//
//  CryptoTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import CommonCrypto
@testable import PubNub
import XCTest

class CryptoTests: XCTestCase {
  func testEncryptDecrypt_Data() {
    let cryptoModule = CryptoModule.legacyCryptoModule(with: "SomeTestString")
    let testMessage = "Test Message To Be Encrypted"
    
    guard let testData = testMessage.data(using: .utf16) else {
      return XCTFail("Could not create Data from test string")
    }
    guard let encryptedData = try? cryptoModule.encrypt(data: testData).get() else {
      return XCTFail("Encrypted Data should not be nil")
    }
    guard let decryptedData = try? cryptoModule.decrypt(data: encryptedData).get() else {
      return XCTFail("Decrypted Data should not be nil")
    }
    let decryptedString = String(
      bytes: decryptedData,
      encoding: .utf16
    )
    XCTAssertEqual(testMessage, decryptedString)
  }

  func testEncryptDecrypt_String() {
    let cryptoModule = CryptoModule.legacyCryptoModule(with: "SomeTestString")
    let testMessage = true.description
    
    guard let encryptedString = try? cryptoModule.encrypt(string: testMessage).get() else {
      return XCTFail("Encrypted Data should not be nil")
    }
    guard
      let encryptedStringAsData = Data(base64Encoded: encryptedString),
      let decryptedString = try? cryptoModule.decryptedString(from: encryptedStringAsData).get()
    else {
      return XCTFail("Decrypted Data should not be nil")
    }
    XCTAssertEqual(testMessage, decryptedString)
  }

  func testEncryptDecrypt_JSONString() {
    let cryptoModule = CryptoModule.legacyCryptoModule(with: "SomeTestString")
    let testMessage = "Test Message To Be Encrypted"
    let jsonMessage = testMessage.jsonDescription
    
    guard let testData = jsonMessage.data(using: .utf8) else {
      return XCTFail("Could not create Data from test string")
    }
    guard let encryptedData = try? cryptoModule.encrypt(data: testData).get() else {
      return XCTFail("Encrypted Data should not be nil")
    }
    guard let decryptedData = try? cryptoModule.decrypt(data: encryptedData).get() else {
      return XCTFail("Decrypted Data should not be nil")
    }
    let decryptedString = String(
      bytes: decryptedData,
      encoding: .utf8
    )?.reverseJSONDescription
    
    XCTAssertEqual(testMessage, decryptedString)
  }

  func testDefaultRandomizedIVEncryptDecrypt() {
    let testMessage = "Test Message To Be Encrypted"
    let cryptoModule = CryptoModule.legacyCryptoModule(with: "MyCoolCipherKey")
    
    guard let encryptedString1 = try? cryptoModule.encrypt(string: testMessage).get() else {
      return XCTFail("Encrypted Data should not be nil")
    }
    guard let encryptedString2 = try? cryptoModule.encrypt(string: testMessage).get() else {
      return XCTFail("Encrypted Data should not be nil")
    }
    guard let encryptedString1Data = Data(base64Encoded: encryptedString1) else {
      return XCTFail("Cannot create Data from Base-64 encoded \(encryptedString1)")
    }
    guard let decryptedString1 = try? cryptoModule.decryptedString(from: encryptedString1Data).get() else {
      return XCTFail("Decrypted Data should not be nil")
    }
    guard let encryptedString2Data = Data(base64Encoded: encryptedString2) else {
      return XCTFail("Cannot create Data from Base-64 encoded \(encryptedString2)")
    }
    guard let decryptedString2 = try? cryptoModule.decryptedString(from: encryptedString2Data).get() else {
      return XCTFail("Decrypted Data should not be nil")
    }
    
    XCTAssertNotEqual(encryptedString1, encryptedString2)
    XCTAssertEqual(decryptedString1, decryptedString2)
    XCTAssertEqual(testMessage, decryptedString1)
  }

  func testOtherSDKContractTest() {
    let cryptoModule = CryptoModule.legacyCryptoModule(with: "MyCoolCipherKey", withRandomIV: false)
    let message = "\"Hello there!\""
    
    guard let messageData = message.data(using: .utf8) else {
      return XCTFail("Could not create message data")
    }

    do {
      let encryptedMessage = try cryptoModule.encrypt(data: messageData).get()
      let decrypted = try cryptoModule.decrypt(data: encryptedMessage).get()
      XCTAssertEqual(message, String(bytes: decrypted, encoding: .utf8))
    } catch {
      XCTFail("Crypto failed due to \(error)")
    }
  }

  func testOtherSDK_RandomIV() {
    let cryptoModule = CryptoModule.legacyCryptoModule(with: "enigma", withRandomIV: true)
    let plainText = "yay!"
    let otherSDKBase64 = "MTIzNDU2Nzg5MDEyMzQ1NjdnONoCgo0wbuMGGMmfMX0="

    do {
      let swiftEncryptedString = try cryptoModule.encrypt(string: plainText).get()
      let swiftEncryptedStringAsData = Data(base64Encoded: swiftEncryptedString)!
      let swiftDecryptedString = try cryptoModule.decryptedString(from: swiftEncryptedStringAsData).get()

      XCTAssertEqual(plainText, swiftDecryptedString)

      guard let otherData = Data(base64Encoded: otherSDKBase64) else {
        return XCTFail("Could not create data from Base64")
      }
      let otherDecrypted = try cryptoModule.decrypt(data: otherData).get()
      XCTAssertEqual(plainText, String(data: otherDecrypted, encoding: .utf8))
    } catch {
      XCTFail("Crypto failed due to \(error)")
    }
  }

  func testStreamOtherSDK() {
    let cryptoModule = CryptoModule.legacyCryptoModule(
      with: "enigma",
      withRandomIV: true
    )
    do {
      let ecrypted = try ImportTestResource.importResource("file_upload_sample_encrypted", withExtension: "txt")
      let final = try ImportTestResource.importResource("file_upload_sample", withExtension: "txt")
      let finalString = String(data: final, encoding: .utf8)

      XCTAssertEqual(finalString?.isEmpty, false)

      let outputPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("testFile")
      // Purges existing item (if any)
      try? FileManager.default.removeItem(at: outputPath)

      cryptoModule.decrypt(
        stream: InputStream(data: ecrypted),
        contentLength: ecrypted.count,
        to: outputPath
      )
      
      let decrypted = try Data(contentsOf: outputPath)
      XCTAssertEqual(finalString, String(data: decrypted, encoding: .utf8))
      
    } catch {
      XCTFail("Could not write to temp file \(error)")
    }
  }

  func testStreamEncryptDecrypt() {
    let cryptoModule = CryptoModule.legacyCryptoModule(
      with: "enigma",
      withRandomIV: true
    )
    do {
      guard let plainTextURL = ImportTestResource.testsBundle.url(
        forResource: "file_upload_sample", withExtension: "txt"
      ) else {
        return XCTFail("Could not get the URL for resource")
      }
      guard let plainTextString = String(data: try Data(contentsOf: plainTextURL), encoding: .utf8) else {
        return XCTFail("Could not create string from data")
      }

      XCTAssertEqual(plainTextString.isEmpty, false)

      let data = try Data(contentsOf: plainTextURL)
      let inputStream = InputStream(data: data)
      
      let encryptedStreamResult = try cryptoModule.encrypt(
        stream: inputStream,
        contentLength: data.count
      ).get() as! MultipartInputStream

      let decryptedURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("decryptedStream")
      try? FileManager.default.removeItem(at: decryptedURL)
      
      cryptoModule.decrypt(
        stream: encryptedStreamResult,
        contentLength: encryptedStreamResult.length,
        to: decryptedURL
      )
      
      let decryptedString = String(data: try Data(contentsOf: decryptedURL), encoding: .utf8)
      XCTAssertEqual(plainTextString, decryptedString)

    } catch {
      XCTFail("Could not write to temp file \(error)")
    }
  }

  // MARK: - CryptoError

  func testRawValue_Nil() {
    XCTAssertNil(CryptoError(rawValue: CCCryptorStatus(kCCSuccess)))
  }

  func testRawValue_IllegalParameter() {
    XCTAssertEqual(
      CryptoError.illegalParameter,
      CryptoError(rawValue: CCCryptorStatus(kCCParamError))
    )
  }

  func testRawValue_BufferTooSmall() {
    XCTAssertEqual(
      CryptoError.bufferTooSmall,
      CryptoError(rawValue: CCCryptorStatus(kCCBufferTooSmall))
    )
  }

  func testRawValue_MemoryFailure() {
    XCTAssertEqual(
      CryptoError.memoryFailure,
      CryptoError(rawValue: CCCryptorStatus(kCCMemoryFailure))
    )
  }

  func testRawValue_AlignmentError() {
    XCTAssertEqual(
      CryptoError.alignmentError,
      CryptoError(rawValue: CCCryptorStatus(kCCAlignmentError))
    )
  }

  func testRawValue_DecodeError() {
    XCTAssertEqual(
      CryptoError.decodeError,
      CryptoError(rawValue: CCCryptorStatus(kCCDecodeError))
    )
  }

  func testRawValue_Overflow() {
    XCTAssertEqual(
      CryptoError.overflow,
      CryptoError(rawValue: CCCryptorStatus(kCCOverflow))
    )
  }

  func testRawValue_RNGFailure() {
    XCTAssertEqual(
      CryptoError.rngFailure,
      CryptoError(rawValue: CCCryptorStatus(kCCRNGFailure))
    )
  }

  func testRawValue_CallSequenceError() {
    XCTAssertEqual(
      CryptoError.callSequenceError,
      CryptoError(rawValue: CCCryptorStatus(kCCCallSequenceError))
    )
  }

  func testRawValue_KeySizeError() {
    XCTAssertEqual(
      CryptoError.keySizeError,
      CryptoError(rawValue: CCCryptorStatus(kCCKeySizeError))
    )
  }

  func testRawValue_Unimplemented() {
    XCTAssertEqual(
      CryptoError.unimplemented,
      CryptoError(rawValue: CCCryptorStatus(kCCUnimplemented))
    )
  }

  func testRawValue_UnspecifiedError() {
    XCTAssertEqual(
      CryptoError.unspecifiedError,
      CryptoError(rawValue: CCCryptorStatus(kCCUnspecifiedError))
    )
  }

  func testRawValue_Unknown() {
    XCTAssertEqual(
      CryptoError.unknown,
      CryptoError(rawValue: CCCryptorStatus(1_240_124))
    )
  }
}
