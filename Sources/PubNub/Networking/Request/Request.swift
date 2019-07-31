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

public final class Request {
  enum TaskState: CustomStringConvertible {
    case initialized
    case resumed
    case cancelled
    case finished

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
      switch self {
      case .initialized:
        return "Initialized"
      case .resumed:
        return "Resumed"
      case .cancelled:
        return "Cancelled"
      case .finished:
        return "Finished"
      }
    }
  }

  struct InternalState {
    var taskState: TaskState = .initialized

    var responseProcessingFinished = false
    var responseCompletionClosure: (() -> Void)?

    var tasks: [URLSessionTask] = []

    var urlRequests: [URLRequest] = []
    var error: Error?
    var previousErrors: [Error] = []

    var retryCount = 0

    var responesData: Data?
  }

  public let requestID: UUID = UUID()
  public let router: Router
  public let requestQueue: DispatchQueue
  public let requestOperator: RequestOperator?

  public private(set) weak var delegate: RequestDelegate?
  let sessionStream: SessionStream?

  let atomicState: Atomic<InternalState> = Atomic(InternalState())

  private var atomicValidators: Atomic<[() -> Void]> = Atomic([])

  public init(
    with router: Router,
    requestQueue: DispatchQueue,
    sessionStream: SessionStream?,
    requestOperator: RequestOperator? = nil,
    delegate: RequestDelegate
  ) {
    self.router = router
    self.requestQueue = requestQueue
    self.sessionStream = sessionStream
    self.requestOperator = requestOperator
    self.delegate = delegate
  }

  public var urlRequests: [URLRequest] {
    return atomicState.lockedRead { $0.urlRequests }
  }

  public var urlRequest: URLRequest? {
    return urlRequests.last
  }

  public var tasks: [URLSessionTask] {
    return atomicState.lockedRead { $0.tasks }
  }

  public var task: URLSessionTask? {
    return tasks.last
  }

  public var urlResponse: HTTPURLResponse? {
    return task?.response as? HTTPURLResponse
  }

  public var data: Data? {
    return atomicState.lockedRead { $0.responesData }
  }

  public private(set) var error: Error? {
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

  public var previousErrors: [Error] {
    return atomicState.lockedRead { $0.previousErrors }
  }

  public var previousError: Error? {
    return previousErrors.last
  }

  public var retryCount: Int {
    return atomicState.lockedRead { $0.retryCount }
  }

  public var isCancelled: Bool {
    return atomicState.lockedRead { $0.taskState == .cancelled }
  }

  func withTaskState(perform closure: (TaskState) -> Void) {
    atomicState.lockedWrite { closure($0.taskState) }
//    atomicState.withTaskState(perform: closure)
  }

  // MARK: - Request Processing

  func didMutate(_ initialRequest: URLRequest, to mutatedRequest: URLRequest) {
    atomicState.lockedWrite { $0.urlRequests.append(mutatedRequest) }

    sessionStream?.emitRequest(self, didMutate: initialRequest, to: mutatedRequest)
  }

  func didFailToMutate(_ urlRequest: URLRequest, with mutatorError: PNError) {
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
    self.error = error

    sessionStream?.emitRequest(self, didFailToCreateURLRequestWith: error)

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
  }

  func didResume(_ task: URLSessionTask) {
    sessionStream?.emitRequest(self, didResume: task)
  }

  func didCancel(_ task: URLSessionTask) {
    sessionStream?.emitRequest(self, didCancel: task)
  }

  func didComplete(_ task: URLSessionTask) {
    atomicValidators.lockedRead { $0.forEach { $0() } }

    sessionStream?.emitRequest(self, didComplete: task)

    retryOrFinish(with: error)
  }

  func didComplete(_ task: URLSessionTask, with error: Error) {
    self.error = error

    sessionStream?.emitRequest(self, didComplete: task, with: error)

    retryOrFinish(with: error)
  }

  // MARK: - SessionDelegate Events

  func didReceive(data: Data) {
    // Set the data value
    if self.data == nil {
      atomicState.lockedWrite { $0.responesData = data }
    }
  }

  func retryOrFinish(with error: Error?) {
    guard let error = error, let delegate = delegate else {
      finish()
      return
    }

    delegate.retryResult(for: self, dueTo: error, andPrevious: previousError) { retryResult in
      if retryResult.isRequired {
        delegate.retryRequest(self, withDelay: retryResult.delay)
      } else {
        self.finish(error: retryResult.error)
      }
    }
  }

  // MARK: - URLSessionTask State Actions

  @discardableResult
  public func resume() -> Self {
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
  public func cancel(with cancellationError: Error) -> Self {
    atomicState.lockedWrite { mutableState in
      guard mutableState.taskState.canTransition(to: .cancelled) else {
        return
      }

      mutableState.taskState = .cancelled

      self.requestQueue.async { self.didCancel() }

      mutableState.error = cancellationError

      guard let task = mutableState.tasks.last, task.state != .completed else {
        self.requestQueue.async { self.finish() }
        return
      }

      task.cancel()

      self.requestQueue.async { self.didCancel(task) }
    }

    return self
  }

  func finish(error: Error? = nil) {
    if let error = error { self.error = error }

    processResponseCompletion()

    didFinish()
  }

  // MARK: - First-class Operators

  public typealias ValidationClosure = (URLRequest, HTTPURLResponse, Data?) -> Error?

  func validate(_ closure: @escaping ValidationClosure) -> Self {
    let validator: () -> Void = { [unowned self] in
      guard self.error == nil, let request = self.urlRequest, let response = self.urlResponse else {
        return
      }

      if let validationError = closure(request, response, self.data) {
        self.error = validationError
      }
    }

    atomicValidators.append(validator)

    return self
  }

  public func validate() -> Self {
    let router = self.router
    return validate { request, response, data in
      if !response.isSuccessful {
        return router.decodeError(request: request, response: response, for: data)
      }
      return nil
    }
  }
}

// MARK: - Hashable

extension Request: Hashable {
  public static func == (lhs: Request, rhs: Request) -> Bool {
    return lhs.requestID == rhs.requestID
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(requestID)
  }
}

// MARK: - RequestDelegate

public protocol RequestDelegate: AnyObject {
  func retryResult(
    for request: Request,
    dueTo error: Error,
    andPrevious error: Error?,
    completion: @escaping (RetryResult) -> Void
  )

  func retryRequest(_ request: Request, withDelay timeDelay: TimeInterval?)
}
