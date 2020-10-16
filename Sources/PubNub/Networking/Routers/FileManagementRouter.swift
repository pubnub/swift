//
//  FileManagementRouter.swift
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
//

import Foundation

import CoreServices

// MARK: - Router

struct FileManagementRouter: HTTPRouter {
  // Nested Endpoint
  enum Endpoint: CustomStringConvertible {
    /// Upload file / data to specified `Channel`
    case generateURL(channel: String, body: GenerateURLRequestBody)
    /// Retrieve list of files uploaded to `Channel`
    case list(channel: String, limit: UInt, next: String?)
    /// Get a file's direct download URL. This method doesn't make any API calls, and won't decrypt an encrypted file.
    case fetchURL(channel: String, fileId: String, filename: String)
    /// Delete file from specified `Channel`
    case delete(channel: String, fileId: String, filename: String)

    var description: String {
      switch self {
      case .generateURL:
        return "Generate a presigned request for file upload"
      case .list:
        return "Get a list of files"
      case .fetchURL:
        return "Redirects to a download URL for the given file"
      case .delete:
        return "Delete a file"
      }
    }
  }

  /// Request body  for `generateURL` endpoint
  struct GenerateURLRequestBody: Codable {
    /// User-supplied filename
    let name: String
  }

  // Init
  init(_ endpoint: Endpoint, configuration: RouterConfiguration) {
    self.endpoint = endpoint
    self.configuration = configuration
  }

  var endpoint: Endpoint
  var configuration: RouterConfiguration

  // Protocol Properties
  var service: PubNubService {
    return .fileManagement
  }

  var category: String {
    return endpoint.description
  }

  var method: HTTPMethod {
    switch endpoint {
    case .generateURL:
      return .post
    case .list:
      return .get
    case .fetchURL:
      return .get
    case .delete:
      return .delete
    }
  }

  var path: Result<String, Error> {
    let path: String

    switch endpoint {
    case let .generateURL(channel, _):
      path = "/v1/files/\(subscribeKey)/channels/\(channel.urlEncodeSlash)/generate-upload-url"
    case let .list(channel, _, _):
      path = "/v1/files/\(subscribeKey)/channels/\(channel.urlEncodeSlash)/files"
    case let .fetchURL(channel, fileId, filename):
      // swiftlint:disable:next line_length
      path = "/v1/files/\(subscribeKey)/channels/\(channel.urlEncodeSlash)/files/\(fileId.urlEncodeSlash)/\(filename.urlEncodeSlash)"
    case let .delete(channel, fileId, filename):
      // swiftlint:disable:next line_length
      path = "/v1/files/\(subscribeKey)/channels/\(channel.urlEncodeSlash)/files/\(fileId.urlEncodeSlash)/\(filename.urlEncodeSlash)"
    }
    return .success(path)
  }

  var queryItems: Result<[URLQueryItem], Error> {
    let query = defaultQueryItems

    switch endpoint {
    default:
      break
    }

    return .success(query)
  }

  var body: Result<Data?, Error> {
    switch endpoint {
    case let .generateURL(_, body):
      return .success(try? Constant.jsonEncoder.encode(body))
    default:
      return .success(nil)
    }
  }

  var pamVersion: PAMVersionRequirement {
    return .version3
  }

  // Validated
  var validationErrorDetail: String? {
    switch endpoint {
    case let .generateURL(channel, body):
      return isInvalidForReason(
        (channel.isEmpty, ErrorDescription.emptyChannelString),
        (body.name.isEmpty, ErrorDescription.emptyFilenameString)
      )
    case let .list(channel, _, _):
      return isInvalidForReason(
        (channel.isEmpty, ErrorDescription.emptyChannelString)
      )
    case let .fetchURL(channel, fileId, filename):
      return isInvalidForReason(
        (channel.isEmpty, ErrorDescription.emptyChannelString),
        (fileId.isEmpty, ErrorDescription.emptyFileIdString),
        (filename.isEmpty, ErrorDescription.emptyFilenameString)
      )
    case let .delete(channel, fileId, filename):
      return isInvalidForReason(
        (channel.isEmpty, ErrorDescription.emptyChannelString),
        (fileId.isEmpty, ErrorDescription.emptyFileIdString),
        (filename.isEmpty, ErrorDescription.emptyFilenameString)
      )
    }
  }
}

// MARK: - Response Decoder

struct FileGenerateResponseDecoder: ResponseDecoder {
  typealias Payload = GenerateUploadURLResponse
}

struct FileDownloadResponseDecoder<PayloadType>: ResponseDecoder where PayloadType: Codable {
  typealias Payload = PayloadType
}

struct FileListResponseDecoder: ResponseDecoder {
  typealias Payload = ListFilesSuccessResponse
}

struct FileGeneralSuccessResponseDecoder: ResponseDecoder {
  typealias Payload = GeneralSuccessResponse
}

