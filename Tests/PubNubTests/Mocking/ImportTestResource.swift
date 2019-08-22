//
//  ImportJSON.swift
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

@testable import PubNub
import XCTest

enum ImportTestResourceError: Error, LocalizedError {
  case jsonResourceNotFound
  case resourceDataConversionFailure
  case malformedMockResource

  var errorDescription: String? {
    switch self {
    case .jsonResourceNotFound:
      return "JSON Resource was not found at URL"
    case .resourceDataConversionFailure:
      return "Contents of URL could not be transformed into Data"
    case .malformedMockResource:
      return "MockResource was malformed, and not useable"
    }
  }
}

struct EndpointResource: Codable {
  var code: Int
  var body: AnyJSON
}

struct URLErrorResource: Codable {
  var rawURLErrorCode: Int
}

extension URLErrorResource {
  var urlError: URLError {
    return URLError(URLError.Code(rawValue: rawURLErrorCode))
  }
}

struct ImportTestResource {
  static let testsBundle = Bundle(for: PubNubConfigurationTests.self)

  static func importResource(_ filename: String) throws -> Data {
    guard let url = testsBundle.url(forResource: filename, withExtension: "json") else {
      throw ImportTestResourceError.jsonResourceNotFound
    }
    guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else {
      throw ImportTestResourceError.resourceDataConversionFailure
    }

    return data
  }

  static func testResource<T>(_ filename: String) -> T? where T: Decodable {
    do {
      let data = try importResource(filename)
      return try? JSONDecoder().decode(T.self, from: data)
    } catch {
      XCTFail("Failed to import requested resource file \(filename).json due to \(error.localizedDescription)")
      return nil
    }
  }
}
