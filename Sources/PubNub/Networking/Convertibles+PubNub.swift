//
//  Convertibles+PubNub.swift
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

/// An object that is capable of converting into an URL
public protocol URLConvertible {
  /// The converted `URL` or the error that occurred during converting
  var asURL: Result<URL, Error> { get }
}

/// An `Error` that occured when generating an `URL` from an `URLConvertible`
public enum URLConvertibleError: Error {
  case urlComponents
}

extension URLComponents: URLConvertible {
  public var asURL: Result<URL, Error> {
    guard let url = self.url else {
      return .failure(URLConvertibleError.urlComponents)
    }
    return .success(url)
  }
}

// MARK: - URLRequestConvertible

/// An object that is capable of converting into an URLRequest
public protocol URLRequestConvertible: URLConvertible {
  /// The converted `URLRequest` or the error that occurred during converting
  var asURLRequest: Result<URLRequest, Error> { get }
}