// MARK: - Response Body

struct GeneralSuccessResponse: Codable {
  /// Status code
  let status: Int
}

struct ListFilesSuccessResponse: Codable {
  /// Status code
  let status: Int
  /// List of File data points
  let data: [FileInfo]
  /// URL-safe token to get the next batch of files
  let next: String?
  /// URL-safe token to get the prev batch of files
  let prev: String?
  /// Number of files returned
  let count: Int
}

/// An object that contains file info
struct FileInfo: PubNubFile {
  /// PubNub-generated ID for a file
  let fileId: String
  /// User defined name for a file
  var filename: String
  /// Size, in bytes, of the stored file
  var size: Int64
  /// ISO 8601 date and time the file was uploaded
  var created: Date

  // MARK: PubNubFile

  var channel: String = ""
  var contentType: String?
  var createdDate: Date? {
    get { return created }
    set {
      if let newValue = newValue {
        created = newValue
      }
    }
  }

  enum CodingKeys: String, CodingKey {
    case filename = "name"
    case fileId = "id"
    case size
    case created
  }

  init(
    fileId: String,
    filename: String,
    size: Int64,
    created: Date
  ) {
    self.fileId = fileId
    self.filename = filename
    self.size = size
    self.created = created
  }

  init(from other: PubNubFile) throws {
    guard let created = other.createdDate else {
      throw PubNubError(
        .protocolTranscodingFailure,
        additional: [String(describing: FileInfo.self), String(describing: other)]
      )
    }

    self.init(fileId: other.fileId, filename: other.filename, size: other.size, created: created)
  }
}

/// An array of form fields to be used in the presigned POST request. You must supply these fields in the order in which you receive them from the server.
struct FormField: Codable {
  /// Form field name
  let key: String
  /// Form field value
  let value: String

  func multipartyDescription(boundary: String) -> String {
    return "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n"
  }
}

struct GenerateUploadURLResponse: Codable {
  /// Status code
  let status: Int

  let filename: String
  let fileId: String

  let uploadRequestURL: URL
  let uploadMethod: HTTPMethod
  let uploadFormFields: [FormField]

  init(
    status: Int,
    filename: String,
    fileId: String,
    uploadRequestURL: URL,
    uploadMethod: HTTPMethod,
    uploadFormFields: [FormField]
  ) {
    self.status = status
    self.filename = filename
    self.fileId = fileId
    self.uploadRequestURL = uploadRequestURL
    self.uploadMethod = uploadMethod
    self.uploadFormFields = uploadFormFields
  }

  enum CodingKeys: String, CodingKey {
    case status
    case data
    case fileRequest = "file_upload_request"
  }

  enum FileCodingKeys: String, CodingKey {
    case fileId = "id"
    case filename = "name"
  }

  enum FileRequestCodingKeys: String, CodingKey {
    case url
    case method
    case fields = "form_fields"
    case expiration = "expiration_date"
  }

  init(from decoder: Decoder) throws {
    let rootContainer = try decoder.container(keyedBy: CodingKeys.self)
    status = try rootContainer.decode(Int.self, forKey: .status)

    let fileContainer = try rootContainer.nestedContainer(keyedBy: FileCodingKeys.self, forKey: .data)
    fileId = try fileContainer.decode(String.self, forKey: .fileId)
    filename = try fileContainer.decode(String.self, forKey: .filename)

    let uploadRequestContainer = try rootContainer.nestedContainer(
      keyedBy: FileRequestCodingKeys.self, forKey: .fileRequest
    )
    uploadRequestURL = try uploadRequestContainer.decode(URL.self, forKey: .url)
    uploadMethod = try uploadRequestContainer.decode(HTTPMethod.self, forKey: .method)
    uploadFormFields = try uploadRequestContainer.decode([FormField].self, forKey: .fields)
  }

  func encode(to encoder: Encoder) throws {
    var rootContainer = encoder.container(keyedBy: CodingKeys.self)
    try rootContainer.encode(status, forKey: .status)

    var fileContainer = rootContainer.nestedContainer(keyedBy: FileCodingKeys.self, forKey: .data)
    try fileContainer.encode(fileId, forKey: .fileId)
    try fileContainer.encode(filename, forKey: .filename)

    var uploadRequestContainer = rootContainer.nestedContainer(
      keyedBy: FileRequestCodingKeys.self, forKey: .fileRequest
    )
    try uploadRequestContainer.encode(uploadRequestURL, forKey: .url)
    try uploadRequestContainer.encode(uploadMethod, forKey: .method)
    try uploadRequestContainer.encode(uploadFormFields, forKey: .fields)
  }
}

struct FileUploadError: Codable, Hashable {
  var code: String
  var message: String
  var requestId: String
  var hostId: String

  var condition: String?
  var maxSizeAllowed: String?
  var proposedSize: String?

