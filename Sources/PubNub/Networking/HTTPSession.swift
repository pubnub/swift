//
//  HTTPSession.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - PubNub Networking

/// An object that coordinates a group of related network data transfer tasks.
public final class HTTPSession {
  /// The unique identifier for this object
  public let sessionID = UUID()
  /// The underlying `URLSession` used to execute the network tasks
  public let session: URLSessionReplaceable
  /// The dispatch queue used to execute session operations
  public let sessionQueue: DispatchQueue
  /// The dispatch queue used to execute request operations
  let requestQueue: DispatchQueue
  /// The state that tracks the validity of the underlying `URLSessionReplaceable`
  let invalidationState = AtomicInt(0)
  /// The delegate that receives incoming network transmissions
  weak var delegate: HTTPSessionDelegate?
  /// The event stream that session activity status will emit to
  public var sessionStream: SessionStream?
  /// The `RequestOperator` that is attached to every request
  public var defaultRequestOperator: RequestOperator?
  /// The collection of associations between `URLSessionTask` and their corresponding `Request`
  var taskToRequest: [URLSessionTask: RequestReplaceable] = [:]

  /// Default HTTPSession configuration for PubNub REST endpoints
  static var pubnub = HTTPSession(configuration: .pubnub)

  init(
    session: URLSessionReplaceable,
    delegate: HTTPSessionDelegate,
    sessionQueue: DispatchQueue,
    requestQueue: DispatchQueue? = nil,
    sessionStream: SessionStream? = nil
  ) {
    precondition(session.delegateQueue.underlyingQueue === sessionQueue,
                 "Session.sessionQueue must be the same DispatchQueue used as the URLSession.delegate underlyingQueue")

    self.session = session
    self.sessionQueue = sessionQueue
    self.requestQueue = requestQueue ?? DispatchQueue(label: "com.pubnub.session.requestQueue", target: sessionQueue)

    self.delegate = delegate
    self.sessionStream = sessionStream

    PubNub.log.debug("Session created \(sessionID)")

    delegate.sessionBridge = self
  }

  public convenience init(
    configuration: URLSessionConfiguration = .ephemeral,
    delegate: HTTPSessionDelegate = HTTPSessionDelegate(),
    sessionQueue: DispatchQueue = DispatchQueue(label: "com.pubnub.session.sessionQueue"),
    requestQueue: DispatchQueue? = nil,
    sessionStream: SessionStream? = nil
  ) {
    let delegateQueue = OperationQueue(maxConcurrentOperationCount: 1,
                                       underlyingQueue: sessionQueue,
                                       name: "org.pubnub.httpClient.URLSessionReplaceableDelegate")

    let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
    session.sessionDescription = "Underlying URLSession for: com.pubnub.session"

    self.init(session: session,
              delegate: delegate,
              sessionQueue: sessionQueue,
              requestQueue: requestQueue,
              sessionStream: sessionStream)
  }

  deinit {
    PubNub.log.debug("Session Destroyed \(sessionID) with active requests \(taskToRequest.values.map { $0.requestID })")

    taskToRequest.values.forEach {
      $0.cancel(PubNubError(.sessionDeinitialized, router: $0.router))
    }

    invalidateAndCancel()
  }

  // MARK: - Self Operators

  /// The method used to set the default `RequestOperator`
  ///
  /// - parameter requestOperator: The default `RequestOperator`
  /// - returns: This `Session` object
  public func usingDefault(requestOperator: RequestOperator?) -> Self {
    defaultRequestOperator = requestOperator
    return self
  }

  // MARK: - Perform Request

  /// Creates and performs a request using the provided router
  ///
  /// - parameters:
  ///   -  with: The `Router` used to create the `Request`
  ///   -  requestOperator: The operator specific to this `Request`
  /// - returns: This created `Request`
  public func request(
    with router: HTTPRouter,
    requestOperator: RequestOperator? = nil
  ) -> RequestReplaceable {
    let request = Request(with: router,
                          requestQueue: sessionQueue,
                          sessionStream: sessionStream,
                          requestOperator: requestOperator,
                          delegate: self,
                          createdBy: sessionID)

    perform(request)

    return request
  }

  // MARK: Internal Methods

  func perform(_ request: RequestReplaceable) {
    requestQueue.async {
      // Ensure that the request hasn't been cancelled
      if request.isCancelled { return }

      self.perform(request, urlRequest: request.router)
    }
  }

