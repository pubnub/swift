//
//  PubNubUploadableObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//
// IMPORTANT NOTE FOR DEVELOPERS USING THIS SDK
//
// All public symbols in this file are intended to allow interoperation with Kotlin Multiplatform for other PubNub frameworks.
// While these symbols are public, they are intended strictly for internal usage.
//
// External developers should refrain from directly using these symbols in their code, as their implementation details
// may change in future versions of the framework, potentially leading to breaking changes.

import Foundation

@objc
public class KMPUploadable: NSObject {

}

@objc
public class KMPDataUploadContent: KMPUploadable {
  @objc public let data: Data
  @objc public let contentType: String?

  @objc
  public init(data: Data, contentType: String?) {
    self.data = data
    self.contentType = contentType
  }
}

@objc
public class KMPFileUploadContent: KMPUploadable {
  @objc public let fileURL: URL

  @objc
  public init(fileURL: URL) {
    self.fileURL = fileURL
  }
}

@objc
public class KMPInputStreamUploadContent: KMPUploadable {
  @objc public let stream: InputStream
  @objc public let contentType: String?
  @objc public let contentLength: Int

  @objc
  public init(stream: InputStream, contentType: String?, contentLength: Int) {
    self.stream = stream
    self.contentType = contentType
    self.contentLength = contentLength
  }
}
