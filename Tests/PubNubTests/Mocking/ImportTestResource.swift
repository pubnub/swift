//
//  ImportTestResource.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
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

enum ImportTestResource {
  static let testsBundle = Bundle(for: PubNubConfigurationTests.self)

  static func importResource(_ filename: String, withExtension ext: String = "json") throws -> Data {
    let url = try ImportTestResource.resourceURL(filename, withExtension: ext)

    guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else {
      throw ImportTestResourceError.resourceDataConversionFailure
    }

    return data
  }

  static func resourceURL(_ filename: String, withExtension ext: String = "json") throws -> URL {
    guard let url = testsBundle.url(forResource: filename, withExtension: ext) else {
      throw ImportTestResourceError.jsonResourceNotFound
    }

    return url
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
