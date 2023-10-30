//
//  MockURLSession.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
@testable import PubNub

class MockURLSessionDataTask: URLSessionDataTask {
  weak var mockSession: MockURLSession?
  var mockRequest: URLRequest
  var mockState: URLSessionTask.State = .suspended
  var mockResponse: HTTPURLResponse?
  var mockData: Data?
  var mockError: Error?
  var mockIdentifier: Int

  override var response: URLResponse? {
    return mockResponse
  }

  override var originalRequest: URLRequest? {
    return mockRequest
  }

  override var currentRequest: URLRequest? {
    return mockRequest
  }

  override var error: Error? {
    return mockError
  }

  override var state: URLSessionTask.State {
    return mockState
  }

  override var taskIdentifier: Int {
    return mockIdentifier
  }

  override func resume() {
    mockState = .running
    mockSession?.resume(task: self)
  }

  override func cancel() {}

  init(identifier: Int, session: MockURLSession?, request: URLRequest) {
    mockIdentifier = identifier
    mockSession = session
    mockRequest = request
  }
}

class MockURLSessionUploadTask: URLSessionUploadTask {
  weak var mockSession: MockURLSession?
  var mockIdentifier: Int
  var mockState: URLSessionTask.State = .suspended

  var mockRequest: URLRequest?
  var mockResponse: HTTPURLResponse?

  var mockData: Data?
  var mockError: Error?

  override var response: URLResponse? {
    return mockResponse
  }

  override var originalRequest: URLRequest? {
    return mockRequest
  }

  override var currentRequest: URLRequest? {
    return mockRequest
  }

  override var error: Error? {
    return mockError
  }

  override var state: URLSessionTask.State {
    return mockState
  }

  override var taskIdentifier: Int {
    return mockIdentifier
  }

  override var countOfBytesExpectedToReceive: Int64 {
    return 0
  }

  override var progress: Progress {
    return Progress(totalUnitCount: 0)
  }

  override func resume() {
    mockState = .running
    mockSession?.resume(task: self)
  }

  init(
    identifier: Int,
    request: URLRequest? = nil,
    response: HTTPURLResponse? = nil,
    data: Data? = nil,
    error: Error? = nil
  ) {
    mockIdentifier = identifier
    mockRequest = request
    mockData = data
    mockResponse = response
    mockError = error
  }
}

extension HTTPURLResponse {
  convenience init?(url: URL? = nil, statusCode: Int, headerFields: [String: String]? = nil) {
    self.init(
      url: url ?? URL(fileURLWithPath: ""),
      statusCode: statusCode,
      httpVersion: "1.1",
      headerFields: headerFields
    )
  }
}

extension URLSessionTask {
  var downloadResumeData: Data? {
    return (self as? URLSessionDownloadTask)?.resumeData
  }
}

class MockURLSessionDownloadTask: URLSessionDownloadTask {
  var mockIdentifier: Int
  weak var mockSession: MockURLSession?

  var mockState: URLSessionTask.State = .suspended
  var mockRequest: URLRequest?
  var mockResponse: HTTPURLResponse?
  var mockDownloadLocation: URL?
  var mockError: Error?

  override var response: URLResponse? {
    return mockResponse
  }

  override var originalRequest: URLRequest? {
    return mockRequest
  }

  override var currentRequest: URLRequest? {
    return mockRequest
  }

  override var error: Error? {
    return mockError
  }

  override var state: URLSessionTask.State {
    return mockState
  }

  override var taskIdentifier: Int {
    return mockIdentifier
  }

  override var countOfBytesExpectedToReceive: Int64 {
    return 0
  }

  override var progress: Progress {
    return Progress(totalUnitCount: 0)
  }

  override func resume() {
    mockState = .running
    mockSession?.resume(task: self)
  }

