//
//  HTTPSessionDelegate.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A protocol defining a bridge to an implementation of `URLSessionDataDelegate` for receiving delegation events
public class HTTPSessionDelegate: NSObject {
  weak var sessionBridge: SessionStateBridge?
}

extension HTTPSessionDelegate: URLSessionDataDelegate {
  // MARK: - URLSessionDelegate

  // Task was invalidated by the session directly
  public func urlSession(_: URLSession, didBecomeInvalidWithError error: Error?) {
    PubNub.log.warn("Session Invalidated \(String(describing: sessionBridge?.sessionID))")

    // Set invalidated in case this happened unexpectedly
    sessionBridge?.isInvalidated = true

    sessionBridge?.sessionInvalidated(with: error)
  }

  // Called when the request fails.
  public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    // Lookup the request
    guard let request = sessionBridge?.request(for: task) else {
      return
    }

    if let error = error {
      if error.isCancellationError {
        request.cancel(PubNubError(.clientCancelled, router: request.router, underlying: error))
      } else {
        request.didComplete(task, with: error)
      }
    } else {
      request.didComplete(task)
    }

    // Remove request/task from list
    sessionBridge?.didComplete(task)

    sessionBridge?.sessionStream?.emitURLSession(session, task: task, didCompleteWith: error)
  }

  // MARK: - URLSessionDataDelegate

  public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    if let request = sessionBridge?.request(for: dataTask) {
      request.didReceive(data: data)
    }

    sessionBridge?.sessionStream?.emitURLSession(session, dataTask: dataTask, didReceive: data)
  }

  public func urlSession(
    _ session: URLSession,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
  ) {
    sessionBridge?.sessionStream?.emitURLSession(session, didReceive: challenge)

    completionHandler(.performDefaultHandling, nil)
  }
}

/// A bridge between a `Session` and a corresponding `SessionDelegate`
protocol SessionStateBridge: AnyObject {
  /// The value that uniquely identifies the `Session`
  var sessionID: UUID { get }
  /// The event stream that session activity status will emit to
  var sessionStream: SessionStream? { get }
  /// True if the underlying session is invalidated and can no longer perform requests
  var isInvalidated: Bool { get set }
  /// Performs a lookup to find the associated `Request` for a given `URLSessionTask`
  ///
  /// - parameter for: The `URLSessionTask` used as a lookup key
  /// - returns: The `Request` that is associated with the given `URLSessionTask`
  func request(for task: URLSessionTask) -> RequestReplaceable?
  /// Event that notifies a given `URLSessionTask` has completed
  func didComplete(_ task: URLSessionTask)
  /// Event that notifies the underlying `URLSession` has become invalid
  func sessionInvalidated(with error: Error?)
}

extension HTTPSession: SessionStateBridge {
  func request(for task: URLSessionTask) -> RequestReplaceable? {
    return taskToRequest[task]
  }

  func didComplete(_ task: URLSessionTask) {
    // Cleanup the task/requst map
    taskToRequest.removeValue(forKey: task)
  }

  func sessionInvalidated(with error: Error?) {
    // Notify the requests that the tasks have been invalidated
    taskToRequest.values.forEach {
      $0.cancel(PubNubError(.sessionInvalidated, router: $0.router, underlying: error))
    }

    // Clean up the task dictionary
    taskToRequest.removeAll()
  }
}
