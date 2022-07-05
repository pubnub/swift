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
  var fileURL: URL { get set }

  /// Allows for converting  between different `PubNubLocalFile` types
  init(from other: PubNubLocalFile) throws
  /// Map a local resource `URL` to  a `PubNubFile`
  init(from other: PubNubFile, withFile url: URL) throws
}

public extension PubNubLocalFile {
  /// PubNub  defined name for a file
  var remoteFilename: String {
    return filename
  }

  /// Size, in bytes, of the local file
  var localSize: Int64 {
    return Int64(fileURL.sizeOf)
  }

  /// The MIME Type of the local file
  var localContentType: String? {
    return fileURL.contentType
  }

  /// Name for the local file
  var localFilename: String {
    return fileURL.lastPathComponent
  }

  init(from other: PubNubFile, withFile url: URL) throws {
    try self.init(from: other)

    fileURL = url
  }
}

public extension PubNubLocalFile {
  /// Converts this protocol into a custom type
  /// - Parameter into: The explicit type for the returned value
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  func transcode<T: PubNubLocalFile>(into _: T.Type) throws -> T {
    return try transcode()
  }

  /// Converts this protocol into a custom type
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  func transcode<T: PubNubLocalFile>() throws -> T {
    // Check if we're already that object, and return
    if let custom = self as? T {
      return custom
    }

    return try T(from: self)
  }
}

/// A base concrete representation of a `PubNubLocalFile`
public struct PubNubLocalFileBase: PubNubLocalFile, Hashable {
  public var channel: String
  public var fileId: String
  public var filename: String
  public var size: Int64
  public var contentType: String?
  public var createdDate: Date?

  public var fileURL: URL

  public init(
    channel: String,
    fileId: String,
    filename: String,
    size: Int64,
    contentType: String?,
    fileURL: URL,
    createdDate: Date? = nil
  ) {
    self.channel = channel
    self.fileId = fileId
    self.filename = filename
    self.size = size
    self.contentType = contentType
    self.fileURL = fileURL
    self.createdDate = createdDate
  }

  public init(from other: PubNubLocalFile) {
    self.init(
      channel: other.channel,
      fileId: other.fileId,
      filename: other.filename,
      size: other.size,
      contentType: other.contentType,
      fileURL: other.fileURL,
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
      channel: channel,
      fileId: response.fileId,
      filename: response.filename,
      size: Int64(url.sizeOf),
      contentType: url.contentType,
      fileURL: url
    )
  }

  public init(
    channel: String,
    fileId: String,
    fileURL: URL,
    createdDate: Date? = nil
  ) {
    self.init(
      channel: channel,
      fileId: fileId,
      filename: fileURL.lastPathComponent,
      size: Int64(fileURL.sizeOf),
      contentType: fileURL.contentType,
      fileURL: fileURL,
      createdDate: createdDate
    )
  }

  public init(from other: PubNubFile, withFile url: URL) {
    self.init(
      channel: other.channel,
      fileId: other.fileId,
      filename: other.filename,
      size: other.size,
      contentType: other.contentType,
      fileURL: url,
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
  var contentType: String? { get }

  /// ISO 8601 date and time the file was uploaded
  var createdDate: Date? { get set }

  /// Allows for converting  between different `PubNubFile` types
  init(from other: PubNubFile) throws
}

public extension PubNubFile {
  /// Converts this protocol into a custom type
  /// - Parameter into: The explicit type for the returned value
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  func transcode<T: PubNubFile>(into _: T.Type) throws -> T {
    return try transcode()
  }

  /// Converts this protocol into a custom type
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  func transcode<T: PubNubFile>() throws -> T {
    // Check if we're already that object, and return
    if let custom = self as? T {
      return custom
    }

    return try T(from: self)
  }

  static func createBaseType(
    channel: String,
    fileId: String,
    filename: String,
    size: Int64,
    contentType: String?,
    fileURL: URL?,
    createdDate: Date? = nil
  ) -> PubNubFile {
    if let fileURL = fileURL {
      return PubNubLocalFileBase(
        channel: channel,
        fileId: fileId,
        filename: filename,
        size: size,
        contentType: contentType,
        fileURL: fileURL,
        createdDate: createdDate
      )
    } else {
      return PubNubFileBase(
        channel: channel,
        fileId: fileId,
        filename: filename,
        size: size,
        contentType: contentType,
        createdDate: createdDate
      )
    }
  }
}

/// A base concrete representation of a `PubNubFile`
public struct PubNubFileBase: PubNubFile, Hashable {
  public var channel: String
  public var fileId: String
  public var filename: String
  public var size: Int64
  public var contentType: String?
  public var createdDate: Date?

  public init(
    channel: String,
    fileId: String,
    filename: String,
    size: Int64,
    contentType: String?,
    createdDate: Date? = nil
  ) {
    self.channel = channel
    self.fileId = fileId
    self.filename = filename
    self.size = size
    self.contentType = contentType
    self.createdDate = createdDate
  }

  public init(from other: PubNubFile) {
    self.init(
      channel: other.channel,
      fileId: other.fileId,
      filename: other.filename,
      size: other.size,
      contentType: other.contentType,
      createdDate: other.createdDate
    )
  }

  init(from fileInfo: FileInfo, on channel: String) {
    self.init(
      channel: channel,
      fileId: fileInfo.fileId,
      filename: fileInfo.filename,
      size: fileInfo.size,
      contentType: fileInfo.contentType,
      createdDate: fileInfo.created
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

public extension PubNubFileEvent {
  /// Converts this protocol into a custom type
  /// - Parameter into: The explicit type for the returned value
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  func transcode<T: PubNubFileEvent>(into _: T.Type) throws -> T {
    return try transcode()
  }

  /// Converts this protocol into a custom type
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  func transcode<T: PubNubFileEvent>() throws -> T {
    // Check if we're already that object, and return
    if let custom = self as? T {
      return custom
    }

    return try T(from: self)
  }
}

// MARK: Concrete PubNubFileEvent

/// A concrete representation of a `PubNubFileEvent`
public struct PubNubFileEventBase: PubNubFileEvent, Hashable {
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
      createdDate: filePayload.createdDate
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

  // swiftlint:disable:next file_length
}
