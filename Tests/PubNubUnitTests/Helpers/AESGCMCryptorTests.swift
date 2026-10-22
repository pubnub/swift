//
//  AESGCMCryptorTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import CryptoKit
import Foundation
import XCTest

@testable import PubNubSDK

class AESGCMCryptorTests: XCTestCase {
  private let cipherKey = "enigma"

  // MARK: - Raw key

  func test_Decrypt_MatchesPublishedAES256Vectors() throws {
    struct Vector {
      let key: String
      let nonce: String
      let plaintext: String
      let ciphertext: String
      let tag: String
    }
    let vectors = [
      Vector(
        key: String(repeating: "00", count: 32),
        nonce: String(repeating: "00", count: 12),
        plaintext: "",
        ciphertext: "",
        tag: "530f8afbc74536b9a963b4f1c4cb738b"
      ),
      Vector(
        key: String(repeating: "00", count: 32),
        nonce: String(repeating: "00", count: 12),
        plaintext: String(repeating: "00", count: 16),
        ciphertext: "cea7403d4d606b6e074ec5d3baf39d18",
        tag: "d0d1c8a799996bf0265b98b5d48ab919"
      ),
      Vector(
        key: "feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308",
        nonce: "cafebabefacedbaddecaf888",
        plaintext: "d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a72"
          + "1c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b391aafd255",
        ciphertext: "522dc1f099567d07f47f37a32a84427d643a8cdcbfe5c0c97598a2bd2555d1aa"
          + "8cb08e48590dbb3da7b08b1056828838c5f61e6393ba7a0abcc9f662898015ad",
        tag: "b094dac5d93471bdec1a502270e3cc6c"
      )
    ]

    for vector in vectors {
      let cryptor = AESGCMCryptor(rawKey: try hex(vector.key))
      let result = cryptor.decrypt(data: EncryptedData(
        metadata: try hex(vector.nonce) + hex(vector.tag),
        data: try hex(vector.ciphertext)
      ))
      XCTAssertEqual(try result.get(), try hex(vector.plaintext))
    }
  }

  func test_Decrypt_RoundTripsCryptoKitOutput_ForAllLengths() throws {
    let key = SymmetricKey(size: .bits256)
    let cryptor = AESGCMCryptor(rawKey: key.withUnsafeBytes { Data($0) })

    for length in [0, 1, 15, 16, 17, 31, 32, 33, 255, 1_000, 70_000] {
      let plaintext = Data((0..<length).map { _ in UInt8.random(in: 0...255) })
      let box = try AES.GCM.seal(plaintext, using: key)
      let result = cryptor.decrypt(data: EncryptedData(metadata: Data(box.nonce) + box.tag, data: box.ciphertext))

      XCTAssertEqual(try result.get(), plaintext, "length: \(length)")
    }
  }

  func test_Decrypt_RejectsAnyModifiedInput() throws {
    let key = Data(repeating: 0x42, count: 32)
    let nonce = Data(repeating: 0x07, count: 12)
    let box = try AES.GCM.seal(
      Data("authenticated".utf8),
      using: SymmetricKey(data: key),
      nonce: AES.GCM.Nonce(data: nonce)
    )
    let metadata = nonce + box.tag

    let valid = AESGCMCryptor(rawKey: key).decrypt(data: EncryptedData(metadata: metadata, data: box.ciphertext))
    XCTAssertEqual(try valid.get(), Data("authenticated".utf8))

    let failures = [
      AESGCMCryptor(rawKey: key).decrypt(data: EncryptedData(metadata: metadata, data: flipped(box.ciphertext))),
      AESGCMCryptor(rawKey: key).decrypt(data: EncryptedData(metadata: flipped(metadata), data: box.ciphertext)),
      AESGCMCryptor(rawKey: flipped(key)).decrypt(data: EncryptedData(metadata: metadata, data: box.ciphertext))
    ]
    for failure in failures {
      assertOpaqueDecryptionFailure(failure.error)
    }
  }

  func test_Decrypt_RejectsRawKeysOfWrongLength() throws {
    let nonce = randomNonce()
    let box = try seal(Data("payload".utf8), nonce: nonce)
    let input = EncryptedData(metadata: nonce + box.tag, data: box.ciphertext)

    for length in [0, 16, 24, 31, 33] {
      assertOpaqueDecryptionFailure(AESGCMCryptor(rawKey: Data(count: length)).decrypt(data: input).error)
    }
  }

