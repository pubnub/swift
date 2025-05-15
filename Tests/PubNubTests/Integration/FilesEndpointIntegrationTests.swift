//
//  FilesEndpointIntegrationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import XCTest
import PubNubSDK

class FilesEndpointIntegrationTests: XCTestCase {
  let config = PubNubConfiguration(from: Bundle(for: FilesEndpointIntegrationTests.self))
  
  func testUploadFile() throws {
    let data = try XCTUnwrap("Lorem ipsum dolor sit amet".data(using: .utf8))
    let client = PubNub(configuration: config, fileSession: URLSession(configuration: .default, delegate: FileSessionManager(), delegateQueue: .main))
    let remoteFileId = "remoteFileId"
    let testChannel = randomString()

    let sendFileExpect = expectation(description: "Send File Response")
    let removeFileExpect = expectation(description: "Remove File Response")
        
    let performDeleteFile = { (file: PubNubFile) in
      client.remove(
        fileId: file.fileId,
        filename: file.filename,
        channel: testChannel
      ) { result in
        switch result {
        case .success:
          removeFileExpect.fulfill()
        case let .failure(error):
          XCTFail("Unexpected condition: \(error)")
        }
      }
    }

    client.send(
      .data(data, contentType: "text/plain"),
      channel: testChannel,
      remoteFilename: remoteFileId
    ) { result in
      switch result {
      case let .success(sendFileResponse):
        XCTAssertEqual(sendFileResponse.file.filename, remoteFileId)
        XCTAssertEqual(sendFileResponse.file.channel, testChannel)
        sendFileExpect.fulfill()
        performDeleteFile(sendFileResponse.file)
      case let .failure(error):
        XCTFail("Unexpected error: \(error)")
      }
    }
    
    wait(for: [sendFileExpect, removeFileExpect], timeout: 20.0)
  }
  
  func testListFiles() throws {
    let data = try XCTUnwrap("Lorem ipsum dolor sit amet".data(using: .utf8))
    let client = PubNub(configuration: config, fileSession: URLSession(configuration: .default, delegate: FileSessionManager(), delegateQueue: .main))
    let remoteFileId = "remoteFileId"
    let testChannel = randomString()
    let removeFileExpect = expectation(description: "Remove File Response")
    let listFilesExpect = expectation(description: "List Files Response")
    
    let performDeleteFile = { (file: PubNubFile) in
      client.remove(
        fileId: file.fileId,
        filename: file.filename,
        channel: testChannel
      ) { result in
        switch result {
        case .success:
          removeFileExpect.fulfill()
        case let .failure(error):
          XCTFail("Unexpected condition: \(error)")
        }
      }
    }
    
    client.send(
      .data(data, contentType: "text/plain"),
      channel: testChannel,
      remoteFilename: remoteFileId
    ) { [unowned client] result in
      switch result {
      case .success:
        client.listFiles(channel: testChannel) { getFilesResult in
          switch getFilesResult {
          case let .success(getFilesResponse):
            XCTAssertEqual(getFilesResponse.files.count, 1)
            listFilesExpect.fulfill()
            performDeleteFile(getFilesResponse.files[0])
          case let .failure(error):
            XCTFail("Unexpected error: \(error)")
          }
        }
      case let .failure(error):
        XCTFail("Unexpected error: \(error)")
      }
    }
    
    wait(for: [listFilesExpect, removeFileExpect], timeout: 30.0)
  }
  
  func testUploadFileAsStream() throws {
    let data = try XCTUnwrap("Lorem ipsum dolor sit amet".data(using: .utf8))
    let client = PubNub(configuration: config, fileSession: URLSession(configuration: .default, delegate: FileSessionManager(), delegateQueue: .main))
    let remoteFileId = "remoteFileId"
    let testChannel = randomString()

    let sendFileExpect = expectation(description: "Send File Response")
    let removeFileExpect = expectation(description: "Remove File Response")
        
    // Clean up the file after the test
    let performDeleteFile = { (file: PubNubFile) in
      client.remove(
        fileId: file.fileId,
        filename: file.filename,
        channel: testChannel
      ) { result in
        switch result {
        case .success:
          removeFileExpect.fulfill()
        case let .failure(error):
          XCTFail("Unexpected condition: \(error)")
        }
      }
    }

    client.send(
      .stream(InputStream(data: data), contentType: "text/plain", contentLength: data.count),
      channel: testChannel,
      remoteFilename: remoteFileId
    ) { result in
      switch result {
      case let .success(sendFileResponse):
        XCTAssertEqual(sendFileResponse.file.filename, remoteFileId)
        XCTAssertEqual(sendFileResponse.file.channel, testChannel)
        sendFileExpect.fulfill()
        performDeleteFile(sendFileResponse.file)
      case let .failure(error):
        XCTFail("Unexpected error: \(error)")
      }
    }
    
    wait(for: [sendFileExpect, removeFileExpect], timeout: 20.0)
  }
  
