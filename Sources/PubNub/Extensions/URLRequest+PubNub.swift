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

  /// Creates  a multipart-form request based on a generated url response and a file URL
  internal init(
    from response: GenerateUploadURLResponse,
    uploading content: PubNub.FileUploadContent,
    cryptorModule: CryptorModule? = nil
  ) throws {
    self.init(url: response.uploadRequestURL)
    method = response.uploadMethod

    // File Prefix
    var prefixData = Data()
    prefixData.append(
      response.uploadFormFields.map { $0.multipartyDescription(boundary: response.fileId) }.joined()
    )
    // swiftlint:disable:next line_length
    prefixData.append("--\(response.fileId)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"\(response.filename)\"\r\n")
    prefixData.append("Content-Type: \(content.contentType)\r\n\r\n")

    // File Postfix
    var postfixData = Data()
    postfixData.append("\r\n--\(response.fileId)--")

    // Get Content InputStream
    guard let contentStream = content.inputStream else {
      throw PubNubError(.streamCouldNotBeInitialized, additional: [content.debugDescription])
    }
    
    let finalStream: InputStream
    let contentLength: Int
    
    // If we were given a Crypto module we should convert the stream to a secure stream
    if let cryptorModule = cryptorModule {
      switch cryptorModule.encrypt(stream: contentStream, contentLength: content.contentLength) {
      case .success(let encryptingResult):
        finalStream = encryptingResult
        contentLength = prefixData.count + encryptingResult.length + postfixData.count
      case .failure(let encryptionError):
        throw encryptionError
      }      
    } else {
      finalStream = contentStream
      contentLength = prefixData.count + content.contentLength + postfixData.count
    }

    setValue("\(contentLength)", forHTTPHeaderField: "Content-Length")
    setValue("multipart/form-data; boundary=\(response.fileId)", forHTTPHeaderField: "Content-Type")
    
    httpBodyStream = MultipartInputStream(
      inputStreams: [InputStream(data: prefixData), finalStream, InputStream(data: postfixData)]
    )
  }
}
