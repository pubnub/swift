//
//  File+PubNub.swift
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

// MARK: - File

public extension PubNub {
  /// Retrieve list of files uploaded to `Channel`
  /// - Parameters:
  ///   - channel: The name of the channel
  ///   - limit: Number of files to return. Minimum value is 1, and maximum is 100.
  ///   - next: Previously-returned cursor bookmark for fetching the next page.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing the list of Files for the channel, and the cursor for the `next` page if the list count exceeded the requested limit
  ///     - **Failure**: An `Error` describing the failure
  func listFiles(
    channel: String, limit: UInt = 100, next: String? = nil,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(files: [PubNubFile], next: String?), Error>) -> Void)?
  ) {
    route(
      FileManagementRouter(.list(channel: channel, limit: limit, next: next), configuration: configuration),
      responseDecoder: FileListResponseDecoder(),
      custom: requestConfig
    ) { result in
      switch result {
      case let .success(response):
        completion?(.success((
          files: response.payload.data.map { PubNubFileBase(from: $0, on: channel) },
          next: response.payload.next
        )))
      case let .failure(error):
        completion?(.failure(error))
      }
    }
  }

  /// Remove file from specified `Channel`
  /// - Parameters:
  ///   - fileId: Unique identifier of the file to be removed.
  ///   - filename: Name of the file to be removed.
  ///   - channel: The name of the channel
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing the `channel` and `fileId` of the removed file
  ///     - **Failure**: An `Error` describing the failure
  func remove(
    fileId: String, filename: String, channel: String,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(channel: String, fileId: String), Error>) -> Void)?
  ) {
    route(
      FileManagementRouter(.delete(channel: channel, fileId: fileId, filename: filename), configuration: configuration),
      responseDecoder: FileGeneralSuccessResponseDecoder(),
      custom: requestConfig
    ) { result in
      switch result {
      case .success:
        completion?(.success((channel: channel, fileId: fileId)))
      case let .failure(error):
        completion?(.failure(error))
      }
    }
  }

  // MARK: Upload File

  /// Additional information that can be sent during a File publish
  struct PublishFileRequest {
    /// The optional message that will be include alongside the File information
    public var additionalMessage: JSONCodable?
    /// If true the published message is stored in history.
    public var store: Bool?
    /// Set a per message time to live in storage.
    public var ttl: Int?
    /// Additional metadata to publish alongside the file
    public var meta: JSONCodable?
    /// Custom configuration overrides for this request
    public var customRequestConfig: RequestConfiguration

    /// Default init
    /// - Parameters:
    ///   - additionalMessage: The optional message that will be include alongside the File information
    ///   - store: If true the published message is stored in history.
    ///   - ttl: Set a per message time to live in storage.
    ///   - meta: Additional metadata to publish alongside the file
    ///   - customRequestConfig: Custom configuration overrides for this request
    public init(
      additionalMessage: JSONCodable? = nil,
      store: Bool? = nil,
      ttl: Int? = nil,
      meta: JSONCodable? = nil,
      customRequestConfig: RequestConfiguration = RequestConfiguration()
    ) {
      self.additionalMessage = additionalMessage
      self.store = store
      self.ttl = ttl
      self.meta = meta
      self.customRequestConfig = customRequestConfig
    }
  }

  /// A request to PubNub for a  File Upload `URLRequest` which can be used to send a file to target `Channel`
  ///
  /// If your `URLSession` processes requests in the foreground, then this `URLRequest` can be processed without any additional modification by the `URLSession``uploadTask(withStreamedRequest:)`
  ///
  /// If the `URLSession` processes requests in the Background, then the `httpBodyStream` property will need to be output to a temporary file.  The `temporaryFile(using:writing:)` `FileManager` extension can be used to assist in generating an upload File, and then the `URLRequest` and `URL` can be proccessed by a `URLSession` using `uploadTask(with:fromFile:)`
  ///
  /// It is recommended to use `createFileURLSessionUploadTask(request:session)` to create the URLSessionUploadTask for your session.
  ///
  /// - Warning: The `URLRequest` will expire shortly after creation, so it should be processed immidately and not cached.
  /// - Parameters:
  ///   - fileURL: The URL of the file that will be eventually uploaded
  ///   - remoteFilename: A replacement filename that will be used by the server
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing the `URLRequest` to upload the `fileURL`, and the fileId/filename the uploaded file will have once uploaded
  ///     - **Failure**: An `Error` describing the failure
  func generateFileUploadURLRequest(
    _ content: FileUploadContent,
    channel: String,
    remoteFilename: String,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<FileUploadTuple, Error>) -> Void)?
  ) {
    route(
      FileManagementRouter(
        .generateURL(channel: channel, body: .init(name: remoteFilename)),
        configuration: configuration
      ),
      responseDecoder: FileGenerateResponseDecoder(),
      custom: requestConfig
    ) { [configuration] result in
      switch result {
      case let .success(response):
        do {
          let autoCrypto = requestConfig.customConfiguration?.cipherKey ?? configuration.cipherKey
          completion?(.success((
            try URLRequest(from: response.payload, uploading: content, crypto: autoCrypto),
            response.payload.fileId,
            response.payload.filename
          )))
        } catch {
          // Error Creating the Reqeust
          completion?(.failure(error))
        }
      case let .failure(error):
        // Error retrieving upoad url from PubNub
        completion?(.failure(error))
      }
    }
  }

  /// Create a `HTTPFileUploadTask` for the `URLSessionRequest` processed by the provided session.
  ///
  /// If the URLSession is configured to process requests in the background, then a temporary File will be created to
  /// After you create the task, you must start it by calling its `resume()` method. The task calls methods on the session’s delegate to provide you with the upload’s progress, response metadata, response data, and so on.
  ///
  /// - Precondition: The URLRequest must have its `httpBodyStream` populated with the correct body data; which can be obtained using `generateFileUploadURLRequest(local:channel:)`
  /// - Parameters:
  ///   - request: The `URLRequest` to the file service proxy that store PubNub files
  ///   - session: The `URLSession` that will perfrom the upload
  ///   - backgroundFileCacheIdentifier: The filename of the temproary file if the URLSession processes requests in the background
  /// - Returns: The new file upload task. The `urlSessionTask` property can be used to access the underlying `URLSessionUploadTask`
  /// - Throws: The error that occurred while creating the temprorary file to upload
  func createFileURLSessionUploadTask(
    request: URLRequest,
    session: URLSessionReplaceable,
    backgroundFileCacheIdentifier: String
  ) throws -> HTTPFileUploadTask {
    let urlSessionTask: URLSessionUploadTask
    // If the session is background we need to save body to a file
    if !session.makesBackgroundRequests {
      urlSessionTask = session.uploadTask(withStreamedRequest: request)
    } else {
      // If it's a background upload we will create a temporary file
      let uploadURL = try FileManager.default.temporaryFile(
        using: backgroundFileCacheIdentifier,
        writing: request.httpBodyStream
      )

      urlSessionTask = session.uploadTask(with: request, fromFile: uploadURL)
    }

    // Create `FileUploadTask`
    let fileTask = HTTPFileUploadTask(
      task: urlSessionTask,
      session: session.configuration.identifier
    )

    // Create task map inside Delegate if we're managing it
    (session.delegate as? FileSessionManager)?.tasksByIdentifier[fileTask.taskIdentifier] = fileTask

    return fileTask
  }

  /// Publish file message from specified `Channel`
  /// - Parameters:
  ///   - file: The `PubNubFile` representing the uploaded File
  ///   - request: The request configuration object
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `Timetoken` of the published Message
  ///     - **Failure**: An `Error` describing the failure
  func publish(
    file: PubNubFile,
    request: PublishFileRequest,
    completion: ((Result<Timetoken, Error>) -> Void)?
  ) {
    let fileMessage = FilePublishPayload(from: file, additional: request.additionalMessage)

    let router = PublishRouter(
      .file(
        message: fileMessage,
        shouldStore: request.store, ttl: request.ttl, meta: request.meta?.codableValue
      ),
      configuration: configuration
    )

    route(router,
          responseDecoder: PublishResponseDecoder(),
          custom: request.customRequestConfig) { result in
      completion?(result.map { $0.payload.timetoken })
    }
  }

  /// Content that can be uploaded as a `File` to PubNub
  enum FileUploadContent: CustomStringConvertible, CustomDebugStringConvertible {
    /// A URL to an existing file
    case file(url: URL)
    /// The raw content of a file and the content type that best describes it
    case data(_ data: Data, contentType: String?)
    /// A stream of data, the content type of that stream, and the total length of the stream in bytes
    case stream(_ stream: InputStream, contentType: String?, contentLength: Int)

    public var contentLength: Int {
      switch self {
      case let .file(url):
        return url.sizeOf
      case let .data(data, _):
        return data.count
      case let .stream(_, _, contentLength):
        return contentLength
      }
    }

    public var rawContent: Any {
      switch self {
      case let .file(url):
        return url
      case let .data(data, _):
        return data
      case let .stream(stream, _, _):
        return stream
      }
    }

    public func contentType<T>(_: T.Type) -> T? {
      return rawContent as? T
    }

    public var inputStream: InputStream? {
      switch self {
      case let .file(url):
        return InputStream(url: url)
      case let .data(data, _):
        return InputStream(data: data)
      case let .stream(stream, _, _):
        return stream
      }
    }

    public var contentType: String {
      switch self {
      case let .file(url):
        return url.contentType
      case let .data(_, contentType):
        return contentType ?? "application/octet-stream"
      case let .stream(_, contentType, _):
        return contentType ?? "application/octet-stream"
      }
    }

    public var description: String {
      switch self {
      case let .file(url):
        return url.description
      case let .data(data, _):
        return data.description
      case let .stream(stream, _, _):
        return stream.description
      }
    }

    public var debugDescription: String {
      return "\(description); Content-Length: \(contentLength); Content-Type: \(contentType)"
    }
  }

  /// Upload file / data to specified `Channel`
  ///
  /// This method is a combination of the functionality found in:
  ///  * `generateFileUploadURLRequest(local:channel:)`
  ///  * `createFileURLSessionUploadTask(request:session)`
  ///  * `publish(file:request:)`
  ///
  ///  - Note: The `fileSession` property is the `URLSession` that procsses the file upload, and is configured to be a background session by default
  ///
  /// - Parameters:
  ///   - fileURL: The local file to upload
  ///   - channel: `Channel` for the file
  ///   - remoteFilename: The name of the content when uploaded
  ///   - publishRequest: The request configuration object when the file is published to PubNub
  ///   - custom: Custom configuration overrides when generating the File Upload `URLRequest`
  ///   - uploadTask: The file upload task executing the upload; contains a reference to the actual `URLSessionUploadTask`
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing the `HTTPFileUploadTask` that completed, the `PubNubFile` or `PubNubLocalFile` that was uploaded, and the `Timetoken` when it was published
  ///     - **Failure**: An `Error` describing the failure
  func send(
    _ content: FileUploadContent,
    channel: String,
    remoteFilename: String,
    publishRequest: PublishFileRequest = PublishFileRequest(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    uploadTask: @escaping (HTTPFileUploadTask) -> Void = { _ in },
    completion: ((Result<FileUploadSendSuccess, Error>) -> Void)?
  ) {
    // Generate a File Upload URL from PubNub
    generateFileUploadURLRequest(
      content, channel: channel, remoteFilename: remoteFilename, custom: requestConfig
    ) { [weak self] generateURLResult in
      switch generateURLResult {
      case let .success((request, fileId, filename)):
        guard let strongSelf = self else {
          completion?(.failure(PubNubError(.sessionDeinitialized)))
          return
        }

        let task: HTTPFileUploadTask
        do {
          task = try strongSelf.createFileURLSessionUploadTask(
            request: request,
            session: strongSelf.fileURLSession,
            backgroundFileCacheIdentifier: fileId
          )
        } catch {
          // Error creating the URLSessionTask for the upload
          completion?(.failure(error))
          return
        }

        // Create a File Upload task
        task.completionBlock = { [weak self] uploadResult in
          switch uploadResult {
          case .success:
            let localFile = PubNubFileBase.createBaseType(
              channel: channel,
              fileId: fileId,
              filename: filename,
              size: Int64(content.contentLength),
              contentType: content.contentType,
              fileURL: content.rawContent as? URL
            )
            // Publish the File was uploaded
            self?.publish(
              file: localFile,
              request: publishRequest
            ) { publishResult in
              completion?(publishResult.map { (task: task, file: localFile, publishedAt: $0) })
            }
          case let .failure(uploadError):
            completion?(.failure(uploadError))
            // Error returned attempting to upload the file
          }
        }

        // Responsd with task
        uploadTask(task)

        // Start the upload
        task.resume()

      case let .failure(error):
        // Error retrieving the File Upload Request information from PubNub
        completion?(.failure(error))
      }
    }
  }

  // MARK: File Download

  /// Generate a file's direct download URL.
  ///
  /// - Note:The returned URL is used to download a file independent of the `PubNub` instance, and not to be used with the PubNub `download(file:downloadTo:resumeData:completion:)` function.
  ///
  /// This method doesn't make any API calls, but the URL construction might change and should not be cached
  /// - Parameters:
  ///   - channel: The `PubNubFile` representing the uploaded File
  ///   - fileId: Unique file identifier which has been assigned during file upload.
  ///   - filename: Name under which the uploaded file is stored.
  /// - Returns:The URL where the file can be downloaded
  /// - Throws: An error if the URL could be created
  func generateFileDownloadURL(channel: String, fileId: String, filename: String) throws -> URL {
    return try FileManagementRouter(
      .fetchURL(channel: channel, fileId: fileId, filename: filename),
      configuration: configuration
    ).asURL.get()
  }

  /// The type of file download task
  enum FileDownloadTaskType {
    /// A task generated by a URL
    case requestURL(URL)
    /// A task resumed with the provided `Data`
    case resumeData(Data)
  }

  /// Generate a file's direct download URL.
  ///
  /// After you create the task, you must start it by calling its `resume()` method.
  ///
  /// - Parameters:
  ///   - taskType: The `PubNubFile` representing the uploaded File
  ///   - session: The `URLSession` that will perfrom the upload
  ///   - downloadTo: The async `Result` of the method call
  /// - Returns: The new file download task. The `urlSessionTask` property can be used to access the underlying `URLSessionDownloadTask`
  func createFileURLSessionDownloadTask(
    _ taskType: FileDownloadTaskType, session: URLSessionReplaceable, downloadTo url: URL, decrypt: Crypto? = nil
  ) -> HTTPFileDownloadTask {
    let downloadTask: URLSessionDownloadTask
    switch taskType {
    case let .requestURL(url):
      downloadTask = session.downloadTask(with: url)
    case let .resumeData(resumeData):
      downloadTask = session.downloadTask(withResumeData: resumeData)
    }

    let httpTask = HTTPFileDownloadTask(
      task: downloadTask,
      session: session.configuration.identifier,
      downloadTo: url,
      crypto: decrypt ?? configuration.cipherKey
    )

    // Create task map inside Delegate
    (session.delegate as? FileSessionManager)?.tasksByIdentifier[httpTask.taskIdentifier] = httpTask

    return httpTask
  }

  /// Download file from specified `Channel`
  ///
  /// This method is a combination of the functionality found in:
  ///  * `generateFileDownloadURL(channel:fileId:filename:)`
  ///  * `createFileURLSessionDownloadTask(:session:downloadTo:)`
  ///
  ///  - Note: The `fileSession` property is the `URLSession` that procsses the file download, and is configured to be a background session by default
  ///
  /// - Parameters:
  ///   - file: The `PubNubFile` that should be downloaded
  ///   - localFileURL: The file URL where the file should be downloaded to. This is should not be the URL returned from `generateFileDownloadURL`
  ///   - resumeData: A data object that provides the data necessary to resume a download.
  ///   - downloadTask: The file download task executing the upload
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing the `HTTPFileUploadTask` that completed,, and the `PubNubLocalFile` that was downloaded. The `fileURL` of this object might be different from the `toFileURL` in the request if a file already exists at that location.
  ///     - **Failure**: An `Error` describing the failure
  func download(
    file: PubNubFile, toFileURL localFileURL: URL,
    resumeData: Data? = nil,
    downloadTask: @escaping (HTTPFileDownloadTask) -> Void = { _ in },
    completion: ((Result<(task: HTTPFileDownloadTask, file: PubNubLocalFile), Error>) -> Void)?
  ) {
    let task: HTTPFileDownloadTask
    if let resumeData = resumeData {
      task = createFileURLSessionDownloadTask(
        .resumeData(resumeData), session: fileURLSession, downloadTo: localFileURL
      )
    } else {
      // URLSession will automatically redirect, so we can download directly from the fetchURL endpoint
      do {
        task = createFileURLSessionDownloadTask(
          .requestURL(try generateFileDownloadURL(channel: file.channel, fileId: file.fileId, filename: file.filename)),
          session: fileURLSession,
          downloadTo: localFileURL
        )
      } catch {
        completion?(.failure(error))
        return
      }
    }

    task.completionBlock = { result in
      switch result {
      case let .success(downloadURL):
        completion?(.success((
          task: task,
          file: PubNubLocalFileBase(from: file, withFile: downloadURL)
        )))
      case let .failure(error):
        completion?(.failure(error))
      }
    }

    // Send the download Task
    downloadTask(task)

    // Start the download
    task.resume()
  }

  // swiftlint:disable:next file_length
}
