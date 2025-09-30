//
//  Request.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// swiftlint:disable:next type_body_length
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
  let requestID = UUID()
  let router: HTTPRouter
  let requestQueue: DispatchQueue
  let requestOperator: RequestOperator?
  let sessionStream: SessionStream?
  let atomicState: Atomic<InternalState> = Atomic(InternalState())
  let logger: PubNubLogger

  private(set) weak var delegate: RequestDelegate?
  private var atomicValidators: Atomic<[() -> Void]> = Atomic([])

  init(
    with router: HTTPRouter,
    requestQueue: DispatchQueue,
    sessionStream: SessionStream?,
    requestOperator: RequestOperator? = nil,
    delegate: RequestDelegate,
    createdBy sessionID: UUID,
    logger: PubNubLogger
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
    self.logger = logger
    self.delegate = delegate

    logger.trace(
      .customObject(
        .init(
          operation: "request-init",
          details: "Request Created",
          arguments: [("requestID", self.requestID), ("router", router)]
        )
      ), category: .networking
    )
  }

  deinit {
    logger.trace(
      .customObject(
        .init(
          operation: "request-deinit",
          details: "Request Destroyed",
          arguments: [("requestID", self.requestID)]
        )
      ), category: .networking
    )

    let currentState = atomicState.lockedRead { $0 }
    let taskState = currentState.taskState

    // Ensure that the response is always delivered to the caller. This situation could occur if the task is created
    // but not yet resumed, and the session is invalidated in the meantime.
    if taskState == .initialized {
      let error = PubNubError(.clientCancelled)
      atomicState.lockedWrite { $0.error = error }
      finish(error: error)
    }

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
    logger.error(
      .customObject(
        .init(
          operation: "request-mutate-fail",
          details: "Failed to mutate URL request",
          arguments: [
            ("requestID", self.requestID),
            ("error.reason", (mutatorError as? PubNubError)?.reason ?? "Unknown reason")
          ]
        )
      ), category: .networking
    )
    logger.trace(
      .customObject(
        .init(
          operation: "request-mutate-fail",
          details: "Failed to mutate URL request",
          arguments: [
            ("requestID", self.requestID),
            ("error", mutatorError)
          ]
        )
      ), category: .networking
    )

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
    logger.error(
      .customObject(
        .init(
          operation: "request-create-fail",
          details: "Failed to create URLRequest",
          arguments: [("requestID", self.requestID)]
        )
      ), category: .networking
    )

    logger.trace(
      .customObject(
        .init(
          operation: "request-create-fail",
          details: "Failed to create URLRequest",
          arguments: [("requestID", self.requestID), ("error", error)]
        )
      ), category: .networking
    )

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
    let request: URLRequest? = task.currentRequest

    logger.trace(
      .networkRequest(
        .init(
          id: self.requestID.uuidString,
          origin: request?.url?.host ?? "Unknown origin",
          path: request?.url?.path ?? "Unknown path",
          query: task.getURLQueryItems().reduce(into: [String: String]()) { $0[$1.name] = $1.value },
          method: request?.httpMethod ?? "Unknown HTTP method",
          headers: request?.allHTTPHeaderFields ?? [:],
          body: request?.httpBody,
          details: nil,
          isCompleted: false,
          isCancelled: false,
          isFailed: false
        )
      ), category: .networking
    )

    sessionStream?.emitRequest(
      self,
      didResume: task
    )
  }

  func didCancel(_ task: URLSessionTask) {
    sessionStream?.emitRequest(self, didCancel: task)
  }

  func didComplete(_ task: URLSessionTask) {
    // Log the request completion
    logRequestCompletion(task: task, error: nil)
    // Process the Validators for any additional errors
    atomicValidators.lockedRead { $0.forEach { $0() } }

    if let error = error {
      sessionStream?.emitRequest(self, didComplete: task, with: error)
      retryOrFinish(with: error)
    } else {
      sessionStream?.emitRequest(self, didComplete: task)
      finish()
    }
  }

  func didComplete(_ task: URLSessionTask, with error: Error) {
    logRequestCompletion(task: task, error: error)

    self.error = PubNubError.sessionDelegate(error, router: router)
    sessionStream?.emitRequest(self, didComplete: task, with: error)
    retryOrFinish(with: error)
  }

  private func logRequestCompletion(task: URLSessionTask, error: Error?) {
    let request = task.currentRequest
    let response = task.response as? HTTPURLResponse

    if let error = error, !error.isCancellationError {
      logger.error(
        .customObject(
          .init(
            operation: "network-request-failed",
            details: "Network request completed with error",
            arguments: [
              ("requestID", self.requestID.uuidString),
              ("host", request?.url?.host ?? "unknown"),
              ("method", request?.httpMethod ?? "unknown"),
              ("statusCode", response?.statusCode ?? 0)
            ]
          )
        ), category: .networking
      )
    }

    logger.trace(
      .networkRequest(
        .init(
          id: self.requestID.uuidString,
          origin: request?.url?.host ?? "Unknown origin",
          path: request?.url?.path ?? "Unknown path",
          query: task.getURLQueryItems().reduce(into: [String: String]()) { $0[$1.name] = $1.value },
          method: request?.httpMethod ?? "Unknown HTTP method",
          headers: request?.allHTTPHeaderFields ?? [:],
          body: request?.httpBody,
          details: error?.localizedDescription,
          isCompleted: false,
          isCancelled: error?.isCancellationError ?? false,
          isFailed: error != nil
        )
      ), category: .networking
    )

    logger.trace(
      .networkResponse(
        .init(
          id: self.requestID.uuidString,
          url: request?.url,
          status: response?.statusCode ?? 0,
          headers: request?.allHTTPHeaderFields ?? [:],
          body: self.data,
          details: nil
        )
      ), category: .networking
    )
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
        self.atomicState.lockedWrite { $0.responesData = nil }
        delegate.retryRequest(self, withDelay: retryAfter)
      case let .failure(error):
        self.finish(error: PubNubError.retry(error, router: self.router))
      }
    }
  }

  func finish(error _: Error? = nil) {
    if let error = error, !error.isCancellationError {
      let responseMessage = if let response = urlResponse {
        response.description
      } else {
        "No response available"
      }

      logger.error(
        .customObject(
          .init(
            operation: "request-failed",
            details: "Request failed",
            arguments: [
              ("requestID", self.requestID.uuidString),
              ("hasResponse", self.urlResponse != nil),
              ("statusCode", self.urlResponse?.statusCode ?? 0)
            ]
          )
        ), category: .networking
      )
    }

    if let error = error {
      processResponseCompletion(.failure(error))
      return
    }

    processResponseCompletion(atomicState.lockedRead { state -> Result<EndpointResponse<Data>, Error> in
      if let error = state.error {
        return .failure(error)
      }
      if let request = state.urlRequests.last, let response = state.tasks.last?.httpResponse, let data = state.responesData {
        return .success(
          EndpointResponse(
            router: router,
            request: request,
            response: response,
            payload: data
          )
        )
      }
      return .failure(
        PubNubError(
          .missingCriticalResponseData,
          router: router
        )
      )
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
      guard
        self?.error == nil,
        let request = self?.urlRequest,
        let response = self?.urlResponse,
        let router = self?.router,
        let data = self?.data
      else {
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
  func retryRequest(
    _ request: RequestReplaceable,
    withDelay timeDelay: TimeInterval?
  )
}

// MARK: - Private Extensions

private extension URLSessionTask {
  func getURLQueryItems() -> [URLQueryItem] {
    let components: URLComponents? = if let url = self.currentRequest?.url {
      URLComponents(url: url, resolvingAgainstBaseURL: false)
    } else {
      nil
    }

    return components?.queryItems ?? []
  }
}

// swiftlint:disable:this file_length
