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
  ///  The delegate assigned when this object was created.
  var delegate: URLSessionDelegate? { get }
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
  /// Creates a task that performs an HTTP request for uploading the specified file.
  ///
  ///  An HTTP upload request is any request that contains a request body, such as a POST or PUT request. Upload tasks require you to create a request object so that you can provide metadata for the upload, like HTTP request headers.
  ///
  ///  After you create the task, you must start it by calling its `resume()` method. The task calls methods on the session’s delegate to provide you with the upload’s progress, response metadata, response data, and so on.
  ///
  /// - Parameters:
  ///   - request: A URL request object that provides the URL, cache policy, request type, and so on.
  /// - Returns: The new session data task.
  func uploadTask(withStreamedRequest request: URLRequest) -> URLSessionUploadTask
  /// Creates a task that performs an HTTP request for uploading the specified file.
  ///
  ///  An HTTP upload request is any request that contains a request body, such as a POST or PUT request. Upload tasks require you to create a request object so that you can provide metadata for the upload, like HTTP request headers.
  ///
  ///  After you create the task, you must start it by calling its resume() method. The task calls methods on the session’s delegate to provide you with the upload’s progress, response metadata, response data, and so on.
  ///
  /// - Parameters:
  ///   - request: A URL request object that provides the URL, cache policy, request type, and so on. The body stream and body data in this request object are ignored.
  ///   - fileURL: The URL of the file to upload.
  /// - Returns: The new session data task.
  func uploadTask(with request: URLRequest, fromFile fileURL: URL) -> URLSessionUploadTask
  /// Creates a download task that retrieves the contents of a URL based on the specified URL request object and saves the results to a file.
  ///
  ///  After you create the task, you must start it by calling its resume() method.
  ///
  /// - Parameter url: The URL to download.
  /// - Returns: The new session download task.
  func downloadTask(with url: URL) -> URLSessionDownloadTask
  /// Creates a download task that retrieves the contents of a URL based on the specified URL request object and saves the results to a file.
  ///
  ///  After you create the task, you must start it by calling its resume() method.
  ///
  ///  For detailed usage information, including ways to obtain a resume data object, see
  ///  [Pausing and Resuming Downloads](https://developer.apple.com/documentation/foundation/url_loading_system/pausing_and_resuming_downloads)
  ///
  /// - Parameter resumeData: A data object that provides the data necessary to resume a download.
  /// - Returns: The new session download task.
  func downloadTask(withResumeData resumeData: Data) -> URLSessionDownloadTask
  /// Cancels all outstanding tasks and then invalidates the session.
  ///
  /// Once invalidated, references to the delegate and callback objects are broken. After invalidation,
  /// session objects cannot be reused.
  /// - Important: Calling this method on the session returned by the shared method has no effect.
  func invalidateAndCancel()
}

extension URLSessionReplaceable {
  /// Whether the URLSession represented will perform requests in the background
  var makesBackgroundRequests: Bool {
    return configuration.identifier != nil
  }
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

  func route<Decoder>(
    _ router: HTTPRouter,
    responseDecoder: Decoder,
    responseQueue: DispatchQueue,
    completion: @escaping (Result<EndpointResponse<Decoder.Payload>, Error>) -> Void
  ) where Decoder: ResponseDecoder
}

public extension SessionReplaceable {
  func route<Decoder>(
    _ router: HTTPRouter,
    responseDecoder: Decoder,
    responseQueue: DispatchQueue = .main,
    completion: @escaping (Result<EndpointResponse<Decoder.Payload>, Error>) -> Void
  ) where Decoder: ResponseDecoder {
    request(with: router, requestOperator: nil)
      .validate()
      .response(
        on: responseQueue,
        decoder: responseDecoder,
        completion: completion
      )
  }

  func invalidateAndCancel() { /* no-op */ }
  func usingDefault(requestOperator _: RequestOperator?) -> Self {
    return self
  }
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

public extension RequestReplaceable {
  func didCreate(_: URLRequest) { /* no-op */ }
  func didFailToCreateURLRequest(with _: Error) { /* no-op */ }
  func didCreate(_: URLSessionTask) { /* no-op */ }

  func didMutate(_: URLRequest, to _: URLRequest) { /* no-op */ }
  func didFailToMutate(_: URLRequest, with _: Error) { /* no-op */ }

  func didReceive(data _: Data) { /* no-op */ }
  func didComplete(_: URLSessionTask) { /* no-op */ }
  func didComplete(_: URLSessionTask, with _: Error) { /* no-op */ }
  func prepareForRetry() { /* no-op */ }

  func cancel(_: Error) -> Self {
    return self
  }

  func validate() -> Self {
    return self
  }

  func response<D: ResponseDecoder>(
    on _: DispatchQueue,
    decoder _: D,
    completion _: @escaping (Result<EndpointResponse<D.Payload>, Error>) -> Void
  ) {
    /* no-op */
  }
}

extension Request: RequestReplaceable {}