  func perform(_ request: RequestReplaceable, urlRequest convertible: URLRequestConvertible) {
    // Perform the request.  (SessionDelegate will emit the response)
    let urlRequest: URLRequest

    // Create the URLRequest
    switch convertible.asURLRequest {
    case let .success(convertURLRequest):
      urlRequest = convertURLRequest
      sessionQueue.async {
        request.didCreate(convertURLRequest)
      }
    case let .failure(error):
      sessionQueue.async {
        request.didFailToCreateURLRequest(with: error)
      }
      return
    }

    // Ensure that the request hasn't been cancelled
    if request.isCancelled { return }

    // Perform any provided request mutations
    sessionQueue.async { [weak self] in
      if let strongSelf = self, let mutator = strongSelf.mutator(for: request) {
        mutator.mutate(urlRequest, for: strongSelf) { result in
          switch result {
          case let .success(mutatedRequest):
            request.didMutate(urlRequest, to: mutatedRequest)
            self?.didCreateURLRequest(mutatedRequest, for: request)
          case let .failure(error):
            request.didFailToMutate(urlRequest, with: error)
          }
        }
      } else {
        self?.didCreateURLRequest(urlRequest, for: request)
      }
    }
  }

  /// True if the underlying session is invalidated and can no longer perform requests
  var isInvalidated: Bool {
    get {
      return invalidationState.isEqual(to: 1)
    }
    set {
      invalidationState.bitwiseOrAssignemnt(newValue ? 1 : 0)
    }
  }

  func didCreateURLRequest(_ urlRequest: URLRequest, for request: RequestReplaceable) {
    if request.isCancelled { return }

    // Leak inside URLSession; passing in copy to avoid passing in managed objects
    let urlRequestCopy = urlRequest

    // URLSession doesn't provide a way to check if it's invalidated,
    // so we lock to avoid crashes from creating tasks while invalidated
    if !isInvalidated {
      let task = session.dataTask(with: urlRequestCopy)
      taskToRequest[task] = request
      request.didCreate(task)
    } else {
      PubNub.log.warn("Attempted to create task from invalidated session: \(sessionID)")
    }
  }

  func mutator(for request: RequestReplaceable) -> RequestMutator? {
    if let requestOperator = request.requestOperator, let sessionOperator = defaultRequestOperator {
      return MultiplexRequestOperator(operators: [requestOperator, sessionOperator])
    } else {
      return request.requestOperator ?? defaultRequestOperator
    }
  }

  func retrier(for request: RequestReplaceable) -> RequestRetrier? {
    if let requestOperator = request.requestOperator, let sessionOperator = defaultRequestOperator {
      return MultiplexRequestOperator(operators: [requestOperator, sessionOperator])
    } else {
      return request.requestOperator ?? defaultRequestOperator
    }
  }

  /// Cancels all outstanding tasks and then invalidates the session.
  ///
  /// Once invalidated, references to the delegate and callback objects are broken.
  /// After invalidation, session objects cannot be reused.
  /// - Important: Calling this method on the session returned by the shared method has no effect.
  public func invalidateAndCancel() {
    // Ensure that we lock out task creation prior to invalidating
    isInvalidated = true

    session.invalidateAndCancel()
  }
}

// MARK: - RequestDelegate

extension HTTPSession: RequestDelegate {
  func retryResult(
    for request: RequestReplaceable,
    dueTo error: Error,
    andPrevious _: Error?,
    completion: @escaping (Result<TimeInterval, Error>) -> Void
  ) {
    // Immediately return error if we don't have any retry logic
    guard let retrier = retrier(for: request) else {
      sessionQueue.async { completion(.failure(error)) }
      return
    }

    PubNub.log.info("Retrying request \(request.requestID) due to error \(error)")

    retrier.retry(request, for: self, dueTo: error) { [weak self] retryResult in
      self?.sessionQueue.async {
        completion(retryResult)
      }
    }
  }

  func retryRequest(_ request: RequestReplaceable, withDelay timeDelay: TimeInterval?) {
    sessionQueue.async {
      let retry: () -> Void = {
        if request.isCancelled { return }

        request.prepareForRetry()

        self.perform(request)
      }

      if let retryDelay = timeDelay {
        self.sessionQueue.asyncAfter(deadline: .now() + retryDelay) {
          retry()
        }
      } else {
        retry()
      }
    }
  }
}
