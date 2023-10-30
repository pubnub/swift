//
//  XMLCodingTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

class XMLCodingTests: XCTestCase {
  func testDecode_XMLError() {
    // swiftlint:disable:next line_length
    let exampleBase64 = "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPEVycm9yPjxDb2RlPlByZWNvbmRpdGlvbkZhaWxlZDwvQ29kZT48TWVzc2FnZT5BdCBsZWFzdCBvbmUgb2YgdGhlIHByZS1jb25kaXRpb25zIHlvdSBzcGVjaWZpZWQgZGlkIG5vdCBob2xkPC9NZXNzYWdlPjxDb25kaXRpb24+QnVja2V0IFBPU1QgbXVzdCBiZSBvZiB0aGUgZW5jbG9zdXJlLXR5cGUgbXVsdGlwYXJ0L2Zvcm0tZGF0YTwvQ29uZGl0aW9uPjxSZXF1ZXN0SWQ+Rjg2NUU0REIxQzlBNEE3QTwvUmVxdWVzdElkPjxIb3N0SWQ+SWFTQS9EVjc2MUF1U1RBQUJyNkJDM0ZWT0ZnMHRNRVFReGE2T2k1U2pFdnRCM2lRSU9Vall2YmhQQkp5alFTMENkVTRjV2Fwdk9NPTwvSG9zdElkPjwvRXJyb3I+"

    let fileError = FileUploadError(
      code: "PreconditionFailed",
      message: "At least one of the pre-conditions you specified did not hold",
      requestId: "F865E4DB1C9A4A7A",
      hostId: "IaSA/DV761AuSTAABr6BC3FVOFg0tMEQQxa6Oi5SjEvtB3iQIOUjYvbhPBJyjQS0CdU4cWapvOM=",
      condition: "Bucket POST must be of the enclosure-type multipart/form-data"
    )

    guard let data = Data(base64Encoded: exampleBase64) else {
      return XCTFail("Could not create the example data")
    }

    do {
      let decoded = try XMLDecoder().decode(FileUploadError.self, from: data)

      XCTAssertEqual(fileError, decoded)
    } catch {
      XCTFail("Failed to decode \(error)")
    }
  }
}