  func test_StringInitializer_ForwardsToRawKeyInitializer() {
    let derived = CryptorUtils.SHA256.hash(from: Data(cipherKey.utf8))

    XCTAssertEqual(AESGCMCryptor(key: cipherKey), AESGCMCryptor(rawKey: derived))
  }

  // MARK: - Cryptor

  func test_Decrypt_RejectsInvalidShapes() throws {
    let nonce = randomNonce()
    let box = try seal(Data("payload".utf8), nonce: nonce)
    let cryptor = AESGCMCryptor(key: cipherKey)
    let metadata = nonce + box.tag

    let invalidInputs = [
      EncryptedData(metadata: Data(metadata.prefix(27)), data: box.ciphertext),
      EncryptedData(metadata: metadata + Data([0x00]), data: box.ciphertext),
      EncryptedData(metadata: nonce, data: box.ciphertext + box.tag),
      EncryptedData(metadata: Data(), data: box.ciphertext),
      EncryptedData(metadata: flipped(metadata), data: box.ciphertext),
      EncryptedData(metadata: metadata, data: flipped(box.ciphertext))
    ]
    for input in invalidInputs {
      assertOpaqueDecryptionFailure(cryptor.decrypt(data: input).error)
    }
  }

  func test_Decrypt_RejectsWrongKey() throws {
    let nonce = randomNonce()
    let box = try seal(Data("payload".utf8), nonce: nonce)
    let cryptor = AESGCMCryptor(key: "not-the-key")

    let result = cryptor.decrypt(data: EncryptedData(metadata: nonce + box.tag, data: box.ciphertext))

    assertOpaqueDecryptionFailure(result.error)
  }

  func test_Encrypt_IsNotSupported() {
    let cryptor = AESGCMCryptor(key: cipherKey)

    for error in [
      cryptor.encrypt(data: Data("payload".utf8)).error,
      cryptor.encrypt(stream: InputStream(data: Data("payload".utf8)), contentLength: 7).error
    ] {
      XCTAssertEqual((error as? PubNubError)?.reason, .encryptionFailure)
    }
  }

  func test_Equality_DependsOnKey() {
    XCTAssertEqual(AESGCMCryptor(key: "a"), AESGCMCryptor(key: "a"))
    XCTAssertNotEqual(AESGCMCryptor(key: "a"), AESGCMCryptor(key: "b"))
    XCTAssertEqual(AESGCMCryptor(key: "a").id, [0x41, 0x43, 0x47, 0x4D])
  }

  // MARK: - CryptoModule

  func test_Module_DecryptsGCMPayload_WithBothFactories() throws {
    let plaintext = Data("Hello from AES-GCM".utf8)
    let payload = try makePayload(plaintext)

    for module in [
      CryptoModule.aesCbcCryptoModule(with: cipherKey),
      CryptoModule.legacyCryptoModule(with: cipherKey)
    ] {
      XCTAssertEqual(try module.decrypt(data: payload).get(), plaintext)
      XCTAssertEqual(try module.decryptedString(from: payload).get(), "Hello from AES-GCM")
    }
  }

  func test_Module_DecryptsEmptyPlaintext() throws {
    let payload = try makePayload(Data())
    let module = CryptoModule.aesCbcCryptoModule(with: cipherKey)

    XCTAssertEqual(try module.decrypt(data: payload).get(), Data())
    XCTAssertEqual(try module.decryptedString(from: payload).get(), "")
  }

  func test_Module_DecryptsEmptyPlaintext_ForCBC() throws {
    let cryptor = AESCBCCryptor(key: cipherKey)
    let encrypted = try cryptor.encrypt(data: Data()).get()
    let payload = CryptorHeader.v1(cryptorId: cryptor.id, dataLength: encrypted.metadata.count).toData()
      + encrypted.metadata
      + encrypted.data

    XCTAssertEqual(try CryptoModule.aesCbcCryptoModule(with: cipherKey).decrypt(data: payload).get(), Data())
  }

  func test_Module_StillRejectsEmptyInput() {
    let module = CryptoModule.aesCbcCryptoModule(with: cipherKey)

    XCTAssertEqual((module.decrypt(data: Data()).error as? PubNubError)?.reason, .decryptionFailure)
  }

