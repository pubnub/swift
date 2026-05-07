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
import XCTest

@testable import PubNubSDK

class CryptoTests: XCTestCase {
  func test_CryptoModule_EncryptThenDecryptData_ReturnsOriginal() throws {
    let cryptoModule = CryptoModule.legacyCryptoModule(with: "SomeTestString")
    let testMessage = "Test Message To Be Encrypted"

    let testData = try XCTUnwrap(testMessage.data(using: .utf16))
    let encryptedData = try cryptoModule.encrypt(data: testData).get()
    let decryptedData = try cryptoModule.decrypt(data: encryptedData).get()
    let decryptedString = String(bytes: decryptedData, encoding: .utf16)

    XCTAssertEqual(testMessage, decryptedString)
  }

  func test_CryptoModule_EncryptThenDecryptString_ReturnsOriginal() throws {
    let cryptoModule = CryptoModule.legacyCryptoModule(with: "SomeTestString")
    let testMessage = true.description

    let encryptedString = try cryptoModule.encrypt(string: testMessage).get()
    let encryptedStringAsData = try XCTUnwrap(Data(base64Encoded: encryptedString))
    let decryptedString = try cryptoModule.decryptedString(from: encryptedStringAsData).get()

    XCTAssertEqual(testMessage, decryptedString)
  }

  func test_CryptoModule_EncryptThenDecryptJSONString_ReturnsOriginal() throws {
    let cryptoModule = CryptoModule.legacyCryptoModule(with: "SomeTestString")
    let testMessage = "Test Message To Be Encrypted"
    let jsonMessage = testMessage.jsonDescription

    let testData = try XCTUnwrap(jsonMessage.data(using: .utf8))
    let encryptedData = try cryptoModule.encrypt(data: testData).get()
    let decryptedData = try cryptoModule.decrypt(data: encryptedData).get()
    let decryptedString = String(bytes: decryptedData, encoding: .utf8)?.reverseJSONDescription

    XCTAssertEqual(testMessage, decryptedString)
  }

  func test_CryptoModule_RandomizedIV_ProducesDifferentCiphertextButSamePlaintext() throws {
    let testMessage = "Test Message To Be Encrypted"
    let cryptoModule = CryptoModule.legacyCryptoModule(with: "MyCoolCipherKey")

    let encryptedString1 = try cryptoModule.encrypt(string: testMessage).get()
    let encryptedString2 = try cryptoModule.encrypt(string: testMessage).get()
    let encryptedString1Data = try XCTUnwrap(Data(base64Encoded: encryptedString1))
    let decryptedString1 = try cryptoModule.decryptedString(from: encryptedString1Data).get()
    let encryptedString2Data = try XCTUnwrap(Data(base64Encoded: encryptedString2))
    let decryptedString2 = try cryptoModule.decryptedString(from: encryptedString2Data).get()

    XCTAssertNotEqual(encryptedString1, encryptedString2)
    XCTAssertEqual(decryptedString1, decryptedString2)
    XCTAssertEqual(testMessage, decryptedString1)
  }

  func test_CryptoModule_StaticIVEncryptDecrypt_ReturnsOriginal() throws {
    let cryptoModule = CryptoModule.legacyCryptoModule(with: "MyCoolCipherKey", withRandomIV: false)
    let message = "\"Hello there!\""

    let messageData = try XCTUnwrap(message.data(using: .utf8))
    let encryptedMessage = try cryptoModule.encrypt(data: messageData).get()
    let decrypted = try cryptoModule.decrypt(data: encryptedMessage).get()
    XCTAssertEqual(message, String(bytes: decrypted, encoding: .utf8))
  }

  func test_CryptoModule_DecryptOtherSDKRandomIVPayload_ReturnsOriginal() throws {
    let cryptoModule = CryptoModule.legacyCryptoModule(with: "enigma", withRandomIV: true)
    let plainText = "yay!"
    let otherSDKBase64 = "MTIzNDU2Nzg5MDEyMzQ1NjdnONoCgo0wbuMGGMmfMX0="

    let swiftEncryptedString = try cryptoModule.encrypt(string: plainText).get()
    let swiftEncryptedStringAsData = try XCTUnwrap(Data(base64Encoded: swiftEncryptedString))
    let swiftDecryptedString = try cryptoModule.decryptedString(from: swiftEncryptedStringAsData).get()

    XCTAssertEqual(plainText, swiftDecryptedString)

    let otherData = try XCTUnwrap(Data(base64Encoded: otherSDKBase64))
    let otherDecrypted = try cryptoModule.decrypt(data: otherData).get()

    XCTAssertEqual(plainText, String(data: otherDecrypted, encoding: .utf8))
  }

  func test_CryptoModule_DecryptStreamFromOtherSDK_MatchesPlaintext() throws {
    let cryptoModule = CryptoModule.legacyCryptoModule(with: "enigma", withRandomIV: true)
    let ecrypted = try ImportTestResource.importResource("file_upload_sample_encrypted", withExtension: "txt")
    let final = try ImportTestResource.importResource("file_upload_sample", withExtension: "txt")
    let finalString = String(data: final, encoding: .utf8)

    XCTAssertEqual(finalString?.isEmpty, false)

    let outputPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("testFile-\(UUID().uuidString)")
    try? FileManager.default.removeItem(at: outputPath)

    cryptoModule.decrypt(
      stream: InputStream(data: ecrypted),
      contentLength: ecrypted.count,
      to: outputPath
    )

    let decrypted = try Data(contentsOf: outputPath)

    XCTAssertEqual(finalString, String(data: decrypted, encoding: .utf8))
  }