  init(
    code: String,
    message: String,
    requestId: String,
    hostId: String,
    condition: String? = nil,
    maxSizeAllowed: String? = nil,
    proposedSize: String? = nil
  ) {
    self.code = code
    self.message = message
    self.requestId = requestId
    self.hostId = hostId
    self.condition = condition
    self.maxSizeAllowed = maxSizeAllowed
    self.proposedSize = proposedSize
  }

  enum CodingKeys: String, CodingKey {
    case code = "Code"
    case message = "Message"
    case requestId = "RequestId"
    case hostId = "HostId"

    case condition = "Condition"
    case maxSizeAllowed = "MaxSizeAllowed"
    case proposedSize = "ProposedSize"
  }

  var asPubNubError: PubNubError {
    switch code {
    case "EntityTooLarge":
      return PubNubError(.fileTooLarge, additional: [message])
    case "AccessDenied", "TokenRefreshRequired":
      return PubNubError(.fileAccessDenied, additional: [message])
    case "MalformedPOSTRequest":
      return PubNubError(.fileContentLength, additional: [message])
    default:
      return PubNubError(.unknown, additional: [code, message])
    }
  }
}

// MARK: - Publish Request Body

/// The message structure used by all SDKs to denote a published message
struct FilePublishPayload: PubNubFile, Hashable {
  /// The additional payload published along with the file
  var additionalDetails: JSONCodable? {
    get {
      return additionalDetailsConcrete
    }
    set {
      additionalDetailsConcrete = newValue?.codableValue
    }
  }

  var additionalDetailsConcrete: AnyJSON?

  /// The ID of file on the server
  var fileId: String
  /// The name of the file on the server
  var filename: String
  /// The size in bytes of the file
  var size: Int64
  /// The MIME Type of the file
  var contentType: String?

  var channel: String
  var createdDate: Date?

  init(
    channel: String,
    fileId: String,
    filename: String,
    size: Int64 = 0,
    contentType: String? = nil,
    createdDate: Date? = nil,
    additionalDetails: JSONCodable? = nil
  ) {
    self.channel = channel
    self.fileId = fileId
    self.filename = filename
    self.size = size
    self.contentType = contentType
    self.createdDate = createdDate
    self.additionalDetails = additionalDetails
  }

  init(from other: PubNubFile) {
    self.init(
      channel: other.channel,
      fileId: other.fileId,
      filename: other.filename,
      size: other.size,
      contentType: other.contentType,
      createdDate: other.createdDate
    )
  }

  init(from other: PubNubFile, additional message: JSONCodable?) {
    self.init(
      channel: other.channel,
      fileId: other.fileId,
      filename: other.filename,
      size: other.size,
      contentType: other.contentType,
      createdDate: other.createdDate,
      additionalDetails: message
    )
  }

  // MARK: Codable

  enum CodingKeys: String, CodingKey {
    case message
    case file
    case channel
  }

  enum FileCodingKeys: String, CodingKey {
    case id
    case name
    case size
    case mimeType = "mime-type"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    additionalDetailsConcrete = try container.decodeIfPresent(AnyJSON.self, forKey: .message)
    channel = try container.decodeIfPresent(String.self, forKey: .channel) ?? ""

    let fileContainer = try container.nestedContainer(keyedBy: FileCodingKeys.self, forKey: .file)
    fileId = try fileContainer.decode(String.self, forKey: .id)
    filename = try fileContainer.decode(String.self, forKey: .name)
    size = try fileContainer.decodeIfPresent(Int64.self, forKey: .size) ?? 0
    contentType = try fileContainer.decodeIfPresent(String.self, forKey: .mimeType)
  }

  func encode(to encoder: Encoder) throws {
    var rootContainer = encoder.container(keyedBy: CodingKeys.self)
    try rootContainer.encodeIfPresent(additionalDetailsConcrete, forKey: .message)

    var fileContainer = rootContainer.nestedContainer(keyedBy: FileCodingKeys.self, forKey: .file)
    try fileContainer.encode(fileId, forKey: .id)
    try fileContainer.encode(filename, forKey: .name)
    try fileContainer.encode(size, forKey: .size)
    try fileContainer.encode(contentType, forKey: .mimeType)
  }
}

extension FilePublishPayload: Validated {
  var validationError: Error? {
    if fileId.isEmpty {
      return PubNubError(.missingRequiredParameter, additional: [ErrorDescription.emptyFileIdString])
    }

    if filename.isEmpty {
      return PubNubError(.missingRequiredParameter, additional: [ErrorDescription.emptyFilenameString])
    }

    if channel.isEmpty {
      return PubNubError(.missingRequiredParameter, additional: [ErrorDescription.emptyChannelString])
    }

    return nil
  }

  var validationErrorDetail: String? {
    return validationError?.pubNubError?.details.first
  }

  // swiftlint:disable:next file_length
}
