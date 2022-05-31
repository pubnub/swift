//
//  HTTPFileTask.swift
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

// MARK: Protocol Extensions

public extension URLSessionTask {
  var httpResponse: HTTPURLResponse? {
    return response as? HTTPURLResponse
  }
}

public extension URLSessionDownloadTask {
  var resumeData: Data? {
    return error?.resumeData
  }
}

// MARK: - Base Class

/// A file-based task performed in a URL session.
public class HTTPFileTask: Hashable {
  /// The underlying URLSessionTask that is being processed
  public private(set) var urlSessionTask: URLSessionTask

  /// A representation of the overall task progress.
  public let progress: Progress
  var progressBlock: ProgressBlock?

  var responseError: Error?

  /// The background identifier of the URLSession that is processing this task
  public let sessionIdentifier: String?

  /// Creates a new task based on an existing URLSessionTask and the URLSession that created it
  ///
  /// To ensure delegate events are not missed, this `init` should be used before calling `resume()` on the `URLSessionTask` for the first time
  public init(task: URLSessionTask, session identifier: String?) {
    urlSessionTask = task
    sessionIdentifier = identifier

    // We have to create/update the Progress manually for older platform versions
    if #available(iOS 11.0, macOS 10.13, macCatalyst 13.0, tvOS 11.0, watchOS 4.0, *) {
      self.progress = task.progress
    } else {
      progress = Progress()
      progress.kind = .file

      progress.totalUnitCount = task.countOfBytesExpectedToReceive

      // We say we're a file operation so the localized descriptions are a little nicer.
      progress.setUserInfoObject(
        Progress.FileOperationKind.downloading as AnyObject,
        forKey: ProgressUserInfoKey.fileOperationKindKey
      )
    }
  }

  // MARK: URLSessionTaskDelegate methods

  func didComplete() { /* no-op */ }
  func didError(_: Error) { /* no-op */ }

  // MARK: Progress

  func updateProgress(bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    // Progress is handled automatically on iOS 11+
    if #available(iOS 11.0, macOS 10.13, macCatalyst 13.0, tvOS 11.0, watchOS 4.0, *) { } else {
      progress.completedUnitCount = totalBytesWritten
    }

    progressBlock?((bytesWritten, totalBytesWritten, totalBytesExpectedToWrite))
  }

  func responseCodeError() -> Error? {
    // If the response was an error, then return the status code as error
    if let response = response, let reason = response.statusCodeReason {
      return PubNubError(
        reason: reason,
        router: nil,
        request: urlSessionTask.currentRequest,
        response: response
      )
    }

    return nil
  }

  // MARK: Hashable

  public static func == (lhs: HTTPFileTask, rhs: HTTPFileTask) -> Bool {
    return lhs.urlSessionTask.taskIdentifier == rhs.urlSessionTask.taskIdentifier
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(urlSessionTask.taskIdentifier)
  }
}

// MARK: Convenience access from URLSessionTask

public extension HTTPFileTask {
  /// An error object that indicates why the task failed.
  ///
  /// This value is nil if the task is still active or if the transfer completed successfully.
  var error: Error? {
    return urlSessionTask.error ?? responseError
  }

  /// An identifier uniquely identifying the task within a given session.
  ///
  /// This value is unique only within the context of a single session; tasks in other sessions may have the same taskIdentifier value.
  var taskIdentifier: Int {
    return urlSessionTask.taskIdentifier
  }

  /// The server’s response to the currently active request.
  ///
  /// This object provides information about the request as provided by the server. This information always includes the original URL.
  var response: HTTPURLResponse? {
    return urlSessionTask.httpResponse
  }

  /// Temporarily suspends a task.
  ///
  /// A task, while suspended, produces no network traffic and is not subject to timeouts. A download task can continue transferring data at a later time. All other tasks must start over when resumed.
  func suspend() {
    urlSessionTask.suspend()
  }

  /// Resumes the task, if it is suspended.
  ///
  /// Newly-initialized tasks begin in a suspended state, so you need to call this method to start the task.
  func resume() {
    urlSessionTask.resume()
  }

  /// Cancels the task
  ///
  /// This method returns immediately, marking the task as being canceled.
  /// Once a task is marked as being canceled, `urlSession(_:task:didCompleteWithError:) `will be sent to the task delegate, passing an error in the domain `NSURLErrorDomain` with the code `NSURLErrorCancelled`.
  /// A task may, under some circumstances, send messages to its delegate before the cancelation is acknowledged.
  ///
  /// This method may be called on a task that is suspended.
  func cancel() {
    urlSessionTask.cancel()
  }
}

// MARK: - Uploading

// A File-based URL session task that uploads data to the network in a request body or directy from a file URL
public class HTTPFileUploadTask: HTTPFileTask {
  /// The body of the response
  public var responseData: Data?
  /// The  block that is called when the task completes
  public var completionBlock: ((Result<Void, Error>) -> Void)?

