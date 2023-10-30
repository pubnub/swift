//
//  URLRequest+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
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
    cryptoModule: CryptoModule? = nil
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
    if let cryptoModule = cryptoModule {
      switch cryptoModule.encrypt(stream: contentStream, contentLength: content.contentLength) {
      case .success(let encryptingResult):
        finalStream = encryptingResult
        contentLength = prefixData.count + ((encryptingResult as? MultipartInputStream)?.length ?? 0) + postfixData.count
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
