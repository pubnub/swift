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
import Foundation
import XCTest

@testable import PubNubSDK

class CryptoTests: XCTestCase {
  func test_EncryptThenDecryptData_ReturnsOriginal() throws {
    let cryptoModule = CryptoModule.legacyCryptoModule(with: "SomeTestString")
    let testMessage = "Test Message To Be Encrypted"

    let testData = try XCTUnwrap(testMessage.data(using: .utf16))
    let encryptedData = try cryptoModule.encrypt(data: testData).get()
    let decryptedData = try cryptoModule.decrypt(data: encryptedData).get()
    let decryptedString = try XCTUnwrap(String(bytes: decryptedData, encoding: .utf16))

    XCTAssertEqual(testMessage, decryptedString)
  }

  func test_EncryptThenDecryptString_ReturnsOriginal() throws {
    let cryptoModule = CryptoModule.legacyCryptoModule(with: "SomeTestString")
    let testMessage = true.description

    let encryptedString = try cryptoModule.encrypt(string: testMessage).get()
    let encryptedStringAsData = try XCTUnwrap(Data(base64Encoded: encryptedString))
    let decryptedString = try cryptoModule.decryptedString(from: encryptedStringAsData).get()

    XCTAssertEqual(testMessage, decryptedString)
  }

  func test_EncryptThenDecryptJSONString_ReturnsOriginal() throws {
    let cryptoModule = CryptoModule.legacyCryptoModule(with: "SomeTestString")
    let testMessage = "Test Message To Be Encrypted"
    let jsonMessage = testMessage.jsonDescription

    let testData = try XCTUnwrap(jsonMessage.data(using: .utf8))
    let encryptedData = try cryptoModule.encrypt(data: testData).get()
    let decryptedData = try cryptoModule.decrypt(data: encryptedData).get()
    let decryptedString = try XCTUnwrap(String(bytes: decryptedData, encoding: .utf8)).reverseJSONDescription

    XCTAssertEqual(testMessage, decryptedString)
  }

