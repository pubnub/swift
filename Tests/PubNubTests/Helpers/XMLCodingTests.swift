//
//  XMLCodingTests.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2020 PubNub Inc.
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
