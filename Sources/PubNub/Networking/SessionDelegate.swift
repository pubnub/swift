//
//  SessionDelegate.swift
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

public class SessionDelegate: NSObject {
  weak var sessionBridge: SessionStateBridge?
}

extension SessionDelegate: URLSessionDataDelegate {
  // MARK: - URLSessionDelegate

  // Task was invalidated by the session directly
  public func urlSession(_: URLSession, didBecomeInvalidWithError error: Error?) {
    if let error = error {
      sessionBridge?.cancelRequests(for: .sessionInvalidated(.implicit(dueTo: error),
                                                             sessionID: sessionBridge?.sessionID))
    } else {
      sessionBridge?.cancelRequests(for: .sessionInvalidated(.explicit,
                                                             sessionID: sessionBridge?.sessionID))
    }
  }

  // Called when the request fails.
  public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    // Lookup the request
    let request = sessionBridge?.request(for: task)

    if let urlError = error?.urlError,
      let pnError = PNError.convert(error: urlError,
                                    request: request?.urlRequest,
                                    response: task.response as? HTTPURLResponse) {
      request?.didComplete(task, with: pnError)
    } else if let error = error {
      request?.didComplete(task, with: PNError.unknownError(error))
    } else {
      request?.didComplete(task)
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
}

protocol SessionStateBridge: AnyObject {
  var sessionID: UUID { get }
  var sessionStream: SessionStream? { get }
  func request(for task: URLSessionTask) -> Request?
  func didComplete(_ task: URLSessionTask)
  func cancelRequests(for invalidationError: PNError)
}

extension Session: SessionStateBridge {
  func request(for task: URLSessionTask) -> Request? {
    return taskToRequest[task]
  }

  func didComplete(_ task: URLSessionTask) {
    // Cleanup the task/requst map
    taskToRequest[task] = nil
  }

  func cancelRequests(for invalidationError: PNError) {
    taskToRequest.values.forEach {
      $0.retryOrFinish(with: invalidationError)
    }
  }
}
