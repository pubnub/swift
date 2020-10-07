//
//  PubNubFile.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2020 PubNub Inc.
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

import Foundation

// MARK: - PubNubLocalFile

/// A file stored on a PubNub channel that can be mapped to a local resource
public protocol PubNubLocalFile: PubNubFile {
  /// The local URL of the file
  var localFileURL: URL { get set }
  /// If the local filenames changes this can be used to track the remote filename
  var remoteFilename: String? { get }

  /// Allows for converting  between different `PubNubLocalFile` types
  init(from other: PubNubLocalFile) throws
  /// Map a local resource `URL` to  a `PubNubFile`
  init(from other: PubNubFile, withFile url: URL) throws
}

public extension PubNubLocalFile {
  var size: Int64 {
    return Int64(localFileURL.sizeOf)
  }

  var contentType: String {
    return localFileURL.mimeType
  }

  var filename: String {
    return remoteFilename ?? localFileURL.lastPathComponent
  }

  init(from other: PubNubFile, withFile url: URL) throws {
    try self.init(from: other)

    localFileURL = url
  }
}

/// A base concrete representation of a `PubNubLocalFile`
public struct PubNubLocalFileBase: PubNubLocalFile {
  public var localFileURL: URL
  public var channel: String

  public var fileId: String
  public var remoteFilename: String?

  public var createdDate: Date?

  var concreteCustom: AnyJSON?
  public var custom: JSONCodable? {
    get { return concreteCustom }
    set { concreteCustom = newValue?.codableValue }
  }

  public init(
    localFileURL: URL,
    channel: String,
    fileId: String,
    remoteFilename: String? = nil,
    custom: JSONCodable? = nil,
    createdDate: Date? = nil
  ) {
    self.localFileURL = localFileURL
    self.channel = channel
    self.fileId = fileId
    self.remoteFilename = remoteFilename
    self.custom = custom
    self.createdDate = createdDate
  }

  public init(from other: PubNubLocalFile) {
    self.init(
      localFileURL: other.localFileURL,
      channel: other.channel,
      fileId: other.fileId,
      custom: other.custom,
      createdDate: other.createdDate
    )
  }

  public init(from other: PubNubFile) throws {
    guard let otherLocalFile = other as? PubNubLocalFile else {
      throw PubNubError(
        .protocolTranscodingFailure,
        additional: [String(describing: PubNubLocalFileBase.self), String(describing: other)]
      )
    }

    self.init(from: otherLocalFile)
  }

  init(fromFile url: URL, pubnub response: GenerateUploadURLResponse, on channel: String) {
    self.init(
      localFileURL: url,
      channel: channel,
      fileId: response.fileId,
      remoteFilename: response.filename
    )
  }

  public init(from other: PubNubFile, withFile url: URL) {
    self.init(
      localFileURL: url,
      channel: other.channel,
      fileId: other.fileId,
      remoteFilename: other.filename,
      custom: other.custom,
      createdDate: other.createdDate
    )
  }
}

// MARK: - PubNubFile

/// A file stored on a PubNub channel
public protocol PubNubFile: JSONCodable {
  /// The channel the file is associated with
  var channel: String { get }
  /// PubNub-generated ID for a file
  var fileId: String { get }
  /// User defined name for a file
  var filename: String { get }
  /// Size, in bytes, of the stored file
  var size: Int64 { get }
  /// The MIME Type of the file
  var contentType: String { get }

  /// ISO 8601 date and time the file was uploaded
  var createdDate: Date? { get set }

  /// Custom payload that can be used to store additional file details
  var custom: JSONCodable? { get set }

  /// Allows for converting  between different `PubNubFile` types
  init(from other: PubNubFile) throws
}

/// A base concrete representation of a `PubNubFile`
public struct PubNubFileBase: PubNubFile {
  public var channel: String
  public var fileId: String
  public var filename: String
  public var size: Int64
  public var contentType: String
  public var createdDate: Date?

  var concreteCustom: AnyJSON?
  public var custom: JSONCodable? {
    get { return concreteCustom }
    set { concreteCustom = newValue?.codableValue }
  }

