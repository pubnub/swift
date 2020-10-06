//
//  URLRequest+PubNub.swift
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

public extension URLRequest {
  /// Convience for assigning `HTTPMethod` values to `httpMethod`
  var method: HTTPMethod? {
    get {
      // `httpMethod` defaults to GET; unclear why it's optional
      guard let method = httpMethod else {
        return .get
      }
      return HTTPMethod(rawValue: method)
    }
    set {
      httpMethod = newValue?.rawValue
    }
  }

  internal init(from response: GenerateUploadURLResponse, uploading fileURL: URL) throws {
    self.init(url: response.uploadRequestURL)
    method = response.uploadMethod

    // File Prefix
    var prefixData = Data()
    prefixData.append(
      response.uploadFormFields.map { $0.multipartyDescription(boundary: response.uploadRequestId) }.joined()
    )
    // swiftlint:disable:next line_length
    prefixData.append("--\(response.uploadRequestId)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"\(response.filename)\"\r\n")
    prefixData.append("Content-Type: \(fileURL.mimeType)\r\n\r\n")

    // Get InputStream from File
    guard let fileStream = InputStream(url: fileURL) else {
      throw PubNubError(.streamCouldNotBeInitialized, additional: [fileURL.absoluteString])
    }

    // File Postfix
    var postfixData = Data()
    postfixData.append("\r\n--\(response.uploadRequestId)--")

    let inputStream = MultipartInputStream(
      inputStreams: [InputStream(data: prefixData), fileStream, InputStream(data: postfixData)]
    )

    httpBodyStream = inputStream

    // Headers
    setValue("multipart/form-data; boundary=\(response.uploadRequestId)", forHTTPHeaderField: "Content-Type")
    setValue("\(prefixData.count + fileURL.sizeOf + postfixData.count)", forHTTPHeaderField: "Content-Length")
  }
}