  init(
    identifier: Int,
    request: URLRequest? = nil,
    response: HTTPURLResponse? = nil,
    url: URL? = nil,
    error: Error? = nil
  ) {
    mockIdentifier = identifier
    mockRequest = request
    mockDownloadLocation = url
    mockResponse = response
    mockError = error
  }
}

class MockURLSession: URLSessionReplaceable {
  weak var delegate: URLSessionDelegate?

  var configuration: URLSessionConfiguration
  var delegateQueue: OperationQueue
  var sessionDescription: String?

  let actualSession: URLSession

  struct InternalState {
    var tasks = [URLSessionTask]()
  }

  var state = Atomic(InternalState())
  var tasks: [URLSessionTask] {
    return state.lockedRead { $0.tasks }
  }

  var responseForDataTask: ((MockURLSessionDataTask, Int) -> (MockURLSessionDataTask?))?

  required init(
    configuration: URLSessionConfiguration = .ephemeral,
    delegate: URLSessionDelegate? = HTTPSessionDelegate(),
    delegateQueue: OperationQueue? = .main
  ) {
    self.configuration = configuration
    self.delegate = delegate
    self.delegateQueue = delegateQueue ?? .main

    sessionDescription = "MockURLSession Description"

    actualSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
    actualSession.sessionDescription = sessionDescription
  }

  convenience init(
    tasks: [URLSessionTask],
    configuration: URLSessionConfiguration = .ephemeral,
    delegate: URLSessionDelegate? = FileSessionManager(),
    delegateQueue: OperationQueue? = .main
  ) {
    self.init(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)

    tasks.forEach { task in
      (task as? MockURLSessionDownloadTask)?.mockSession = self
      (task as? MockURLSessionUploadTask)?.mockSession = self
    }

    state.lockedWrite { $0.tasks = tasks.reversed() }
  }

  var dataDelegate: URLSessionDataDelegate? {
    return delegate as? URLSessionDataDelegate
  }

  var sessionDelegate: HTTPSessionDelegate? {
    return delegate as? HTTPSessionDelegate
  }

  func resume(task: MockURLSessionDataTask) {
    delegateQueue.addOperation { [weak self] in
      guard let strongSelf = self else {
        fatalError("Failed to resumed due to weak self")
      }

      let taskIndex = strongSelf.state.lockedRead { $0.tasks.firstIndex(of: task) ?? 0 }

      if let mockTask = strongSelf.responseForDataTask?(task, taskIndex) {
        mockTask.mockState = .completed
        if let data = mockTask.mockData {
          strongSelf.dataDelegate?.urlSession?(strongSelf.actualSession, dataTask: task, didReceive: data)
        }
        strongSelf.dataDelegate?.urlSession?(
          strongSelf.actualSession,
          task: mockTask,
          didCompleteWithError: mockTask.error
        )
      }
    }
  }

  func resume(task: MockURLSessionUploadTask) {
    delegateQueue.addOperation { [weak self] in
      guard let strongSelf = self else {
        fatalError("Failed to resumed due to weak self")
      }

      if let data = task.mockData {
        (strongSelf.delegate as? URLSessionDataDelegate)?.urlSession?(
          strongSelf.actualSession,
          dataTask: task,
          didReceive: data
        )
      }

      (strongSelf.delegate as? URLSessionDataDelegate)?.urlSession?(
        strongSelf.actualSession,
        task: task,
        didCompleteWithError: task.error
      )
    }
  }

  func resume(task: MockURLSessionDownloadTask) {
    delegateQueue.addOperation { [weak self] in
      guard let strongSelf = self else {
        fatalError("Failed to resumed due to weak self")
      }

      if let location = task.mockDownloadLocation {
        (strongSelf.delegate as? URLSessionDownloadDelegate)?.urlSession(
          strongSelf.actualSession,
          downloadTask: task,
          didFinishDownloadingTo: location
        )
      }

      (strongSelf.delegate as? URLSessionDataDelegate)?.urlSession?(
        strongSelf.actualSession,
        task: task,
        didCompleteWithError: task.error
      )
    }
  }