  public init(
    channel: String,
    fileId: String,
    filename: String,
    size: Int64,
    contentType: String,
    createdDate: Date?,
    custom: JSONCodable?
  ) {
    self.channel = channel
    self.fileId = fileId
    self.filename = filename
    self.size = size
    self.contentType = contentType
    self.createdDate = createdDate
    self.custom = custom
  }

  public init(from other: PubNubFile) {
    self.init(
      channel: other.channel,
      fileId: other.fileId,
      filename: other.filename,
      size: other.size,
      contentType: other.contentType,
      createdDate: other.createdDate,
      custom: other.custom
    )
  }

  init(from fileInfo: FileInfo, on channel: String) {
    self.init(
      channel: channel,
      fileId: fileInfo.fileId,
      filename: fileInfo.filename,
      size: fileInfo.size,
      contentType: fileInfo.contentType,
      createdDate: fileInfo.created,
      custom: fileInfo.custom
    )
  }
}

// MARK: - PubNubFile Event

/// A subscription event containing File information
public protocol PubNubFileEvent {
  /// The channel group or wildcard subscription match
  var channelGroup: String? { get }
  /// The UUID responsible for uploading the file
  var publisher: String { get }
  /// The timetoken of the file upload
  var timetoken: Timetoken { get }
  /// The file object that was published
  var file: PubNubFile { get }
  /// The additional message published along with the file
  var additionalMessage: JSONCodable? { get }
  /// Meta information for the event
  var metadata: JSONCodable? { get }

  /// Allows for converting  between different `PubNubFileEvent` types
  init(from other: PubNubFileEvent) throws
}

// MARK: Concrete PubNubFileEvent

/// A concrete representation of a `PubNubFileEvent`
public struct PubNubFileEventBase: PubNubFileEvent {
  public var channelGroup: String?
  public var publisher: String
  public var timetoken: Timetoken

  var concreteFile: PubNubFileBase
  public var file: PubNubFile {
    return concreteFile
  }

  var concreteAdditionalMessage: AnyJSON?
  public var additionalMessage: JSONCodable? {
    get {
      return concreteAdditionalMessage
    }
    set {
      concreteAdditionalMessage = newValue?.codableValue
    }
  }

  var concreteMeta: AnyJSON?
  public var metadata: JSONCodable? {
    get {
      return concreteMeta
    }
    set {
      concreteMeta = newValue?.codableValue
    }
  }

  public init(
    file: PubNubFile,
    channelGroup: String?,
    publisher: String,
    timetoken: Timetoken,
    additionalMessage: JSONCodable?,
    metadata: JSONCodable?
  ) {
    concreteFile = PubNubFileBase(from: file)
    self.channelGroup = channelGroup
    self.publisher = publisher
    self.timetoken = timetoken
    self.additionalMessage = additionalMessage
    self.metadata = metadata
  }

  public init(from other: PubNubFileEvent) throws {
    self.init(
      file: other.file,
      channelGroup: other.channelGroup,
      publisher: other.publisher,
      timetoken: other.timetoken,
      additionalMessage: other.additionalMessage,
      metadata: other.metadata
    )
  }

  init(from subscription: SubscribeMessagePayload) throws {
    let filePayload = try subscription.payload.decode(FilePublishPayload.self)

    guard let publisher = subscription.publisher else {
      throw PubNubError(.missingRequiredParameter, additional: ["publisher"])
    }

    let file = PubNubFileBase(
      channel: subscription.channel,
      fileId: filePayload.fileId,
      filename: filePayload.filename,
      size: filePayload.size,
      contentType: filePayload.contentType,
      createdDate: filePayload.createdDate,
      custom: filePayload.custom
    )

    self.init(
      file: file,
      channelGroup: subscription.subscription,
      publisher: publisher,
      timetoken: subscription.publishTimetoken.timetoken,
      additionalMessage: filePayload.additionalDetails,
      metadata: subscription.metadata
    )
  }
}