  func testManualEncryptDecryptFile() throws {
    let data = try XCTUnwrap("This is a secret message that should be encrypted".data(using: .utf8))
    let cryptoModule = CryptoModule.aesCbcCryptoModule(with: "someKey")
    
    let fileSession = URLSession(configuration: .default, delegate: FileSessionManager(), delegateQueue: .main)
    let client = PubNub(configuration: config, fileSession: fileSession)
    let encryptedStreamResult = try cryptoModule.encrypt(stream: InputStream(data: data), contentLength: data.count).get()
        
    let downloadFileExpect = expectation(description: "Download Encrypted File Expect")
    let decryptFileExpect = expectation(description: "Decrypt File Expect")
    let removeFileExpect = expectation(description: "Remove File Response")

    let remoteFileId = "encryptedFile"
    let testChannel = randomString()
    let downloadFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    let decryptionOutputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    
    // Clean up the file after the test
    let performDeleteFile = { (file: PubNubFile) in
      client.remove(
        fileId: file.fileId,
        filename: file.filename,
        channel: testChannel
      ) { result in
        switch result {
        case .success:
          removeFileExpect.fulfill()
        case let .failure(error):
          XCTFail("Unexpected condition: \(error)")
        }
      }
    }
    
    // Upload encrypted file
    client.send(
      .stream(encryptedStreamResult.stream, contentType: "text/plain", contentLength: encryptedStreamResult.contentLength),
      channel: testChannel,
      remoteFilename: remoteFileId
    ) { [unowned client] result in
      switch result {
      case let .success(sendFileResponse):
        client.download(
          file: sendFileResponse.file,
          toFileURL: downloadFileURL
        ) { downloadResult in
          switch downloadResult {
          case let .success(downloadResponse):
            cryptoModule.decryptStream(from: downloadResponse.file.fileURL, to: decryptionOutputURL)
            XCTAssertEqual(try? Data(contentsOf: decryptionOutputURL), data)
            decryptFileExpect.fulfill()
            performDeleteFile(downloadResponse.file)
          case let .failure(error):
            XCTFail("Unexpected error: \(error)")
          }
          downloadFileExpect.fulfill()
        }
      case let .failure(error):
        XCTFail("Failed to upload encrypted file: \(error)")
      }
    }
    wait(for: [downloadFileExpect, decryptFileExpect, removeFileExpect], timeout: 30.0)
  }
  
  func testSystemWideEncryptDecryptFile() throws {
    let data = try XCTUnwrap("This is a secret message that should be encrypted".data(using: .utf8))
    let fileSession = URLSession(configuration: .default, delegate: FileSessionManager(), delegateQueue: .main)
    
    // Reuse the same config
    var configuration = config
    // Set the system wide crypto module
    configuration.cryptoModule = CryptoModule.aesCbcCryptoModule(with: "someKey")
    
    let client = PubNub(configuration: config, fileSession: fileSession)
    let downloadFileExpect = expectation(description: "Download Encrypted File Expect")
    let decryptFileExpect = expectation(description: "Decrypt File Expect")
    let removeFileExpect = expectation(description: "Remove File Response")

    let remoteFileId = "encryptedFile"
    let testChannel = randomString()
    let downloadFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    
    // Clean up the file after the test
    let performDeleteFile = { (file: PubNubFile) in
      client.remove(
        fileId: file.fileId,
        filename: file.filename,
        channel: testChannel
      ) { result in
        switch result {
        case .success:
          removeFileExpect.fulfill()
        case let .failure(error):
          XCTFail("Unexpected condition: \(error)")
        }
      }
    }
    
    // Upload file
    client.send(
      .stream(InputStream(data: data), contentType: "text/plain", contentLength: data.count),
      channel: testChannel,
      remoteFilename: remoteFileId
    ) { [unowned client] result in
      switch result {
      case let .success(sendFileResponse):
        client.download(
          file: sendFileResponse.file,
          toFileURL: downloadFileURL
        ) { downloadResult in
          switch downloadResult {
          case let .success(downloadResponse):
            XCTAssertEqual(try? Data(contentsOf: downloadResponse.file.fileURL), data)
            decryptFileExpect.fulfill()
            performDeleteFile(downloadResponse.file)
          case let .failure(error):
            XCTFail("Unexpected error: \(error)")
          }
          downloadFileExpect.fulfill()
        }
      case let .failure(error):
        XCTFail("Failed to upload encrypted file: \(error)")
      }
    }
    wait(for: [downloadFileExpect, decryptFileExpect, removeFileExpect], timeout: 30.0)
  }
}
