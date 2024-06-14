//
//  PubNubFileEventResultObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@objc
public class PubNubFileEventResultObjC: NSObject {
  @objc public let channel: String
  @objc public let timetoken: NSNumber?
  @objc public let publisher: String?
  @objc public let message: AnyJSONObjC?
  @objc public let subscription: String?
  @objc public let file: PubNubFileObjC

  static func from(event: PubNubFileChangeEvent, with pubnub: PubNub?) -> PubNubFileEventResultObjC {
    switch event {
    case .uploaded(let fileEvent):
      return PubNubFileEventResultObjC(
        channel: fileEvent.file.channel,
        timetoken: NSNumber(value: fileEvent.timetoken),
        publisher: fileEvent.publisher,
        message: fileEvent.additionalMessage?.codableValue,
        subscription: fileEvent.channelGroup,
        file: PubNubFileObjC(
          from: fileEvent.file,
          url: pubnub?.generateFileDownloadURL(for: fileEvent.file)
        )
      )
    }
  }

  private init(
    channel: String,
    timetoken: NSNumber?,
    publisher: String?,
    message: AnyJSON?,
    subscription: String?,
    file: PubNubFileObjC
  ) {
    self.channel = channel
    self.timetoken = timetoken
    self.publisher = publisher
    self.message = if let message = message { AnyJSONObjC(message) } else { nil }
    self.subscription = subscription
    self.file = file
  }
}

@objc
public class PubNubFileObjC: NSObject {
  @objc public let id: String
  @objc public let name: String
  @objc public let url: URL?
  @objc public let size: Int64
  @objc public let contentType: String?
  @objc public let createdDate: Date?
  
  init(from: PubNubFile, url: URL?) {
    self.id = from.channel
    self.name = from.filename
    self.size = from.size
    self.contentType = from.contentType
    self.createdDate = from.createdDate
    self.url = url
  }
}