  func didReceieve(data: Data) {
    if responseData == nil {
      responseData = data
    } else {
      responseData?.append(data)
    }
  }

  // MARK: URLSessionTaskDelegate methods

  override func didError(_ error: Error) {
    super.didError(error)

    if let reason = (error as? URLError)?.pubnubReason {
      completionBlock?(.failure(PubNubError(reason, underlying: error)))
    } else {
      completionBlock?(.failure(error))
    }
  }

  override func didComplete() {
    // If there is response data then its and XMLError
    if let data = responseData, !data.isEmpty {
      do {
        // Attempt to decode the error
        let xmlError = try XMLDecoder().decode(FileUploadError.self, from: data).asPubNubError

        // Update the response Error
        responseError = xmlError
        completionBlock?(.failure(xmlError))
      } catch {
        responseError = error
        completionBlock?(.failure(error))
      }
      return
    }

    // If the response was an error, then return the status code as error
    if let error = responseCodeError() {
      responseError = error
      completionBlock?(.failure(error))
      return
    }

    completionBlock?(.success(()))
  }
}

// MARK: - Downloading

/// A File-based URL session task that stores downloaded data to a local file.
public class HTTPFileDownloadTask: HTTPFileTask {
  /// The  block that is called when the task completes
  public var completionBlock: ((Result<URL, Error>) -> Void)?
  /// The crypto object that will attempt to decrypt the file
  public var crypto: Crypto?

  /// The location where the temporary downloaded file should be copied
  public private(set) var destinationURL: URL
  /// If an automatic decryption took place this is the URL of the downloaded file
  public private(set) var encryptedURL: URL?
  /// The temporary location the file was downloaded to
  var downloadURL: URL?

  /// Cancels a download and calls a callback with resume data for later use.
  public func cancel(byProducingResumeData: @escaping (Data?) -> Void) {
    (urlSessionTask as? URLSessionDownloadTask)?.cancel(byProducingResumeData: byProducingResumeData)
  }

  init(task: URLSessionDownloadTask, session identifier: String?, downloadTo url: URL, crypto: Crypto?) {
    destinationURL = url
    self.crypto = crypto

    super.init(task: task, session: identifier)
  }

  func decrypt(_ encryptedURL: URL, to outpuURL: URL, using crypto: Crypto) throws {
    // If we were provided a crypto object we should try and decrypt the file
    guard let secureStream = CryptoInputStream(.decrypt, url: encryptedURL, with: crypto) else {
      throw PubNubError(.streamCouldNotBeInitialized, additional: [encryptedURL.absoluteString])
    }
    try secureStream.writeEncodedData(to: outpuURL)
  }

  open func temporaryURL() -> URL {
    return FileManager.default
      .tempDirectory
      .appendingPathComponent("\(sessionIdentifier ?? UUID().uuidString)-\(taskIdentifier)")
  }

  // MARK: URLSessionDownloadTaskDelegate methods

  override func didError(_ error: Error) {
    super.didError(error)

    responseError = error

    // If a file exists at the download location then we need to read the contents to determine the error
    if let url = downloadURL, FileManager.default.fileExists(atPath: url.path), let data = try? Data(contentsOf: url) {
      if let generalErrorPayload = try? Constant.jsonDecoder.decode(GenericServicePayloadResponse.self, from: data) {
        let error = PubNubError(
          reason: generalErrorPayload.pubnubReason,
          router: nil, request: urlSessionTask.currentRequest, response: response,
          additional: generalErrorPayload.details
        )

        completionBlock?(.failure(error))
      } else if let xmlError = try? XMLDecoder().decode(FileUploadError.self, from: data).asPubNubError {
        completionBlock?(.failure(xmlError))
      }

      return
    }

    completionBlock?(.failure(error))
  }

  override func didComplete() {
    super.didComplete()

    // If the response was an error, then return the status code as error
    if let error = responseCodeError() {
      return didError(error)
    }

    // If the URL doesn't exist, then we create a missing file error
    guard let url = downloadURL, FileManager.default.fileExists(atPath: url.path) else {
      return didError(PubNubError(.fileMissingAtPath))
    }

    // Post process the file
    do {
      let fileManager = FileManager.default

      // Update destination to be a unique file
      destinationURL = fileManager.makeUniqueFilename(destinationURL)

      if let crypto = crypto {
        // Set the encrypted in case something goes wrong
        encryptedURL = url

        // If we were provided a crypto object we should try and decrypt the file
        guard let secureStream = CryptoInputStream(.decrypt, url: url, with: crypto) else {
          throw PubNubError(.streamCouldNotBeInitialized, additional: [url.absoluteString])
        }
        try secureStream.writeEncodedData(to: destinationURL)
      } else {
        try fileManager.moveItem(at: url, to: destinationURL)
      }

      completionBlock?(.success(destinationURL))
    } catch {
      PubNub.log.warn(
        "Could not move file to \(destinationURL.absoluteString) due to \(error.localizedDescription)"
      )
      // Set the error to alert that even though a file was retrieved the destination is wrong
      responseError = error
      // Return the temporary file
      completionBlock?(.success(url))
    }
  }

