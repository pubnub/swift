//
//  Session.swift
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

// MARK: - PubNub Networking

public final class Session {
  public let sessionID: UUID = UUID()
  public let session: URLSessionReplaceable
  public let sessionQueue: DispatchQueue
  public let requestQueue: DispatchQueue

  weak var delegate: SessionDelegate?
  let sessionStream: SessionStream?
  let sessionRequestOperator: RequestOperator?

  // Internal
  var taskToRequest: [URLSessionTask: Request] = [:]

  public init(
    session: URLSessionReplaceable,
    delegate: SessionDelegate,
    sessionQueue: DispatchQueue,
    requestQueue: DispatchQueue? = nil,
    requestOperator: RequestOperator? = nil,
    sessionStream: SessionStream? = nil
  ) {
    precondition(session.delegateQueue.underlyingQueue === sessionQueue,
                 "Session.sessionQueue must be the same DispatchQueue used as the URLSession.delegate underlyingQueue")

    self.session = session
    self.sessionQueue = sessionQueue
    self.requestQueue = requestQueue ?? DispatchQueue(label: "com.pubnub.session.requestQueue", target: sessionQueue)
    sessionRequestOperator = requestOperator

    self.delegate = delegate
    self.sessionStream = sessionStream

    delegate.sessionBridge = self
  }

  public convenience init(
    configuration: URLSessionConfiguration = .ephemeral,
    delegate: SessionDelegate = SessionDelegate(),
    sessionQueue: DispatchQueue = DispatchQueue(label: "com.pubnub.session.sessionQueue"),
    requestQueue: DispatchQueue? = nil,
    requestOperator: RequestOperator? = nil,
    sessionStream: SessionStream? = nil
  ) {
    let delegateQueue = OperationQueue(maxConcurrentOperationCount: 1,
                                       underlyingQueue: sessionQueue,
                                       name: "org.pubnub.httpClient.URLSessionReplaceableDelegate")

    let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)

    self.init(session: session,
              delegate: delegate,
              sessionQueue: sessionQueue,
              requestQueue: requestQueue,
              requestOperator: requestOperator,
              sessionStream: sessionStream)
  }

  deinit {
    taskToRequest.values.forEach { $0.finish(error: PNError.sessionDeinitialized(for: sessionID)) }
    taskToRequest.removeAll()
    session.invalidateAndCancel()
  }

  // MARK: -

  public func request(
    with router: Router,
    requestOperator: RequestOperator? = nil
  ) -> Request {
    let request = Request(with: router,
                          requestQueue: sessionQueue,
                          sessionStream: sessionStream,
                          requestOperator: requestOperator,
                          delegate: self)

    perform(request)

    return request
  }

  func perform(_ request: Request) {
    requestQueue.async {
      // Ensure that the request hasn't been cancelled
      if request.isCancelled { return }

      self.perform(request, urlRequest: request.router)
    }
  }

  // This could also be called from retrier, so we don't want to consolidate
  func perform(_ request: Request, urlRequest convertible: URLRequestConvertible) {
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
    if let mutator = self.mutator(for: request) {
      mutator.mutate(urlRequest, for: self) { result in
        switch result {
        case let .success(mutatedRequest):
          self.sessionQueue.async {
            request.didMutate(urlRequest, to: mutatedRequest)
            self.didCreateURLRequest(urlRequest, for: request)
          }
        case let .failure(error):
          self.sessionQueue.async {
            let requestCreationError = PNError
              .requestCreationFailure(
                .requestMutatorFailure(urlRequest, error))

            request.didFailToMutate(urlRequest,
                                    with: requestCreationError)
          }
        }
      }
    } else {
      sessionQueue.async {
        self.didCreateURLRequest(urlRequest, for: request)
      }
    }
  }

  func didCreateURLRequest(_ urlRequest: URLRequest, for request: Request) {
    if request.isCancelled { return }

    // Leak inside URLSession; passing in copy to avoid passing in managed objects
    let urlRequestCopy = urlRequest
    let task = session.dataTask(with: urlRequestCopy)
    taskToRequest[task] = request
    request.didCreate(task)

    updateStatesForTask(task, request: request)
  }

  func updateStatesForTask(_ task: URLSessionTask, request: Request) {
    request.withTaskState { atomicState in
      switch atomicState {
      case .initialized:
        sessionQueue.async { request.resume() }
      case .resumed:
        // URLDataTasks cannot be 'resumed' after starting
        break
      case .cancelled:
        task.cancel()
        sessionQueue.async { request.didCancel(task) }
      case .finished:
        // Do nothing
        break
      }
    }
  }

  func mutator(for request: Request) -> RequestMutator? {
    if let requestInterceptor = request.requestOperator, let sessionInterceptor = sessionRequestOperator {
      return MultiplexRequestOperaptor(mutators: [requestInterceptor, sessionInterceptor])
    } else {
      return request.requestOperator ?? sessionRequestOperator
    }
  }

  func retrier(for request: Request) -> RequestRetrier? {
    if let requestOperator = request.requestOperator, let sessionInterceptor = sessionRequestOperator {
      return MultiplexRequestOperaptor(retriers: [requestOperator, sessionInterceptor])
    } else {
      return request.requestOperator ?? sessionRequestOperator
    }
  }

  func cancelAllTasks(with cancellationError: PNError) {
    taskToRequest.values.forEach { $0.cancel(with: cancellationError) }
  }
}

// MARK: - RequestDelegate

extension Session: RequestDelegate {
  public func retryResult(for request: Request, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
    guard let retrier = retrier(for: request) else {
      sessionQueue.async { completion(.doNotRetry) }
      return
    }

    retrier.retry(request, for: self, dueTo: error) { retryResult in
      self.sessionQueue.async {
        guard let retryResultError = retryResult.error, let urlRequest = request.urlRequest else {
          completion(retryResult)
          return
        }

        completion(.doNotRetryWithError(PNError.requestRetryFailed(urlRequest,
                                                                   dueTo: retryResultError,
                                                                   withPreviousError: error)))
      }
    }
  }

  public func retryRequest(_ request: Request, withDelay timeDelay: TimeInterval?) {
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
