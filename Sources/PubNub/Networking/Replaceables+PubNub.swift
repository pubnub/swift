//
//  Replaceables+PubNub.swift
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

// MARK: - URLSession

/// An object capable of replacing a `URLSession`
public protocol URLSessionReplaceable {
  /// Creates a session with the specified session configuration, delegate, and operation queue.
  init(configuration: URLSessionConfiguration, delegate: URLSessionDelegate?, delegateQueue: OperationQueue?)
  /// An app-defined descriptive label for the session.
  var sessionDescription: String? { get set }
  /// The operation queue provided when this object was created.
  var delegateQueue: OperationQueue { get }
  /// A configuration object that defines behavior and policies for an URL session.
  var configuration: URLSessionConfiguration { get }
  /// Creates a task that retrieves the contents of an URL based on the specified URL request object.
  ///
  /// By creating a task based on a request object, you can tune various aspects of the task’s behavior,
  /// including the cache policy and timeout interval.
  ///
  /// After you create the task, you must start it by calling its resume() method.
  ///
  /// - Parameter with: an URL request object that provides request-specific information such as the URL,
  /// cache policy, request type, and body data or body stream.
  /// - Returns: The new session data task.
  func dataTask(with request: URLRequest) -> URLSessionDataTask
  /// Cancels all outstanding tasks and then invalidates the session.
  ///
  /// Once invalidated, references to the delegate and callback objects are broken. After invalidation,
  /// session objects cannot be reused.
  /// - Important: Calling this method on the session returned by the shared method has no effect.
  func invalidateAndCancel()
}

extension URLSession: URLSessionReplaceable {}

// MARK: - Session

/// An object capable of replacing a `Session`
public protocol SessionReplaceable {
  /// The unique identifier for this object
  var sessionID: UUID { get }
  /// The underlying `URLSession` used to execute the network tasks
  var session: URLSessionReplaceable { get }
  /// The dispatch queue used to execute session operations
  var sessionQueue: DispatchQueue { get }
  /// The `RequestOperator` that is attached to every request
  var defaultRequestOperator: RequestOperator? { get set }

  var sessionStream: SessionStream? { get set }

  /// The method used to set the default `RequestOperator`
  ///
  /// - parameter requestOperator: The default `RequestOperator`
  /// - returns: This `Session` object
  func usingDefault(requestOperator: RequestOperator?) -> Self
  /// Creates and performs a request using the provided router
  ///
  /// - parameters:
  ///   -  with: The `Router` used to create the `Request`
  ///   -  requestOperator: The operator specific to this `Request`
  /// - returns: This created `Request`
  func request(with router: HTTPRouter, requestOperator: RequestOperator?) -> RequestReplaceable
  /// Cancels all outstanding tasks and then invalidates the session.
  ///
  /// Once invalidated, references to the delegate and callback objects are broken.
  /// After invalidation, session objects cannot be reused.
  /// - Important: Calling this method on the session returned by the shared method has no effect.
  func invalidateAndCancel()
}

extension HTTPSession: SessionReplaceable {}

public protocol RequestReplaceable: AnyObject {
  var sessionID: UUID { get }
  var requestID: UUID { get }
  var router: HTTPRouter { get }
  var requestQueue: DispatchQueue { get }
  var requestOperator: RequestOperator? { get }

  var urlRequest: URLRequest? { get }
  var urlResponse: HTTPURLResponse? { get }

  func didCreate(_ urlRequest: URLRequest)
  func didFailToCreateURLRequest(with error: Error)
  func didCreate(_ task: URLSessionTask)

  func didMutate(_ initialRequest: URLRequest, to mutatedRequest: URLRequest)
  func didFailToMutate(_ urlRequest: URLRequest, with mutatorError: Error)

  func didReceive(data: Data)
  func didComplete(_ task: URLSessionTask)
  func didComplete(_ task: URLSessionTask, with error: Error)

  var retryCount: Int { get }
  var isCancelled: Bool { get }
  func prepareForRetry()

  @discardableResult
  func cancel(_ error: Error) -> Self
  func validate() -> Self
  /// The directions on how to process the response when it comes back from the `Endpoint`
  ///
  /// - Parameters:
  ///   - on: The queue the completion block will be returned on
  ///   - decoder: The decoder used to determine the response type
  ///   - completion: The completion block being returned with the decode response data or the error that occurred
  func response<D: ResponseDecoder>(
    on: DispatchQueue,
    decoder: D,
    completion: @escaping (Result<EndpointResponse<D.Payload>, Error>) -> Void
  )
}

extension Request: RequestReplaceable {}
