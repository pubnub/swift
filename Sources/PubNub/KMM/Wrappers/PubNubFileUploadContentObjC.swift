//
//  PubNubFileUploadContentObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@objc
public class PubNubFileUploadContentObjC: NSObject {
  
}

@objc
public class PubNubDataUploadContentObjC: PubNubFileUploadContentObjC {
  @objc public let data: Data
  @objc public let contentType: String?
  
  @objc
  init(data: Data, contentType: String?) {
    self.data = data
    self.contentType = contentType
  }
}

@objc
public class PubNubFileContentObjC: PubNubFileUploadContentObjC {
  @objc public let fileURL: URL
  
  @objc
  init(fileURL: URL) {
    self.fileURL = fileURL
  }
}

@objc
public class PubNubInputStreamUploadContentObjC: PubNubFileUploadContentObjC {
  @objc public let stream: InputStream
  @objc public let contentType: String?
  @objc public let contentLength: Int
  
  @objc
  init(stream: InputStream, contentType: String?, contentLength: Int) {
    self.stream = stream
    self.contentType = contentType
    self.contentLength = contentLength
  }
}
