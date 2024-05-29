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
  @objc public let message: Any?
  @objc public let subscription: String?
  @objc public let file: PubNubFileObjC

  static func from(event: PubNubFileChangeEvent, with pubnub: PubNub?) -> PubNubFileEventResultObjC {
    switch event {
    case .uploaded(let fileEvent):
      return PubNubFileEventResultObjC(
        channel: fileEvent.file.channel,
        timetoken: NSNumber(value: fileEvent.timetoken),
        publisher: fileEvent.publisher,
        message: fileEvent.additionalMessage,
        subscription: fileEvent.channelGroup,
        file: PubNubFileObjC(
          id: fileEvent.file.fileId,
          name: fileEvent.file.filename,
          url: (try? pubnub?.generateFileDownloadURL(
            channel: fileEvent.file.channel,
            fileId: fileEvent.file.fileId,
            filename: fileEvent.file.filename
          ))?.absoluteString ?? ""
        )
      )
    }
  }

  private init(
    channel: String,
    timetoken: NSNumber?,
    publisher: String?,
    message: Any?,
    subscription: String?,
    file: PubNubFileObjC
  ) {
    self.channel = channel
    self.timetoken = timetoken
    self.publisher = publisher
    self.message = message
    self.subscription = subscription
    self.file = file
  }
}

@objc
public class PubNubFileObjC: NSObject {
  @objc public let id: String
  @objc public let name: String
  @objc public let url: String

  init(id: String, name: String, url: String) {
    self.id = id
    self.name = name
    self.url = url
  }
}
