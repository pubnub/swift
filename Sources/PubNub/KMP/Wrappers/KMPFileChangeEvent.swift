//
//  PubNubFileChangeEventObjC.swift
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
public class KMPFileChangeEvent: NSObject {
  @objc public let channel: String
  @objc public let timetoken: NSNumber?
  @objc public let publisher: String?
  @objc public let message: KMPAnyJSON?
  @objc public let metadata: KMPAnyJSON?
  @objc public let subscription: String?
  @objc public let file: KMPFile

  static func from(event: PubNubFileChangeEvent, with pubnub: PubNub?) -> KMPFileChangeEvent {
    switch event {
    case .uploaded(let fileEvent):
      return KMPFileChangeEvent(
        channel: fileEvent.file.channel,
        timetoken: NSNumber(value: fileEvent.timetoken),
        publisher: fileEvent.publisher,
        message: fileEvent.additionalMessage?.codableValue,
        metadata: fileEvent.metadata?.codableValue,
        subscription: fileEvent.channelGroup,
        file: KMPFile(
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
    metadata: AnyJSON?,
    subscription: String?,
    file: KMPFile
  ) {
    self.channel = channel
    self.timetoken = timetoken
    self.publisher = publisher
    self.message = if let message = message { KMPAnyJSON(message) } else { nil }
    self.metadata = if let metadata = metadata { KMPAnyJSON(metadata) } else { nil }
    self.subscription = subscription
    self.file = file
  }
}

@objc
public class KMPFile: NSObject {
  @objc public let id: String
  @objc public let name: String
  @objc public let url: URL?
  @objc public let size: Int64
  @objc public let contentType: String?
  @objc public let createdDate: Date?

  @objc
  public var createdDateStringValue: String? {
    if let createdDate {
      return DateFormatter.iso8601.string(from: createdDate)
    } else {
      return nil
    }
  }

  init(from: PubNubFile, url: URL?) {
    self.id = from.channel
    self.name = from.filename
    self.size = from.size
    self.contentType = from.contentType
    self.createdDate = from.createdDate
    self.url = url
  }
}