  func dataTask(with request: URLRequest) -> URLSessionDataTask {
    let task = MockURLSessionDataTask(identifier: state.lockedRead { $0.tasks.count }, session: self, request: request)

    state.lockedWrite { atomicState in
      atomicState.tasks.append(task)
    }

    return task
  }

  func uploadTask(withStreamedRequest request: URLRequest) -> URLSessionUploadTask {
    guard let task = state.lockedWrite({ $0.tasks.popLast() }),
          let uplaodTask = task as? URLSessionUploadTask else {
      fatalError("Task not found for matching request \(request)")
    }
    return uplaodTask
  }

  func uploadTask(with request: URLRequest, fromFile _: URL) -> URLSessionUploadTask {
    guard let task = state.lockedWrite({ $0.tasks.popLast() }),
          let uplaodTask = task as? URLSessionUploadTask else {
      fatalError("Task not found for matching request \(request)")
    }
    return uplaodTask
  }

  func downloadTask(with url: URL) -> URLSessionDownloadTask {
    guard let task = state.lockedWrite({ $0.tasks.popLast() }),
          let downloadTask = task as? MockURLSessionDownloadTask else {
      fatalError("Task not found for matching request \(url)")
    }
    return downloadTask
  }

  func downloadTask(withResumeData resumeData: Data) -> URLSessionDownloadTask {
    guard let task = state.lockedWrite({ $0.tasks.popLast() }),
          let downloadTask = task as? URLSessionDownloadTask else {
      fatalError("Task not found for matching request \(resumeData)")
    }
    return downloadTask
  }

  func invalidateAndCancel() {
    state.lockedRead { $0.tasks.forEach { $0.cancel() } }
  }
}

extension MockURLSession {
  static func mockSession(
    for jsonResources: [String],
    raw dataResource: [Data] = [],
    with stream: SessionStream? = nil,
    request operators: RequestOperator? = nil
  ) throws -> (session: HTTPSession?, mockSession: MockURLSession) {
    let urlSession = MockURLSession(configuration: .ephemeral, delegate: HTTPSessionDelegate(), delegateQueue: .main)

    urlSession.responseForDataTask = { mockTask, index in
      guard jsonResources.count + dataResource.count > index else {
        fatalError("Index out of range for next task")
      }

      guard let url = mockTask.mockRequest.url else {
        fatalError("Could not get url from mock task")
      }

      if !dataResource.isEmpty, dataResource.count > index {
        mockTask.mockData = dataResource[index]

        mockTask.mockResponse = HTTPURLResponse(url: url,
                                                statusCode: 200,
                                                httpVersion: "1.1",
                                                headerFields: nil)
      } else {
        let resource = jsonResources[index - dataResource.count]
        let endpointResource: EndpointResource? = ImportTestResource.testResource(resource)
        let urlErrorResource: URLErrorResource? = ImportTestResource.testResource(resource)

        mockTask.mockData = try? endpointResource?.body.jsonDataResult.get()

        // Return either the response or an URL error
        if let responseCode = endpointResource?.code {
          mockTask.mockResponse = HTTPURLResponse(url: url,
                                                  statusCode: responseCode,
                                                  httpVersion: "1.1",
                                                  headerFields: nil)
        } else if let error = urlErrorResource?.urlError {
          mockTask.mockError = error
        }
      }

      return mockTask
    }

    guard let delegateQueue = urlSession.delegateQueue.underlyingQueue else {
      return (nil, urlSession)
    }

    guard let delegate = urlSession.sessionDelegate else {
      return (nil, urlSession)
    }

    return (HTTPSession(session: urlSession,
                        delegate: delegate,
                        sessionQueue: delegateQueue,
                        sessionStream: stream).usingDefault(requestOperator: operators),
            urlSession)
  }

  // swiftlint:disable:next file_length
}
