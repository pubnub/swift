//
//  SessionStreamAwait.swift
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
import XCTest

final class SessionExpector {
  public var expectations = [XCTestExpectation]()
  public var sessionListener: SessionListener

  public init(session listener: SessionListener) {
    sessionListener = listener
  }

  // URLRequest Building
  func expectDidCreateURLRequest(fullfil count: Int = 1, closure: @escaping (RequestReplaceable, URLRequest) -> Void) {
    let expectation = XCTestExpectation(description: "didCreateURLRequest")
    expectation.expectedFulfillmentCount = count
    sessionListener.didCreateURLRequest = { request, urlRequest in
      closure(request, urlRequest)
      expectation.fulfill()
    }
    expectations.append(expectation)
  }

  func expectDidFailToCreateURLRequestWithError(
    fullfil count: Int = 1,
    closure: @escaping (RequestReplaceable, Error) -> Void
  ) {
    let expectation = XCTestExpectation(description: "didFailToCreateURLRequestWithError")
    expectation.expectedFulfillmentCount = count
    sessionListener.didFailToCreateURLRequestWithError = { request, error in
      closure(request, error)
      expectation.fulfill()
    }
    expectations.append(expectation)
  }

  // URLSessionTask States
  func expectDidCreateTask(fullfil count: Int = 1, closure: @escaping (RequestReplaceable, URLSessionTask) -> Void) {
    let expectation = XCTestExpectation(description: "didCreateTask")
    expectation.expectedFulfillmentCount = count
    sessionListener.didCreateTask = { request, task in
      closure(request, task)
      expectation.fulfill()
    }
    expectations.append(expectation)
  }

  func expectDidResumeTask(fullfil count: Int = 1, closure: @escaping (RequestReplaceable, URLSessionTask) -> Void) {
    let expectation = XCTestExpectation(description: "didResumeTask")
    expectation.expectedFulfillmentCount = count
    sessionListener.didResumeTask = { request, task in
      closure(request, task)
      expectation.fulfill()
    }
    expectations.append(expectation)
  }

  func expectDidCancelTask(fullfil count: Int = 1, closure: @escaping (RequestReplaceable, URLSessionTask) -> Void) {
    let expectation = XCTestExpectation(description: "didCancelTask")
    expectation.expectedFulfillmentCount = count
    sessionListener.didCancelTask = { request, task in
      closure(request, task)
      expectation.fulfill()
    }
    expectations.append(expectation)
  }

  func expectDidCompleteTask(fullfil count: Int = 1, closure: @escaping (RequestReplaceable, URLSessionTask) -> Void) {
    let expectation = XCTestExpectation(description: "didCompleteTask")
    expectation.expectedFulfillmentCount = count
    sessionListener.didCompleteTask = { request, task in
      closure(request, task)
      expectation.fulfill()
    }
    expectations.append(expectation)
  }

  func expectDidCompleteTaskWithError(
    fullfil count: Int = 1,
    closure: @escaping (RequestReplaceable, URLSessionTask, Error) -> Void
  ) {
    let expectation = XCTestExpectation(description: "didCompleteTaskWithError")
    expectation.expectedFulfillmentCount = count
    sessionListener.didCompleteTaskWithError = { request, task, error in
      closure(request, task, error)
      expectation.fulfill()
    }
    expectations.append(expectation)
  }

  // Request States
  func expectDidResumeRequest(fullfil count: Int = 1, closure: @escaping (RequestReplaceable) -> Void) {
    let expectation = XCTestExpectation(description: "didResumeRequest")
    expectation.expectedFulfillmentCount = count
    sessionListener.didResumeRequest = { request in
      closure(request)
      expectation.fulfill()
    }
    expectations.append(expectation)
  }

  func expectDidFinishRequest(fullfil count: Int = 1, closure: @escaping (RequestReplaceable) -> Void) {
    let expectation = XCTestExpectation(description: "didFinishRequest")
    expectation.expectedFulfillmentCount = count
    sessionListener.didFinishRequest = { request in
      closure(request)
      expectation.fulfill()
    }
    expectations.append(expectation)
  }

  func expectDidCancelRequest(fullfil count: Int = 1, closure: @escaping (RequestReplaceable) -> Void) {
    let expectation = XCTestExpectation(description: "didCancelRequest")
    expectation.expectedFulfillmentCount = count
    sessionListener.didCancelRequest = { request in
      closure(request)
      expectation.fulfill()
    }
    expectations.append(expectation)
  }

  func expectDidRetryRequest(fullfil count: Int = 1, closure: @escaping (RequestReplaceable) -> Void) {
    let expectation = XCTestExpectation(description: "didRetryRequest")
    expectation.expectedFulfillmentCount = count
    sessionListener.didRetryRequest = { request in
      closure(request)
      expectation.fulfill()
    }
    expectations.append(expectation)
  }

  // Request Mutator
  func expectDidMutateRequest(
    fullfil count: Int = 1,
    closure: @escaping (RequestReplaceable, URLRequest, URLRequest) -> Void
  ) {
    let expectation = XCTestExpectation(description: "didMutateRequest")
    expectation.expectedFulfillmentCount = count
    sessionListener.didMutateRequest = { request, initialURLRequest, mutatedURLRequest in
      closure(request, initialURLRequest, mutatedURLRequest)
      expectation.fulfill()
    }
    expectations.append(expectation)
  }

  func expectDidFailToMutateRequest(
    fullfil count: Int = 1,
    closure: @escaping (RequestReplaceable, URLRequest, Error) -> Void
  ) {
    let expectation = XCTestExpectation(description: "didFailToMutateRequest")
    expectation.expectedFulfillmentCount = count
    sessionListener.didFailToMutateRequest = { request, initialURLRequest, error in
      closure(request, initialURLRequest, error)
      expectation.fulfill()
    }
    expectations.append(expectation)
  }

  // URLSessionDelegate
  func expectDidReceiveURLSessionData(
    fullfil count: Int = 1,
    closure: @escaping (URLSession, URLSessionDataTask, Data) -> Void
  ) {
    let expectation = XCTestExpectation(description: "didReceiveURLSessionData")
    expectation.expectedFulfillmentCount = count
    sessionListener.sessionTaskDidReceiveData = { session, dataTask, data in
      closure(session, dataTask, data)
      expectation.fulfill()
    }
    expectations.append(expectation)
  }

  func expectDidCompleteURLSessionTask(
    fullfil count: Int = 1,
    closure: @escaping (URLSession, URLSessionTask, Error?) -> Void
  ) {
    let expectation = XCTestExpectation(description: "didCompleteURLSessionTask")
    expectation.expectedFulfillmentCount = count
    sessionListener.sessionTaskDidComplete = { session, dataTask, error in
      closure(session, dataTask, error)
      expectation.fulfill()
    }
    expectations.append(expectation)
  }

  func expectDidInvalidateURLSession(fullfil count: Int = 1, closure: @escaping (URLSession, Error?) -> Void) {
    let expectation = XCTestExpectation(description: "didCompleteURLSessionTask")
    expectation.expectedFulfillmentCount = count
    sessionListener.sessionDidBecomeInvalidated = { session, error in
      closure(session, error)
      expectation.fulfill()
    }
    expectations.append(expectation)
  }
}
