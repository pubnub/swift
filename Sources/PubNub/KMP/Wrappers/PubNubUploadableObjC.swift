//
//  PubNubUploadableObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// All public symbols in this file that are annotated with @objc are intended to allow interoperation
/// with Kotlin Multiplatform for other PubNub frameworks.
///
/// While these symbols are public, they are intended strictly for internal usage.
  
/// External developers should refrain from directly using these symbols in their code, as their implementation details
/// may change in future versions of the framework, potentially leading to breaking changes.

@objc
public class PubNubUploadableObjC: NSObject {

}

@objc
public class PubNubDataContentObjC: PubNubUploadableObjC {
  @objc public let data: Data
  @objc public let contentType: String?

  @objc
  public init(data: Data, contentType: String?) {
    self.data = data
    self.contentType = contentType
  }
}

@objc
public class PubNubFileContentObjC: PubNubUploadableObjC {
  @objc public let fileURL: URL

  @objc
  public init(fileURL: URL) {
    self.fileURL = fileURL
  }
}

@objc
public class PubNubInputStreamContentObjC: PubNubUploadableObjC {
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
