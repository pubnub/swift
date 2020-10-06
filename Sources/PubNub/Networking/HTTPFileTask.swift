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

extension URLSessionTask { //: URLSessionTaskReplaceable {
  public var httpResponse: HTTPURLResponse? {
    return response as? HTTPURLResponse
  }
}

extension URLSessionDownloadTask { //: URLSessionDownloadTaskReplaceable {
  public var resumeData: Data? {
    return error?.resumeData
  }
}

// extension URLSessionUploadTask: URLSessionUploadTaskReplaceable {}

// MARK: - Base Class

public class HTTPFileTask: Hashable {
  public private(set) var urlSessionTask: URLSessionTask

  public let progress: Progress
  var progressBlock: ProgressBlock?

  public let sessionIdentifier: String?

  public init(task: URLSessionTask, session identifier: String?) {
    urlSessionTask = task
    sessionIdentifier = identifier

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
    if #available(iOS 11.0, macOS 10.13, macCatalyst 13.0, tvOS 11.0, watchOS 4.0, *) {
    } else {
      progress.completedUnitCount = totalBytesWritten
    }

    progressBlock?((bytesWritten, totalBytesWritten, totalBytesExpectedToWrite))
  }

  func responseCodeError() -> Error? {
    // If the response was an error, then return the status code as error
    if let reason = urlSessionTask.httpResponse?.statusCodeReason {
      return PubNubError(reason)
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

extension HTTPFileTask { //: URLSessionTaskReplaceable {
  public var error: Error? {
    return urlSessionTask.error
  }

  public var state: URLSessionTask.State {
    return urlSessionTask.state
  }

  public var priority: Float {
    get {
      return urlSessionTask.priority
    }
    set {
      urlSessionTask.priority = newValue
    }
  }

  public var taskIdentifier: Int {
    return urlSessionTask.taskIdentifier
  }

  public var httpResponse: HTTPURLResponse? {
    return urlSessionTask.httpResponse
  }

  public var countOfBytesExpectedToReceive: Int64 {
    return urlSessionTask.countOfBytesExpectedToReceive
  }

  public func suspend() {
    urlSessionTask.suspend()
  }

  public func resume() {
    urlSessionTask.resume()
  }

  public func cancel() {
    urlSessionTask.cancel()
  }
}

// MARK: - Uploading

public class HTTPFileUploadTask: HTTPFileTask { // , URLSessionUploadTaskReplaceable {
  var responseData: Data?
  public var completionBlock: ((Result<Void, Error>) -> Void)?

  func didReceieve(data: Data) {
    print("didReceieve data \(data.base64EncodedString())")
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
        let xmlError = try XMLDecoder().decode(FileUploadError.self, from: data)
        completionBlock?(.failure(xmlError.asPubNubError))
      } catch {
        completionBlock?(.failure(error))
      }
      return
    }

    // If the response was an error, then return the status code as error
    if let error = responseCodeError() {
      completionBlock?(.failure(error))
      return
    }

    completionBlock?(.success(()))
  }
}

// MARK: - Downloading

public class HTTPFileDownloadTask: HTTPFileTask {
  public var completionBlock: ((Result<URL, Error>) -> Void)?

  public private(set) var destinationURL: URL
  var downloadURL: URL?

  init(task: URLSessionDownloadTask, session identifier: String?, downloadTo url: URL) {
    destinationURL = url

    super.init(task: task, session: identifier)
  }

  // MARK: URLSessionDownloadTaskDelegate methods

  override func didError(_ error: Error) {
    super.didError(error)

    completionBlock?(.failure(error))
  }

  override func didComplete() {
    super.didComplete()

    // If the response was an error, then return the status code as error
    if let error = responseCodeError() {
      completionBlock?(.failure(error))
      return
    }

    guard let url = downloadURL else {
      completionBlock?(.failure(PubNubError(.fileMissingAtPath)))
      return
    }

    completionBlock?(.success(url))
  }

  func didDownload(to tempURL: URL) {
    downloadURL = tempURL
  }
}

// extension HTTPFileDownloadTask: URLSessionDownloadTaskReplaceable {
//  public var resumeData: Data? {
//    return (urlSessionTask as? URLSessionDownloadTaskReplaceable)?.resumeData
//  }
//
//  public func cancel(byProducingResumeData resumeData: @escaping (Data?) -> Void) {
//    (urlSessionTask as? URLSessionDownloadTaskReplaceable)?.cancel(byProducingResumeData: resumeData)
//  }
// }

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

    do {
      let fileManager = FileManager.default

      let fileURL = fileManager.makeUniqueFilename(fileDownloadTask.destinationURL)
      print("Move to \(fileURL.absoluteString)")

      try fileManager.moveItem(at: location, to: fileURL)

      didDownload?(session, downloadTask, fileURL)
      (tasksByIdentifier[downloadTask.taskIdentifier] as? HTTPFileDownloadTask)?.didDownload(to: fileURL)
    } catch {
      PubNub.log.warn(
        "Could not move file to \(fileDownloadTask.destinationURL.absoluteString) due to \(error.localizedDescription)"
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
}