  func test_Module_RejectsTamperedPayload() throws {
    let payload = try makePayload(Data("Hello from AES-GCM".utf8))
    let module = CryptoModule.aesCbcCryptoModule(with: cipherKey)

    // Header, nonce and tag occupy the first bytes, so flip a byte of every region in turn
    for index in [0, 10, 12, 20, 30, 45, payload.count - 1] {
      var tampered = payload
      tampered[index] ^= 0x01
      XCTAssertThrowsError(try module.decrypt(data: tampered).get(), "index: \(index)")
    }
  }

  func test_Module_RejectsPayload_EncryptedWithAnotherKey() throws {
    let payload = try makePayload(Data("Hello from AES-GCM".utf8))
    let module = CryptoModule.aesCbcCryptoModule(with: "another-key")

    guard case let .failure(error) = module.decrypt(data: payload) else {
      return XCTFail("Expected decryption with another key to fail")
    }
    XCTAssertEqual(error.reason, .decryptionFailure)
    assertOpaqueDecryptionFailure(error.underlying)
  }

  func test_Module_StillRoundTripsCBCAndLegacy() throws {
    let plaintext = Data("Hello from the existing cryptors".utf8)

    for module in [
      CryptoModule.aesCbcCryptoModule(with: cipherKey),
      CryptoModule.legacyCryptoModule(with: cipherKey)
    ] {
      let encrypted = try module.encrypt(data: plaintext).get()
      XCTAssertEqual(try module.decrypt(data: encrypted).get(), plaintext)
    }
  }

  func test_ModuleStream_DecryptsGCMFile() throws {
    let plaintext = Data((0..<100_000).map { _ in UInt8.random(in: 0...255) })
    let output = try decryptStream(makePayload(plaintext))

    XCTAssertEqual(try Data(contentsOf: output), plaintext)
  }

  func test_ModuleStream_DecryptsEmptyPlaintextFile() throws {
    let output = try decryptStream(makePayload(Data()))

    XCTAssertEqual(try Data(contentsOf: output), Data())
  }

  func test_ModuleStream_RejectsTamperedFile_AndWritesNothing() throws {
    var payload = try makePayload(Data("Hello from AES-GCM".utf8))
    payload[payload.count - 1] ^= 0x01

    let input = URL.randomTempPath
    let output = URL.randomTempPath
    try payload.write(to: input)

    let result = CryptoModule.aesCbcCryptoModule(with: cipherKey).decryptStream(from: input, to: output)

    XCTAssertThrowsError(try result.get())
    XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
  }

  func test_Module_WithoutGCMCryptor_ReportsUnknownCryptor() throws {
    let payload = try makePayload(Data("Hello from AES-GCM".utf8))
    let module = CryptoModule(default: AESCBCCryptor(key: cipherKey))

    XCTAssertEqual((module.decrypt(data: payload).error as? PubNubError)?.reason, .unknownCryptorFailure)
  }
}

// MARK: - Helpers

private extension AESGCMCryptorTests {
  func randomNonce() -> Data {
    Data((0..<AESGCMCryptor.nonceLength).map { _ in UInt8.random(in: 0...255) })
  }

  func seal(_ plaintext: Data, nonce: Data) throws -> AES.GCM.SealedBox {
    try AES.GCM.seal(
      plaintext,
      using: SymmetricKey(data: CryptorUtils.SHA256.hash(from: Data(cipherKey.utf8))),
      nonce: AES.GCM.Nonce(data: nonce)
    )
  }

  // Builds a complete wire payload: PNED header, nonce, tag and ciphertext
  func makePayload(_ plaintext: Data) throws -> Data {
    let nonce = randomNonce()
    let box = try seal(plaintext, nonce: nonce)

    return CryptorHeader.v1(cryptorId: AESGCMCryptor.ID, dataLength: AESGCMCryptor.metadataLength).toData()
      + nonce
      + box.tag
      + box.ciphertext
  }

  func decryptStream(_ payload: Data) throws -> URL {
    let input = URL.randomTempPath
    let output = URL.randomTempPath
    try payload.write(to: input)

    _ = try CryptoModule.aesCbcCryptoModule(with: cipherKey).decryptStream(from: input, to: output).get()

    return output
  }

  func flipped(_ data: Data) -> Data {
    var copy = data
    copy[copy.startIndex] ^= 0x01
    return copy
  }

  func hex(_ string: String) throws -> Data {
    var data = Data()
    var index = string.startIndex

    while index < string.endIndex {
      let next = string.index(index, offsetBy: 2)
      data.append(try XCTUnwrap(UInt8(string[index..<next], radix: 16)))
      index = next
    }
    return data
  }

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