  func test_CryptoModule_EncryptThenDecryptStream_ReturnsOriginal() throws {
    let cryptoModule = CryptoModule.legacyCryptoModule(
      with: "enigma",
      withRandomIV: true
    )

    let plainTextURL = try XCTUnwrap(
      ImportTestResource.testsBundle.url(
        forResource: "file_upload_sample",
        withExtension: "txt"
      )
    )

    let plainTextString = try XCTUnwrap(
      String(
        data: try Data(contentsOf: plainTextURL),
        encoding: .utf8
      )
    )

    XCTAssertEqual(plainTextString.isEmpty, false)

    let data = try Data(contentsOf: plainTextURL)
    let inputStream = InputStream(data: data)
    let encryptedStreamResult = try cryptoModule.encrypt(stream: inputStream, contentLength: data.count).get()

    let decryptedURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("decryptedStream-\(UUID().uuidString)")
    try? FileManager.default.removeItem(at: decryptedURL)

    cryptoModule.decrypt(
      stream: encryptedStreamResult.stream,
      contentLength: encryptedStreamResult.contentLength,
      to: decryptedURL
    )

    let decryptedString = String(
      data: try Data(contentsOf: decryptedURL),
      encoding: .utf8
    )

    XCTAssertEqual(plainTextString, decryptedString)
  }

  func test_CryptoModule_DecryptStreamFromFileURL_MatchesPlaintext() throws {
    let encryptedTextURL = try XCTUnwrap(ImportTestResource.testsBundle.url(
      forResource: "file_upload_sample_encrypted",
      withExtension: "txt"
    ))

    let plainTextURL = try XCTUnwrap(ImportTestResource.testsBundle.url(
      forResource: "file_upload_sample",
      withExtension: "txt"
    ))

    let expectedDecryptedContent = try XCTUnwrap(String(
      data: try Data(contentsOf: plainTextURL),
      encoding: .utf8
    ))

    let cryptoModule = CryptoModule.aesCbcCryptoModule(with: "enigma", withRandomIV: true)
    let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
    let outputPath = temporaryDirectory.appendingPathComponent("decryptedStream-\(UUID().uuidString)")

    try? FileManager.default.removeItem(at: outputPath)

    cryptoModule.decryptStream(
      from: encryptedTextURL,
      to: outputPath
    )

    let actualDecryptedContent = String(
      data: try Data(contentsOf: outputPath),
      encoding: .utf8
    )

    XCTAssertEqual(
      expectedDecryptedContent,
      actualDecryptedContent
    )
  }

  // MARK: - CryptoError

  func test_CryptoError_SuccessRawValue_ReturnsNil() {
    XCTAssertNil(CryptoError(rawValue: CCCryptorStatus(kCCSuccess)))
  }

  func test_CryptoError_ParamErrorRawValue_ReturnsIllegalParameter() {
    XCTAssertEqual(
      CryptoError.illegalParameter,
      CryptoError(rawValue: CCCryptorStatus(kCCParamError))
    )
  }

  func test_CryptoError_BufferTooSmallRawValue_ReturnsBufferTooSmall() {
    XCTAssertEqual(
      CryptoError.bufferTooSmall,
      CryptoError(rawValue: CCCryptorStatus(kCCBufferTooSmall))
    )
  }

  func test_CryptoError_MemoryFailureRawValue_ReturnsMemoryFailure() {
    XCTAssertEqual(
      CryptoError.memoryFailure,
      CryptoError(rawValue: CCCryptorStatus(kCCMemoryFailure))
    )
  }

  func test_CryptoError_AlignmentErrorRawValue_ReturnsAlignmentError() {
    XCTAssertEqual(
      CryptoError.alignmentError,
      CryptoError(rawValue: CCCryptorStatus(kCCAlignmentError))
    )
  }

  func test_CryptoError_DecodeErrorRawValue_ReturnsDecodeError() {
    XCTAssertEqual(
      CryptoError.decodeError,
      CryptoError(rawValue: CCCryptorStatus(kCCDecodeError))
    )
  }

  func test_CryptoError_OverflowRawValue_ReturnsOverflow() {
    XCTAssertEqual(
      CryptoError.overflow,
      CryptoError(rawValue: CCCryptorStatus(kCCOverflow))
    )
  }

  func test_CryptoError_RNGFailureRawValue_ReturnsRNGFailure() {
    XCTAssertEqual(
      CryptoError.rngFailure,
      CryptoError(rawValue: CCCryptorStatus(kCCRNGFailure))
    )
  }

  func test_CryptoError_CallSequenceErrorRawValue_ReturnsCallSequenceError() {
    XCTAssertEqual(
      CryptoError.callSequenceError,
      CryptoError(rawValue: CCCryptorStatus(kCCCallSequenceError))
    )
  }

  func test_CryptoError_KeySizeErrorRawValue_ReturnsKeySizeError() {
    XCTAssertEqual(
      CryptoError.keySizeError,
      CryptoError(rawValue: CCCryptorStatus(kCCKeySizeError))
    )
  }

  func test_CryptoError_UnimplementedRawValue_ReturnsUnimplemented() {
    XCTAssertEqual(
      CryptoError.unimplemented,
      CryptoError(rawValue: CCCryptorStatus(kCCUnimplemented))
    )
  }

  func test_CryptoError_UnspecifiedErrorRawValue_ReturnsUnspecifiedError() {
    XCTAssertEqual(
      CryptoError.unspecifiedError,
      CryptoError(rawValue: CCCryptorStatus(kCCUnspecifiedError))
    )
  }

  func test_CryptoError_UnknownRawValue_ReturnsUnknown() {
    XCTAssertEqual(
      CryptoError.unknown,
      CryptoError(rawValue: CCCryptorStatus(1_240_124))
    )
  }
}
