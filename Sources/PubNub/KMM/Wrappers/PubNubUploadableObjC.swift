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
