//
//  Convertibles+PubNub.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
//  http://www.pubnub.com/
//  http://www.pubnub.com/terms
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

public protocol URLConvertible {
  var asURL: Result<URL, Error> { get }
}

enum URLConvertibleError: Error {
  case urlComponents
  case urlRequest
}

extension URL: URLConvertible {
  public var asURL: Result<URL, Error> {
    return .success(self)
  }
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

public protocol URLRequestConvertible: URLConvertible {
  var asURLRequest: Result<URLRequest, Error> { get }
}

enum URLRequestConvertibleError: Error {
  case request
}

extension URLRequest: URLRequestConvertible {
  public var asURLRequest: Result<URLRequest, Error> {
    return .success(self)
  }

  public var asURL: Result<URL, Error> {
    guard let url = self.url else {
      return .failure(URLConvertibleError.urlRequest)
    }
    return .success(url)
  }
}

extension Request: URLRequestConvertible {
  public var asURLRequest: Result<URLRequest, Error> {
    guard let urlRequest = self.urlRequest else {
      return .failure(URLRequestConvertibleError.request)
    }
    return .success(urlRequest)
  }

  public var asURL: Result<URL, Error> {
    return asURLRequest.flatMap { $0.asURL }
  }
}

// MARK: - HTTPURLResponseConvertible

public protocol HTTPURLResponseConvertible {
  var asHTTPURLResponse: HTTPURLResponse { get }
}

extension HTTPURLResponse: HTTPURLResponseConvertible {
  public var asHTTPURLResponse: HTTPURLResponse { return self }
}
