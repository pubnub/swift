//
//  Request.swift
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

final class Request {
  enum TaskState: String, CustomStringConvertible {
    case initialized = "Initialized"
    case resumed = "Resumed"
    case cancelled = "Cancelled"
    case finished = "Finished"

    func canTransition(to state: TaskState) -> Bool {
      switch (self, state) {
      case (.initialized, _):
        return true
      case (_, .initialized), (.cancelled, _), (.finished, _):
        return false
      case (.resumed, .cancelled):
        return true
      case (.resumed, .resumed):
        return false
      case (_, .finished):
        return true
      }
    }

    var description: String {
      return rawValue
    }
  }

  struct InternalState {
    var taskState: TaskState = .initialized

    var responseCompletionClosure: ((Result<EndpointResponse<Data>, Error>) -> Void)?

    var tasks: [URLSessionTask] = []

    var urlRequests: [URLRequest] = []
    var error: Error?
    var previousErrors: [Error] = []

    var retryCount = 0

    var responesData: Data?

    mutating func purgeAll() {
      tasks.removeAll()
      urlRequests.removeAll()
      previousErrors.removeAll()
    }
  }

  let sessionID: UUID
  let requestID: UUID = UUID()
  let router: HTTPRouter
  let requestQueue: DispatchQueue
  let requestOperator: RequestOperator?

  private(set) weak var delegate: RequestDelegate?
  let sessionStream: SessionStream?

  let atomicState: Atomic<InternalState> = Atomic(InternalState())

  private var atomicValidators: Atomic<[() -> Void]> = Atomic([])

  init(
    with router: HTTPRouter,
    requestQueue: DispatchQueue,
    sessionStream: SessionStream?,
    requestOperator: RequestOperator? = nil,
    delegate: RequestDelegate,
    createdBy sessionID: UUID
  ) {
    self.router = router
    self.requestQueue = requestQueue
    self.sessionStream = sessionStream
    self.sessionID = sessionID

    var operators = [RequestOperator]()
    if let requestOperator = requestOperator {
      operators.append(requestOperator)
    }
    if router.configuration.useRequestId {
      let requestIdOperator = RequestIdOperator(requestID: requestID.description)
      operators.append(requestIdOperator)
    }
    self.requestOperator = MultiplexRequestOperator(operators: operators)
    self.delegate = delegate

    PubNub.log.debug("Request Created \(requestID) on \(router)")
  }

  deinit {
    PubNub.log.debug("Request Destroyed \(requestID)")

    atomicState.lockedWrite { $0.purgeAll() }
  }

  var urlRequests: [URLRequest] {
    return atomicState.lockedRead { $0.urlRequests }
  }

  var urlRequest: URLRequest? {
    return urlRequests.last
  }

  var tasks: [URLSessionTask] {
    return atomicState.lockedRead { $0.tasks }
  }

  var task: URLSessionTask? {
    return tasks.last
  }

  var urlResponse: HTTPURLResponse? {
    return task?.response as? HTTPURLResponse
  }

  var data: Data? {
    return atomicState.lockedRead { $0.responesData }
  }

  private(set) var error: Error? {
    get {
      return atomicState.lockedRead { $0.error }
    }
    set {
      atomicState.lockedWrite {
        if let error = $0.error {
          $0.previousErrors.append(error)
        }
        $0.error = newValue
      }
    }
  }

  var previousErrors: [Error] {
    return atomicState.lockedRead { $0.previousErrors }
  }

  var previousError: Error? {
    return previousErrors.last
  }

  var retryCount: Int {
    return atomicState.lockedRead { $0.retryCount }
  }

  var requestState: TaskState {
    return atomicState.lockedRead { $0.taskState }
  }

  var isCancelled: Bool {
    return atomicState.lockedRead { $0.taskState == .cancelled }
  }

  var isFinished: Bool {
    return atomicState.lockedRead { state in
      let taskState = state.taskState
      return taskState == .cancelled || taskState == .finished
    }
  }

  // MARK: - Request Processing

  func didMutate(_ initialRequest: URLRequest, to mutatedRequest: URLRequest) {
    atomicState.lockedWrite { $0.urlRequests.append(mutatedRequest) }

    sessionStream?.emitRequest(self, didMutate: initialRequest, to: mutatedRequest)
  }

  func didFailToMutate(_ urlRequest: URLRequest, with mutatorError: Error) {
    error = mutatorError

    sessionStream?.emitRequest(self, didFailToMutate: urlRequest, with: mutatorError)

    retryOrFinish(with: mutatorError)
  }

  func prepareForRetry() {
    atomicState.lockedWrite { $0.retryCount += 1 }
    error = nil
    sessionStream?.emitRequestIsRetrying(self)
  }

  // MARK: - URLRequest State Events

  func didCreate(_ urlRequest: URLRequest) {
    atomicState.lockedWrite { $0.urlRequests.append(urlRequest) }
    sessionStream?.emitRequest(self, didCreate: urlRequest)
  }

  func didFailToCreateURLRequest(with error: Error) {
    let pubnubError = PubNubError.urlCreation(error, router: router)
    self.error = pubnubError
    sessionStream?.emitRequest(self, didFailToCreateURLRequestWith: pubnubError)
    retryOrFinish(with: error)
  }

  // MARK: - Request State Events

  func didResume() {
    sessionStream?.emitRequestDidResume(self)
  }

  func didCancel() {
    sessionStream?.emitRequestDidCancel(self)
  }

  func didFinish() {
    sessionStream?.emitRequestDidFinish(self)
  }

  // MARK: - URLTask State Events

