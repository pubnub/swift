//
//  KMPPubNub+Files.swift
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

extension KMPPubNub {
  var defaultFileDownloadPath: URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("pubnub-chat-sdk")
  }

  func convertUploadContent(from content: KMPUploadable) -> PubNub.FileUploadContent? {
    switch content {
    case let content as KMPDataUploadContent:
      return .data(content.data, contentType: content.contentType)
    case let content as KMPFileUploadContent:
      return .file(url: content.fileURL)
    case let content as KMPInputStreamUploadContent:
      return .stream(content.stream, contentType: content.contentType, contentLength: content.contentLength)
    default:
      return nil
    }
  }
}

@objc
public extension KMPPubNub {
  func listFiles(
    channel: String,
    limit: NSNumber?,
    next: KMPHashedPage?,
    onSuccess: @escaping (([KMPFile], String?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.listFiles(
      channel: channel,
      limit: limit?.uintValue ?? 100,
      next: next?.end
    ) { [weak pubnub] in
      switch $0 {
      case .success(let res):
        onSuccess(res.files.map { KMPFile(from: $0, url: pubnub?.generateFileDownloadURL(for: $0)) }, next?.end)
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func getFileUrl(
    channel: String,
    fileName: String,
    fileId: String,
    onSuccess: @escaping ((String) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    do {
      onSuccess(
        try pubnub.generateFileDownloadURL(
          channel: channel,
          fileId: fileId,
          filename: fileName
        ).absoluteString
      )
    } catch {
      onFailure(KMPError(underlying: error))
    }
  }

  func deleteFile(
    channel: String,
    fileName: String,
    fileId: String,
    onSuccess: @escaping (() -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.remove(fileId: fileId, filename: fileName, channel: channel) {
      switch $0 {
      case .success:
        onSuccess()
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  // swiftlint:disable todo
  // TODO: Missing contentType and fileSize from KMP which are required in Swift SDK

  func publishFileMessage(
    channel: String,
    fileName: String,
    fileId: String,
    message: Any?,
    meta: Any?,
    ttl: NSNumber?,
    shouldStore: NSNumber?,
    onSuccess: @escaping ((Timetoken) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    let messageCodable: AnyJSON? = if let message {
      AnyJSON(message)
    } else {
      nil
    }
    let metaCodable: AnyJSON? = if let meta {
      AnyJSON(meta)
    } else {
      nil
    }
    pubnub.publish(
      file: PubNubFileBase(
        channel: channel,
        fileId: fileId,
        filename: fileName,
        size: 0,
        contentType: nil
      ),
      request: PubNub.PublishFileRequest(
        additionalMessage: messageCodable,
        store: shouldStore?.boolValue,
        ttl: ttl?.intValue,
        meta: metaCodable
      )
    ) {
      switch $0 {
      case .success(let timetoken):
        onSuccess(timetoken)
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  // swiftlint:enable todo

  func downloadFile(
    channel: String,
    fileName: String,
    fileId: String,
    onSuccess: @escaping ((KMPFile) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    let fileBase = PubNubLocalFileBase(
      channel: channel,
      fileId: fileId,
      fileURL: defaultFileDownloadPath.appendingPathComponent(fileName)
    )
    pubnub.download(file: fileBase, toFileURL: fileBase.fileURL) {
      switch $0 {
      case .success(let res):
        onSuccess(KMPFile(from: res.file, url: res.file.fileURL))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func sendFile(
    channel: String,
    fileName: String,
    content: KMPUploadable,
    message: Any?,
    meta: Any?,
    ttl: NSNumber?,
    shouldStore: NSNumber?,
    onSuccess: @escaping ((KMPFile, Timetoken) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    guard let fileContent = convertUploadContent(from: content) else {
      onFailure(KMPError(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Cannot create expected PubNub.FileUploadContent"]
        )
      ))
      return
    }

    let additionalMessage: AnyJSON? = if let message { AnyJSON(message) } else { nil }
    let meta: AnyJSON? = if let meta { AnyJSON(meta) } else { nil }

    pubnub.send(
      fileContent,
      channel: channel,
      remoteFilename: fileName,
      publishRequest: PubNub.PublishFileRequest(
        additionalMessage: additionalMessage,
        store: shouldStore?.boolValue,
        ttl: ttl?.intValue,
        meta: meta
      )
    ) { [weak pubnub] in
      switch $0 {
      case .success(let res):
        onSuccess(
          KMPFile(from: res.file, url: pubnub?.generateFileDownloadURL(for: res.file)),
          res.publishedAt
        )
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }
}
