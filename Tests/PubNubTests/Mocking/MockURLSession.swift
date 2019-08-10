//
//  MockURLSession.swift
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

import Foundation
@testable import PubNub

class MockURLSessionTask: URLSessionDataTask {
  var mockSession: URLSessionReplaceable
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
    (mockSession as? MockURLSession)?.resume(task: self)
  }

  override func cancel() {}

  init(identifier: Int, session: URLSessionReplaceable, request: URLRequest) {
    mockIdentifier = identifier
    mockSession = session
    mockRequest = request
  }
}

class MockURLSession: URLSessionReplaceable {
  var configuration: URLSessionConfiguration
  var urlSessionEvents: URLSessionDelegate?
  var delegateQueue: OperationQueue
  var sessionDescription: String?

  let actualSession: URLSession

  struct InternalState {
    var tasks = [MockURLSessionTask]()
  }

  var state = Atomic(InternalState())
  var tasks: [MockURLSessionTask] {
    return state.lockedRead { $0.tasks }
  }

  var responseForTask: ((MockURLSessionTask, Int) -> (MockURLSessionTask?))?

  required init(configuration: URLSessionConfiguration, delegate: URLSessionDelegate?, delegateQueue: OperationQueue?) {
    self.configuration = configuration
    urlSessionEvents = delegate
    self.delegateQueue = delegateQueue ?? .main

    sessionDescription = "MockURLSession Description"

    actualSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
    actualSession.sessionDescription = sessionDescription
  }

  var dataDelegate: URLSessionDataDelegate? {
    return urlSessionEvents as? URLSessionDataDelegate
  }

  var sessionDelegate: SessionDelegate? {
    return urlSessionEvents as? SessionDelegate
  }

  func resume(task: MockURLSessionTask) {
    delegateQueue.addOperation {
      let taskIndex = self.state.lockedRead { $0.tasks.firstIndex(of: task) ?? 0 }

      if let mockTask = self.responseForTask?(task, taskIndex) {
        mockTask.mockState = .completed
        if let data = mockTask.mockData {
          self.dataDelegate?.urlSession?(self.actualSession, dataTask: task, didReceive: data)
        }
        self.dataDelegate?.urlSession?(self.actualSession, task: mockTask, didCompleteWithError: mockTask.error)
      }
    }
  }

  func dataTask(with request: URLRequest) -> URLSessionDataTask {
    let task = MockURLSessionTask(identifier: state.lockedRead { $0.tasks.count }, session: self, request: request)

    state.lockedWrite { atomicState in
      atomicState.tasks.append(task)
    }

    return task
  }

  func invalidateAndCancel() {
    state.lockedRead { $0.tasks.forEach { $0.cancel() } }
  }
}

extension MockURLSession {
  static func mockSession(
    for jsonResources: [String],
    with stream: SessionStream? = nil
  ) throws -> (session: Session?, mockSession: MockURLSession) {
    let urlSession = MockURLSession(configuration: .ephemeral, delegate: SessionDelegate(), delegateQueue: .main)

    urlSession.responseForTask = { mockTask, index in
      guard jsonResources.count > index else {
        print("Index out of range for next task")
        return nil
      }

      let resource = jsonResources[index]
      let endpointResource: EndpointResource? = ImportTestResource.testResource(resource)
      let urlErrorResource: URLErrorResource? = ImportTestResource.testResource(resource)

      guard let url = mockTask.mockRequest.url else {
        print("Could not get url from mock task")
        return nil
      }

      mockTask.mockData = try? endpointResource?.body.jsonDataResult.get()

      // Return either the response or a URL error
      if let responseCode = endpointResource?.code {
        mockTask.mockResponse = HTTPURLResponse(url: url,
                                                statusCode: responseCode,
                                                httpVersion: "1.1",
                                                headerFields: nil)
      } else if let error = urlErrorResource?.urlError {
        mockTask.mockError = error
      }

      return mockTask
    }

    guard let delegateQueue = urlSession.delegateQueue.underlyingQueue else {
      return (nil, urlSession)
    }

    guard let delegate = urlSession.sessionDelegate else {
      return (nil, urlSession)
    }

    return (Session(session: urlSession,
                    delegate: delegate,
                    sessionQueue: delegateQueue,
                    sessionStream: stream),
            urlSession)
  }
}