  func didCreate(_ task: URLSessionTask) {
    atomicState.lockedWrite { $0.tasks.append(task) }
    sessionStream?.emitRequest(self, didCreate: task)

    switch requestState {
    case .initialized:
      resume()
    case .resumed:
      // URLDataTasks cannot be 'resumed' after starting, but this is called during a retry
      task.resume()
      didResume(task)
    case .cancelled:
      task.cancel()
      didCancel(task)
    case .finished:
      // Do nothing
      break
    }
  }

  func didResume(_ task: URLSessionTask) {
    sessionStream?.emitRequest(self, didResume: task)
  }

  func didCancel(_ task: URLSessionTask) {
    sessionStream?.emitRequest(self, didCancel: task)
  }

  func didComplete(_ task: URLSessionTask) {
    // Process the Validators for any additional errors
    atomicValidators.lockedRead { $0.forEach { $0() } }

    if let error = self.error {
      sessionStream?.emitRequest(self, didComplete: task, with: error)
      retryOrFinish(with: error)
    } else {
      sessionStream?.emitRequest(self, didComplete: task)
      finish()
    }
  }

  func didComplete(_ task: URLSessionTask, with error: Error) {
    self.error = PubNubError.sessionDelegate(error, router: router)
    sessionStream?.emitRequest(self, didComplete: task, with: error)
    retryOrFinish(with: error)
  }

  // MARK: - SessionDelegate Events

  func didReceive(data: Data) {
    // Set the data value
    if self.data == nil {
      atomicState.lockedWrite { $0.responesData = data }
    } else {
      atomicState.lockedWrite { $0.responesData?.append(data) }
    }
  }

  func retryOrFinish(with error: Error) {
    guard let delegate = delegate else {
      finish(error: error)
      return
    }

    delegate.retryResult(for: self, dueTo: error, andPrevious: previousError) { retryResult in
      switch retryResult {
      case let .success(retryAfter):
        delegate.retryRequest(self, withDelay: retryAfter)
      case let .failure(error):
        self.finish(error: PubNubError.retry(error, router: self.router))
      }
    }
  }

  func finish(error: Error? = nil) {
    if let error = self.error, !error.isCancellationError {
      let responseMessage: String
      if let response = urlResponse {
        responseMessage = "for response \(response.description)"
      } else {
        responseMessage = "without response."
      }
      PubNub.log.error("Request \(requestID) failed with error \(error) \(responseMessage)")
    }

    if let error = error {
      processResponseCompletion(.failure(error))
      return
    }

    processResponseCompletion(atomicState.lockedRead { state -> Result<EndpointResponse<Data>, Error> in

      if let error = state.error {
        return .failure(error)
      }

      if let request = state.urlRequests.last,
        let response = state.tasks.last?.response as? HTTPURLResponse,
        let data = state.responesData {
        return .success(EndpointResponse(router: router, request: request, response: response, payload: data))
      }

      return .failure(PubNubError(.missingCriticalResponseData, router: router))
    })

    didFinish()
  }
}

// MARK: Self operators

extension Request {
  @discardableResult
  func resume() -> Self {
    atomicState.lockedWrite { mutableState in
      guard mutableState.taskState.canTransition(to: .resumed) else {
        return
      }
      mutableState.taskState = .resumed

      requestQueue.async { self.didResume() }

      guard let task = mutableState.tasks.last, task.state != .completed else {
        return
      }
      task.resume()

      requestQueue.async { self.didResume(task) }
    }
    return self
  }

  @discardableResult
  func cancel(_ error: Error) -> Self {
    // Nothing to do here if we're already finished
    if isFinished {
      return self
    }

    atomicState.lockedWrite { mutableState in
      guard mutableState.taskState.canTransition(to: .cancelled) else {
        return
      }
      mutableState.taskState = .cancelled

      self.requestQueue.async { self.didCancel() }

      mutableState.error = error

      guard let task = mutableState.tasks.last else {
        self.requestQueue.async { self.finish() }
        return
      }

      if task.state != .completed {
        self.requestQueue.async { task.cancel() }
      }

      if task.state != .completed || task.state != .canceling {
        self.requestQueue.async { self.didCancel(task) }
      }

      // We skip the retry attempt due to the cancellation
      self.requestQueue.async { self.finish(error: error) }
    }
    return self
  }

  func validate(_ closure: @escaping ValidationClosure) -> Self {
    let validator: () -> Void = { [weak self] in
      guard self?.error == nil,
        let request = self?.urlRequest,
        let response = self?.urlResponse,
        let router = self?.router,
        let data = self?.data else {
        return
      }

      if let validationError = closure(router, request, response, data) {
        self?.error = validationError
      }
    }

    atomicValidators.append(validator)

    return self
  }

  func validate() -> Self {
    return validate { router, request, response, data in
      if !response.isSuccessful {
        if let data = data, !data.trulyEmpty {
          return router.decodeError(request: request, response: response, for: data)
        }
        return PubNubError(router: router, request: request, response: response)
      }
      return nil
    }
  }
}

// MARK: - Hashable

extension Request: Hashable {
  static func == (lhs: Request, rhs: Request) -> Bool {
    return lhs.requestID == rhs.requestID
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(requestID)
  }
}

// MARK: - RequestDelegate

protocol RequestDelegate: AnyObject {
  func retryResult(
    for request: RequestReplaceable,
    dueTo error: Error,
    andPrevious error: Error?,
    completion: @escaping (Result<TimeInterval, Error>) -> Void
  )
  func retryRequest(_ request: RequestReplaceable, withDelay timeDelay: TimeInterval?)
}

// swiftlint:disable:this file_length