  func test_RandomizedIV_ProducesDifferentCiphertextButSamePlaintext() throws {
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

  func test_StaticIVEncryptDecrypt_ReturnsOriginal() throws {
    let cryptoModule = CryptoModule.legacyCryptoModule(with: "MyCoolCipherKey", withRandomIV: false)
    let message = "\"Hello there!\""

    let messageData = try XCTUnwrap(message.data(using: .utf8))
    let encryptedMessage = try cryptoModule.encrypt(data: messageData).get()
    let decrypted = try cryptoModule.decrypt(data: encryptedMessage).get()

    XCTAssertEqual(message, try XCTUnwrap(String(bytes: decrypted, encoding: .utf8)))
  }

  func test_EncryptThenDecryptStringWithRandomIV_ReturnsOriginal() throws {
    let cryptoModule = CryptoModule.legacyCryptoModule(with: "enigma", withRandomIV: true)
    let plainText = "yay!"

    let swiftEncryptedString = try cryptoModule.encrypt(string: plainText).get()
    let swiftEncryptedStringAsData = try XCTUnwrap(Data(base64Encoded: swiftEncryptedString))
    let swiftDecryptedString = try cryptoModule.decryptedString(from: swiftEncryptedStringAsData).get()

    XCTAssertEqual(plainText, swiftDecryptedString)
  }

  func test_DecryptOtherSDKRandomIVPayload_ReturnsOriginal() throws {
    let cryptoModule = CryptoModule.legacyCryptoModule(with: "enigma", withRandomIV: true)
    let plainText = "yay!"
    let otherSDKBase64 = "MTIzNDU2Nzg5MDEyMzQ1NjdnONoCgo0wbuMGGMmfMX0="

    let otherData = try XCTUnwrap(Data(base64Encoded: otherSDKBase64))
    let otherDecrypted = try cryptoModule.decrypt(data: otherData).get()

    XCTAssertEqual(plainText, try XCTUnwrap(String(data: otherDecrypted, encoding: .utf8)))
  }

  func test_DecryptStreamFromOtherSDK_MatchesPlaintext() throws {
    let cryptoModule = CryptoModule.legacyCryptoModule(with: "enigma", withRandomIV: true)
    let ecrypted = try ImportTestResource.importResource("file_upload_sample_encrypted", withExtension: "txt")
    let final = try ImportTestResource.importResource("file_upload_sample", withExtension: "txt")
    let finalString = String(data: final, encoding: .utf8)

    XCTAssertEqual(finalString?.isEmpty, false)

    let outputPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("testFile-\(UUID().uuidString)")

    _ = try cryptoModule.decrypt(
      stream: InputStream(data: ecrypted),
      contentLength: ecrypted.count,
      to: outputPath
    ).get()

    let decryptedFile = try Data(contentsOf: outputPath)

    XCTAssertEqual(finalString, try XCTUnwrap(String(data: decryptedFile, encoding: .utf8)))
  }

  func test_EncryptThenDecryptStream_ReturnsOriginal() throws {
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

    _ = try cryptoModule.decrypt(
      stream: encryptedStreamResult.stream,
      contentLength: encryptedStreamResult.contentLength,
      to: decryptedURL
    ).get()

    let decryptedString = try XCTUnwrap(String(
      data: try Data(contentsOf: decryptedURL),
      encoding: .utf8
    ))

    XCTAssertEqual(plainTextString, decryptedString)
  }

  func test_DecryptStreamFromFileURL_MatchesPlaintext() throws {
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

    _ = try cryptoModule.decryptStream(
      from: encryptedTextURL,
      to: outputPath
    ).get()

    let actualDecryptedContent = try XCTUnwrap(String(
      data: try Data(contentsOf: outputPath),
      encoding: .utf8
    ))

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

  func test_Decrypt_RejectsWrongSizeIV() {
    let cryptor = AESCBCCryptor(key: "enigma")
    let wrongSizeIV = Data(repeating: 0x01, count: kCCBlockSizeAES128 - 1)

    let result = cryptor.decrypt(
      data: EncryptedData(
        metadata: wrongSizeIV,
        data: Data(repeating: 0xAB, count: kCCBlockSizeAES128)
      )
    )

    assertOpaqueDecryptionFailure(result.error)
  }

  func test_Decrypt_RejectsNonBlockAlignedContent() {
    let cryptor = AESCBCCryptor(key: "enigma")
    let wrongSizeData = Data(repeating: 0xAB, count: kCCBlockSizeAES128 + 1)

    let result = cryptor.decrypt(
      data: EncryptedData(
        metadata: Data(repeating: 0x01, count: kCCBlockSizeAES128),
        data: wrongSizeData
      )
    )

    assertOpaqueDecryptionFailure(result.error)
  }

  func test_Decrypt_RejectsEmptyContent() {
    let cryptor = AESCBCCryptor(key: "enigma")
    let emptyData = Data()

    let result = cryptor.decrypt(
      data: EncryptedData(
        metadata: Data(repeating: 0x01, count: kCCBlockSizeAES128),
        data: emptyData
      )
    )

    assertOpaqueDecryptionFailure(result.error)
  }

  func test_DecryptStream_RejectsWrongSizeIV() {
    let cryptor = AESCBCCryptor(key: "enigma")
    let wrongSizeIV = Data(repeating: 0x01, count: kCCBlockSizeAES128 - 1)
    let testData = Data(repeating: 0xAB, count: kCCBlockSizeAES128 * 2)
    let outputPath = URL.randomTempPath

    let encryptedStreamData = EncryptedStreamData(
      stream: .init(data: testData),
      contentLength: testData.count, metadata: wrongSizeIV
    )
    let decryptionResult = cryptor.decrypt(
      data: encryptedStreamData,
      outputPath: outputPath
    )

    assertOpaqueDecryptionFailure(decryptionResult.error)
  }

  func test_DecryptStream_RejectsNonBlockAlignedContent() {
    let cryptor = AESCBCCryptor(key: "enigma")
    let iv = Data(repeating: 0x01, count: kCCBlockSizeAES128)
    let wrongSizeData = Data(repeating: 0xAB, count: kCCBlockSizeAES128 + 1)
    let outputPath = URL.randomTempPath

    let encryptedStreamData = EncryptedStreamData(
      stream: .init(data: wrongSizeData),
      contentLength: wrongSizeData.count, metadata: iv
    )
    let decryptionResult = cryptor.decrypt(
      data: encryptedStreamData,
      outputPath: outputPath
    )

    assertOpaqueDecryptionFailure(decryptionResult.error)
  }

  func test_DecryptStream_RejectsEmptyContent() {
    let cryptor = AESCBCCryptor(key: "enigma")
    let iv = Data(repeating: 0x01, count: kCCBlockSizeAES128)
    let emptyData = Data()

    let outputPath = URL.randomTempPath
    let encryptedStreamData = EncryptedStreamData(stream: .init(data: emptyData), contentLength: emptyData.count, metadata: iv)
    let decryptionResult = cryptor.decrypt(data: encryptedStreamData, outputPath: outputPath)

    assertOpaqueDecryptionFailure(decryptionResult.error)
  }
}

private extension CryptoTests {
  func assertOpaqueDecryptionFailure(
    _ error: Error?,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    guard let pubNubError = error as? PubNubError else {
      return XCTFail("Expected a PubNubError, got \(String(describing: error))", file: file, line: line)
    }

    XCTAssertEqual(pubNubError.reason, .decryptionFailure, file: file, line: line)
    XCTAssertNil(pubNubError.underlying, "Decrypt failures must not expose an underlying status", file: file, line: line)
    XCTAssertEqual(pubNubError.details, ["Decryption failed"], file: file, line: line)
  }
}

private extension Result {
  var error: Error? {
    switch self {
    case .success:
      return nil
    case let .failure(error):
      return error
    }
  }
}

private extension URL {
  static var randomTempPath: URL {
    URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
  }
}
