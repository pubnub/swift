//
//  FileManagementRouterTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class FileManagementRouterTests: XCTestCase {
  let testChannel = "TestChannel"
  let testFilename = "TestFile.txt"
  let testFileId = "TestFileId"
}

// MARK: - List

extension FileManagementRouterTests {
  func test_ListRouter_WithValidConfig_SetsExpectedEndpoint() {
    let config = TestPubNubFactory.makeConfig()
    let router = FileManagementRouter(
      .list(channel: testChannel, limit: 0, next: nil),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Get a list of files")
    XCTAssertEqual(router.category, "Get a list of files")
    XCTAssertEqual(router.service, .fileManagement)
  }

  func test_List_WhenChannelEmpty_ReturnsValidationError() {
    let config = TestPubNubFactory.makeConfig()

    let router = FileManagementRouter(
      .list(channel: "", limit: 0, next: nil),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyChannelString)
  }

  func test_ListFiles_WithValidChannel_ReturnsFiles() throws {
    let expectation = self.expectation(description: "testList_Success")

    let sessions = try MockURLSession.mockSession(for: ["file_list_success"])

    let testDate = try XCTUnwrap(DateFormatter.iso8601_noMilliseconds.date(from: "2020-10-12T16:21:56Z"))

    let testFile = PubNubFileBase(
      channel: testChannel,
      fileId: testFileId,
      filename: testFilename,
      size: 8864,
      contentType: nil,
      createdDate: testDate
    )

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.listFiles(channel: testChannel) { result in
      switch result {
      case let .success((files, next)):
        XCTAssertEqual(try? files.first?.transcode(), testFile)
        XCTAssertNil(next)
      case let .failure(error):
        XCTFail("List failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_ListFiles_WithNoFiles_ReturnsEmptyList() throws {
    let expectation = self.expectation(description: "testList_Success_Empty")

    let sessions = try MockURLSession.mockSession(for: ["file_list_success_empty"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.listFiles(channel: testChannel) { result in
      switch result {
      case let .success((files, next)):
        XCTAssertTrue(files.isEmpty)
        XCTAssertNil(next)
      case let .failure(error):
        XCTFail("List failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_ListFiles_WhenInvalidParameter_ReturnsInvalidCharacterError() throws {
    let expectation = self.expectation(description: "testList_Error_InvalidParameter")

    let sessions = try MockURLSession.mockSession(for: ["file_error_invalidParam"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.listFiles(channel: testChannel) { result in
      switch result {
      case .success:
        XCTFail("Request should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError, PubNubError(.invalidCharacter))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_ListFiles_WhenServiceNotEnabled_ReturnsServiceNotEnabledError() throws {
    let expectation = self.expectation(description: "testList_Error_NotEnabled")

    let sessions = try MockURLSession.mockSession(for: ["file_error_notEnabled"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.listFiles(channel: testChannel) { result in
      switch result {
      case .success:
        XCTFail("Request should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError, PubNubError(.serviceNotEnabled))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_ListFiles_WhenInternalServiceError_ReturnsInternalServiceError() throws {
    let expectation = self.expectation(description: "testList_Error_InternalError")

    let sessions = try MockURLSession.mockSession(for: ["internalServiceError_StatusCode"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.listFiles(channel: testChannel) { result in
      switch result {
      case .success:
        XCTFail("Request should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError, PubNubError(.internalServiceError))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Fetch URL / Download

extension FileManagementRouterTests {
  func test_FetchURLRouter_WithValidConfig_SetsExpectedEndpoint() {
    let config = TestPubNubFactory.makeConfig()

    let router = FileManagementRouter(
      .fetchURL(channel: testChannel, fileId: testFileId, filename: testFilename),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Redirects to a download URL for the given file")
    XCTAssertEqual(router.category, "Redirects to a download URL for the given file")
    XCTAssertEqual(router.service, .fileManagement)
  }

  func test_FetchURL_WhenChannelEmpty_ReturnsValidationError() {
    let config = TestPubNubFactory.makeConfig()

    let router = FileManagementRouter(
      .fetchURL(channel: "", fileId: testFileId, filename: testFilename),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyChannelString)
  }

  func test_FetchURL_WhenFileIdEmpty_ReturnsValidationError() {
    let config = TestPubNubFactory.makeConfig()

    let router = FileManagementRouter(
      .fetchURL(channel: testChannel, fileId: "", filename: testFilename),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyFileIdString)
  }

  func test_FetchURL_WhenFilenameEmpty_ReturnsValidationError() {
    let config = TestPubNubFactory.makeConfig()

    let router = FileManagementRouter(
      .fetchURL(channel: testChannel, fileId: testFileId, filename: ""),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyFilenameString)
  }

  func test_FetchURL_WithValidParams_ReturnsExpectedURL() throws {
    let config = TestPubNubFactory.makeConfig()

    var testURL = URLComponents()
    testURL.scheme = config.urlScheme
    testURL.host = config.origin
    // swiftlint:disable:next line_length
    testURL.path = "/v1/files/\(config.subscribeKey)/channels/\(testChannel.urlEncodeSlash)/files/\(testFileId.urlEncodeSlash)/\(testFilename.urlEncodeSlash)"
    testURL.queryItems = [
      Constant.pnSDKURLQueryItem,
      URLQueryItem(name: "uuid", value: config.userId)
    ]

    let downloadURL = try PubNub(configuration: config)
      .generateFileDownloadURL(channel: testChannel, fileId: testFileId, filename: testFilename)

    XCTAssertEqual(downloadURL, testURL.url)
  }

  func test_FetchURL_WhenFileIdEmpty_ThrowsError() {
    let config = TestPubNubFactory.makeConfig()

    do {
      _ = try PubNub(configuration: config)
        .generateFileDownloadURL(channel: testChannel, fileId: "", filename: testFilename)

      XCTFail("Expression should throw an error")
    } catch {
      XCTAssertEqual(error.pubNubError?.details.first,
                     ErrorDescription.emptyFileIdString)
    }
  }

  func test_Download_WithValidFile_ReturnsDownloadedFile() throws {
    let expectation = self.expectation(description: "testDownload_Success")

    let config = TestPubNubFactory.makeConfig()

    let tempFile = FileManager.default.tempDirectory.appendingPathComponent("testDownload_Success.txt")
    if FileManager.default.fileExists(atPath: tempFile.path) {
      try? FileManager.default.removeItem(at: tempFile)
    }

    let testFile = PubNubLocalFileBase(channel: testChannel, fileId: testFileId, fileURL: tempFile)

    let testURL = try ImportTestResource.resourceURL("file_upload_sample", withExtension: "txt")
    let testData = try Data(contentsOf: testURL)

    let mockTask = MockURLSessionDownloadTask(identifier: 1)
    mockTask.mockDownloadLocation = testURL
    mockTask.mockResponse = HTTPURLResponse(statusCode: 202)

    let fileSession = MockURLSession(tasks: [mockTask])

    PubNub(configuration: config, fileSession: fileSession)
      .download(file: testFile, toFileURL: testFile.fileURL) { task in
        XCTAssertEqual(mockTask.mockIdentifier, task.taskIdentifier)
      }
    completion: { result in
        switch result {
        case let .success(response):
          XCTAssertEqual(response.task.taskIdentifier, mockTask.taskIdentifier)
          XCTAssertEqual(try? response.file.transcode(), testFile)
          XCTAssertEqual(try? Data(contentsOf: response.file.fileURL), testData)

        case let .failure(error):
          XCTFail("Request failed with error \(error)")
        }

        try? FileManager.default.removeItem(at: tempFile)
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_Download_WithResumeData_ReturnsDownloadedFile() {
    let expectation = self.expectation(description: "testDownload_Success")

    let config = TestPubNubFactory.makeConfig()

    let tempFile = FileManager.default.tempDirectory.appendingPathComponent("testDownload_Success_ResumeData.txt")
    let downloadURL = FileManager.default.tempDirectory.appendingPathComponent("testDownload_Success.txt")
    let testFile = PubNubLocalFileBase(channel: testChannel, fileId: testFileId, fileURL: tempFile)

    let testData = Data("Testing download resume data".utf8)

    try? InputStream(data: testData).writeEncodedData(to: downloadURL)

    let mockTask = MockURLSessionDownloadTask(identifier: 1)
    mockTask.mockDownloadLocation = downloadURL
    mockTask.mockResponse = HTTPURLResponse(statusCode: 202)

    let fileSession = MockURLSession(tasks: [mockTask])

    PubNub(configuration: config, fileSession: fileSession)
      .download(file: testFile, toFileURL: testFile.fileURL, resumeData: testData) { task in
        XCTAssertEqual(mockTask.mockIdentifier, task.taskIdentifier)
      }
    completion: { result in
        switch result {
        case let .success(response):
          XCTAssertEqual(response.task.taskIdentifier, mockTask.taskIdentifier)
          XCTAssertEqual(try? response.file.transcode(), testFile)
          XCTAssertEqual(try? Data(contentsOf: response.file.fileURL), testData)

        case let .failure(error):
          XCTFail("Request failed with error \(error)")
        }

        // Cleanup files
        try? FileManager.default.removeItem(at: tempFile)
        try? FileManager.default.removeItem(at: downloadURL)

        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_Download_WhenBadRequest_ReturnsInvalidCharacterError() {
    let expectation = self.expectation(description: "testDownload_Error_ServiceNotEnabled")

    let config = TestPubNubFactory.makeConfig()

    let testFile = PubNubLocalFileBase(channel: testChannel, fileId: testFileId, fileURL: URL(fileURLWithPath: ""))

    let mockTask = MockURLSessionDownloadTask(identifier: 1)
    mockTask.mockDownloadLocation = try? ImportTestResource.resourceURL("file_error_invalidParam_raw")
    mockTask.mockResponse = HTTPURLResponse(statusCode: 400)

    let fileSession = MockURLSession(tasks: [mockTask])

    PubNub(configuration: config, fileSession: fileSession)
      .download(file: testFile, toFileURL: testFile.fileURL) { task in
        XCTAssertEqual(mockTask.mockIdentifier, task.taskIdentifier)
      }
    completion: { result in
        switch result {
        case .success:
          XCTFail("Request should not succeed")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.invalidCharacter))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_Download_WhenServiceNotEnabled_ReturnsServiceNotEnabledError() {
    let expectation = self.expectation(description: "testDownload_Error_ServiceNotEnabled")

    let config = TestPubNubFactory.makeConfig()

    let testFile = PubNubLocalFileBase(channel: testChannel, fileId: testFileId, fileURL: URL(fileURLWithPath: ""))

    let mockTask = MockURLSessionDownloadTask(identifier: 1)
    mockTask.mockDownloadLocation = try? ImportTestResource.resourceURL("file_error_notEnabled_raw")
    mockTask.mockResponse = HTTPURLResponse(statusCode: 402)

    let fileSession = MockURLSession(tasks: [mockTask])

    PubNub(configuration: config, fileSession: fileSession)
      .download(file: testFile, toFileURL: testFile.fileURL) { task in
        XCTAssertEqual(mockTask.mockIdentifier, task.taskIdentifier)
      }
    completion: { result in
        switch result {
        case .success:
          XCTFail("Request should not succeed")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.serviceNotEnabled))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_Download_WhenInternalServiceError_ReturnsInternalServiceError() {
    let expectation = self.expectation(description: "testDownload_Error_ServiceNotEnabled")

    let config = TestPubNubFactory.makeConfig()

    let testFile = PubNubLocalFileBase(channel: testChannel, fileId: testFileId, fileURL: URL(fileURLWithPath: ""))

    let mockTask = MockURLSessionDownloadTask(identifier: 1)
    mockTask.mockResponse = HTTPURLResponse(statusCode: 500)

    let fileSession = MockURLSession(tasks: [mockTask])

    PubNub(configuration: config, fileSession: fileSession)
      .download(file: testFile, toFileURL: testFile.fileURL) { task in
        XCTAssertEqual(mockTask.mockIdentifier, task.taskIdentifier)
      }
    completion: { result in
        switch result {
        case .success:
          XCTFail("Request should not succeed")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.internalServiceError))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Generate URL / Send

extension FileManagementRouterTests {
  func test_GenerateURLRouter_WithValidConfig_SetsExpectedEndpoint() {
    let config = TestPubNubFactory.makeConfig()

    let router = FileManagementRouter(
      .generateURL(channel: testChannel, body: .init(name: testFilename)),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Generate a presigned request for file upload")
    XCTAssertEqual(router.category, "Generate a presigned request for file upload")
    XCTAssertEqual(router.service, .fileManagement)
  }

  func test_GenerateURL_WhenChannelEmpty_ReturnsValidationError() {
    let config = TestPubNubFactory.makeConfig()

    let router = FileManagementRouter(
      .generateURL(channel: "", body: .init(name: testFilename)),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyChannelString)
  }

  func test_GenerateURL_WhenFilenameEmpty_ReturnsValidationError() {
    let config = TestPubNubFactory.makeConfig()

    let router = FileManagementRouter(
      .generateURL(channel: testChannel, body: .init(name: "")),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyFilenameString)
  }

  func test_Send_WithFileURL_ReturnsUploadedFileAndTimetoken() throws {
    let expectation = self.expectation(description: "testSend_Success")

    let config = TestPubNubFactory.makeConfig()
    let sessions = try MockURLSession.mockSession(for: ["file_generateURL_success", "publish_success"])
    let testURL = try ImportTestResource.resourceURL("file_upload_sample", withExtension: "txt")

    let testFile = PubNubLocalFileBase(
      channel: testChannel,
      fileId: testFileId,
      filename: testFilename,
      size: Int64(testURL.sizeOf),
      contentType: testURL.contentType,
      fileURL: testURL
    )

    let mockTask = MockURLSessionUploadTask(identifier: 1)
    mockTask.mockResponse = HTTPURLResponse(statusCode: 202)

    let fileSession = MockURLSession(tasks: [mockTask])
    let pubnub = PubNub(configuration: config, session: sessions.session, fileSession: fileSession)

    pubnub.send(.file(url: testURL), channel: testChannel, remoteFilename: testFilename) { task in
      XCTAssertEqual(mockTask.mockIdentifier, task.taskIdentifier)
    }
    completion: { result in
      switch result {
      case let .success(response):
        XCTAssertEqual(response.task.taskIdentifier, mockTask.taskIdentifier)
        XCTAssertEqual(try? response.file.transcode(), testFile)
        XCTAssertEqual(response.publishedAt, 15_644_265_196_692_560)

      case let .failure(error):
        XCTFail("Request failed with error \(error)")
      }

      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_Send_WithBackgroundSession_CreatesBackgroundUploadTask() {
    let config = TestPubNubFactory.makeConfig()
    let testData = Data("Test String".utf8)

    let randomFileId = UUID().uuidString

    let backgroundFileUploadURL = FileManager.default.tempDirectory.appendingPathComponent(randomFileId)

    var request = URLRequest(url: URL(fileURLWithPath: ""))
    request.httpBodyStream = InputStream(data: testData)

    let mockTask = MockURLSessionUploadTask(identifier: 1)
    mockTask.mockResponse = HTTPURLResponse(statusCode: 202)

    let fileSession = MockURLSession(tasks: [mockTask], configuration: .pubnubBackground)

    let task = try? PubNub(configuration: config).createFileURLSessionUploadTask(
      request: request, session: fileSession, backgroundFileCacheIdentifier: randomFileId
    )

    XCTAssertEqual(task?.urlSessionTask, mockTask)
    XCTAssertTrue(FileManager.default.fileExists(atPath: backgroundFileUploadURL.path))

    try? FileManager.default.removeItem(at: backgroundFileUploadURL)
  }

  func test_Send_WhenServiceNotEnabled_ReturnsServiceNotEnabledError() throws {
    let expectation = self.expectation(description: "testSend_Success")

    let sessions = try MockURLSession.mockSession(for: ["file_error_notEnabled"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.send(
      .data(Data(), contentType: "text/plain"), channel: testChannel, remoteFilename: testFilename
    ) { result in
      switch result {
      case .success:
        XCTFail("Request should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError, PubNubError(.serviceNotEnabled))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Delete

extension FileManagementRouterTests {
  func test_DeleteRouter_WithValidConfig_SetsExpectedEndpoint() {
    let config = TestPubNubFactory.makeConfig()

    let router = FileManagementRouter(
      .delete(channel: testChannel, fileId: testFileId, filename: testFilename),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Delete a file")
    XCTAssertEqual(router.category, "Delete a file")
    XCTAssertEqual(router.service, .fileManagement)
    XCTAssertEqual(router.method, .delete)
  }

  func test_Delete_WhenChannelEmpty_ReturnsValidationError() {
    let config = TestPubNubFactory.makeConfig()

    let router = FileManagementRouter(
      .delete(channel: "", fileId: testFileId, filename: testFilename),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyChannelString)
  }

  func test_Delete_WhenFileIdEmpty_ReturnsValidationError() {
    let config = TestPubNubFactory.makeConfig()

    let router = FileManagementRouter(
      .delete(channel: testChannel, fileId: "", filename: testFilename),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyFileIdString)
  }

  func test_Delete_WhenFilenameEmpty_ReturnsValidationError() {
    let config = TestPubNubFactory.makeConfig()

    let router = FileManagementRouter(
      .delete(channel: testChannel, fileId: testFileId, filename: ""),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyFilenameString)
  }

  func test_Delete_WithValidFile_ReturnsSuccess() throws {
    let expectation = self.expectation(description: "testDelete_Success")

    let sessions = try MockURLSession.mockSession(for: ["file_delete_success"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.remove(fileId: testFileId, filename: testFilename, channel: testChannel) { result in
      switch result {
      case .success:
        expectation.fulfill()
      case .failure:
        XCTFail("Request should not fail")
      }
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_Delete_WhenInvalidParameter_ReturnsInvalidCharacterError() throws {
    let expectation = self.expectation(description: "testDelete_Error_InvalidParameter")

    let sessions = try MockURLSession.mockSession(for: ["file_error_invalidParam"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.remove(fileId: testFileId, filename: testFilename, channel: testChannel) { result in
      switch result {
      case .success:
        XCTFail("Request should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError, PubNubError(.invalidCharacter))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_Delete_WhenServiceNotEnabled_ReturnsServiceNotEnabledError() throws {
    let expectation = self.expectation(description: "testDelete_Error_NotEnabled")

    let sessions = try MockURLSession.mockSession(for: ["file_error_notEnabled"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.remove(fileId: testFileId, filename: testFilename, channel: testChannel) { result in
      switch result {
      case .success:
        XCTFail("Request should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError, PubNubError(.serviceNotEnabled))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_Delete_WhenInternalServiceError_ReturnsInternalServiceError() throws {
    let expectation = self.expectation(description: "testDelete_Error_InternalError")

    let sessions = try MockURLSession.mockSession(for: ["internalServiceError_StatusCode"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.remove(fileId: testFileId, filename: testFilename, channel: testChannel) { result in
      switch result {
      case .success:
        XCTFail("Request should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError, PubNubError(.internalServiceError))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}