  func didDownload(to tempURL: URL) {
    downloadURL = tempURL
  }
}

// MARK: - FileSessionManager

open class FileSessionManager: NSObject, URLSessionDataDelegate, URLSessionDownloadDelegate {
  var tasksByIdentifier = [Int: HTTPFileTask]()

  public struct ProgressUnit {
    public var currentBytes: Int64
    public var totalTransmitted: Int64
    public var totalExpectedToTransmit: Int64

    public init(
      currentBytes: Int64,
      totalTransmitted: Int64,
      totalExpectedToTransmit: Int64
    ) {
      self.currentBytes = currentBytes
      self.totalTransmitted = totalTransmitted
      self.totalExpectedToTransmit = totalExpectedToTransmit
    }
  }

  // Public Responders
  public var didComplete: ((_ session: URLSessionReplaceable, _ task: URLSessionTask) -> Void)?
  public var didError: ((_ session: URLSessionReplaceable, _ task: URLSessionTask, _ error: Error) -> Void)?
  public var didDownload: (
    (_ session: URLSessionReplaceable, _ task: URLSessionDownloadTask, _ downloadTo: URL) -> Void
  )?
  public var didTrasmitData: (
    (_ session: URLSessionReplaceable, _ task: URLSessionTask, _ update: ProgressUnit) -> Void
  )?

  // MARK: URLSessionDelegate

  open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if let error = error {
      didError?(session, task, error)
      tasksByIdentifier[task.taskIdentifier]?.didError(error)
    } else {
      didComplete?(session, task)
      tasksByIdentifier[task.taskIdentifier]?.didComplete()
    }
    // Cleanup Task After Completion
    tasksByIdentifier.removeValue(forKey: task.taskIdentifier)
  }

  // MARK: URLSessionDataDelegate

  open func urlSession(
    _ session: URLSession, task: URLSessionTask,
    didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64
  ) {
    // Progress Updates
    didTrasmitData?(
      session,
      task,
      ProgressUnit(
        currentBytes: bytesSent, totalTransmitted: totalBytesSent, totalExpectedToTransmit: totalBytesExpectedToSend
      )
    )
    tasksByIdentifier[task.taskIdentifier]?.updateProgress(
      bytesWritten: bytesSent,
      totalBytesWritten: totalBytesSent,
      totalBytesExpectedToWrite: totalBytesExpectedToSend
    )
  }

  open func urlSession(_: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    (tasksByIdentifier[dataTask.taskIdentifier] as? HTTPFileUploadTask)?.didReceieve(data: data)
  }

  // MARK: URLSessionDownloadDelegate

  open func urlSession(
    _ session: URLSession, downloadTask: URLSessionDownloadTask,
    didFinishDownloadingTo location: URL
  ) {
    guard let fileDownloadTask = tasksByIdentifier[downloadTask.taskIdentifier] as? HTTPFileDownloadTask else {
      didError?(session, downloadTask, PubNubError(.badRequest))
      return
    }

    let temporaryURL = fileDownloadTask.temporaryURL()

    do {
      // Move file to a temporary location or it's lost at the end of this scope
      try FileManager.default.moveItem(at: location, to: temporaryURL)

      didDownload?(session, downloadTask, temporaryURL)
      (tasksByIdentifier[downloadTask.taskIdentifier] as? HTTPFileDownloadTask)?.didDownload(to: temporaryURL)
    } catch {
      PubNub.log.warn(
        "Could not move file to \(temporaryURL.absoluteString) due to \(error.localizedDescription)"
      )
      didError?(session, downloadTask, error)
      tasksByIdentifier[downloadTask.taskIdentifier]?.didError(error)
    }
  }

  open func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didWriteData bytesWritten: Int64,
    totalBytesWritten: Int64,
    totalBytesExpectedToWrite: Int64
  ) {
    didTrasmitData?(
      session, downloadTask,
      ProgressUnit(
        currentBytes: bytesWritten, totalTransmitted: totalBytesWritten,
        totalExpectedToTransmit: totalBytesExpectedToWrite
      )
    )
    tasksByIdentifier[downloadTask.taskIdentifier]?.updateProgress(
      bytesWritten: bytesWritten, totalBytesWritten: totalBytesWritten,
      totalBytesExpectedToWrite: totalBytesExpectedToWrite
    )
  }

  // swiftlint:disable:next file_length
}
