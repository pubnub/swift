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
  @objc public var channel: String
  @objc public var timetoken: NSNumber?
  @objc public var publisher: String?
  @objc public var message: Any?
  @objc public var subscription: String?
  @objc public var file: PubNubFileObjC

  static func from(event: PubNubFileChangeEvent, with pubnub: PubNub) -> PubNubFileEventResultObjC {
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
          url: (try? pubnub.generateFileDownloadURL(
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
  @objc public var id: String
  @objc public var name: String
  @objc public var url: String

  init(id: String, name: String, url: String) {
    self.id = id
    self.name = name
    self.url = url
  }
}
