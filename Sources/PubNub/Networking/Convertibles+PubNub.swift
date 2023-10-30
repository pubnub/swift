//
//  Convertibles+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
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
    guard let url = url else {
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
