//
//  01-files.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

// swiftlint:disable line_length
// snippet.import
import PubNubSDK
import Foundation

// snippet.end

// snippet.pubnub
// Initializes a PubNub object with the configuration
let pubnub = PubNub(
  configuration: PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "myUniqueUserId"
  )
)

// snippet.end

// snippet.send-file
// Sends a File to a channel
pubnub.send(
  .file(url: URL(fileURLWithPath: "/path/to/your/file.jpg")),
  channel: "my_channel",
  remoteFilename: "cat_picture.jpg",
  publishRequest: .init(additionalMessage: ["text": "Look at this photo!"], customMessageType: "yourCustomMessageType")
) { (fileTask: HTTPFileUploadTask) in
  print("The task \(fileTask.urlSessionTask.taskIdentifier) has started uploading; no need to call `resume()`")
  print("If needed, the `URLSessionUploadTask` can be accessed with `fileTask.urlSessionTask`")
  print("You can use `fileTask.progress` to populate a `UIProgressView`/`ProgressView`")
} completion: { result in
  switch result {
  case let .success((task, file, publishedAt)):
    print("The file with an ID of \(file.fileId) was uploaded at \(publishedAt) timetoken)")
  case let .failure(error):
    print("An error occurred while uploading the file: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.list-files
// Retrieve list of files uploaded to a channel
pubnub.listFiles(channel: "my_channel") { result in
  switch result {
  case let .success(response):
    print("There are \(response.files.count) file(s) found")
    print("The next page used for pagination: \(String(describing: response.next))")
  case let .failure(error):
    print("An error occurred while fetching the file list: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.generate-file-download-url
// Generate a download URL for a File
let downloadURL = try? pubnub.generateFileDownloadURL(
  channel: "some-channel",
  fileId: "some-file-id",
  filename: "filename"
)
// snippet.end

// snippet.download-file
// Replace `fileURL:` with your destination URL
let requestFile = PubNubLocalFileBase(
  channel: "my_channel",
  fileId: "fileId-from-PubNub",
  fileURL: URL(fileURLWithPath: "your/download/url.png")
)

// Download the File to the specified URL
pubnub.download(
  file: requestFile,
  toFileURL: requestFile.fileURL
) { (fileTask: HTTPFileDownloadTask) in
  print("The task \(fileTask.taskIdentifier) has started downloading; no need to call `resume()`")
  print("If needed, the `URLSessionUploadTask` can be accessed with `fileTask.urlSessionTask`")
  print("You can use `fileTask.progress` to populate a `UIProgressView`/`ProgressView`")
} completion: { result in
  switch result {
  case let .success((task, newFile)):
    print("The file task \(task.taskIdentifier) downloaded successfully to \(newFile.fileURL), which might be different than \(requestFile.fileURL)")
    print("This also might mean that \(newFile.filename) could be different from \(newFile.remoteFilename)")
  case let .failure(error):
    print("An error occurred while downloading the file: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.download-file-resume
// Assumes this is the portion of the File that was downloaded prior to the interruption.
// See above documentation on how to obtain this data
let resumeData = Data()

// Replace `fileURL:` with your destination URL
let fileToResume = PubNubLocalFileBase(
  channel: "my_channel",
  fileId: "fileId-from-PubNub",
  fileURL: URL(fileURLWithPath: "your/download/url.png")
)

// Resume the download of the File
pubnub.download(
  file: fileToResume,
  toFileURL: fileToResume.fileURL,
  resumeData: resumeData
) { (fileTask: HTTPFileDownloadTask) in
  print("The task \(fileTask.urlSessionTask.taskIdentifier) has started downloading; no need to call `resume()`")
  print("If needed, the `URLSessionUploadTask` can be accessed with `fileTask.urlSessionTask`")
  print("You can use `fileTask.progress` to populate a `UIProgressView`/`ProgressView`")
} completion: { result in
  switch result {
  case let .success((task, newFile)):
    print("The file task \(task.taskIdentifier) downloaded successfully to \(newFile.fileURL), which might be different than \(fileToResume.fileURL)")
    print("This also might mean that \(newFile.filename) could be different from \(newFile.remoteFilename)")
  case let .failure(error):
    print("An error occurred while downloading the file: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.download-file-custom-url-session
// Initialize a PubNub object with a custom URL session
let pubNubWithCustomFileURLSession = PubNub(
  configuration: PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "myUniqueUserId"
  ),
  fileSession: URLSession(
    configuration: .init(),
    delegate: FileSessionManager(),
    delegateQueue: nil
  )
)

// Replace `fileURL:` with your destination URL
let fileToDownload = PubNubLocalFileBase(
  channel: "my_channel",
  fileId: "fileId-from-PubNub",
  fileURL: URL(fileURLWithPath: "your/download/url.png")
)

// Download the File using a PubNub instance with a custom file session
pubNubWithCustomFileURLSession.download(
  file: fileToDownload,
  toFileURL: fileToDownload.fileURL
) { (fileTask: HTTPFileDownloadTask) in
  print("The task \(fileTask.urlSessionTask.taskIdentifier) has started downloading; no need to call `resume()`")
  print("If needed, the `URLSessionUploadTask` can be accessed with `fileTask.urlSessionTask`")
  print("You can use `fileTask.progress` to populate a `UIProgressView`/`ProgressView` ")
} completion: { result in
  switch result {
  case let .success((task, newFile)):
    print("The file task \(task.taskIdentifier) downloaded successfully to \(newFile.fileURL), which might be different than \(fileToDownload.fileURL)")
    print("This also might mean that \(newFile.filename) could be different from \(newFile.remoteFilename)")
  case let .failure(error):
    print("An error occurred while downloading the file: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-file
// Remove a File from a channel
pubnub.remove(
  fileId: "id-of-a-file",
  filename: "example.png",
  channel: "my_channel"
) { result in
  switch result {
  case let .success(response):
    print("The file whose ID is \(response.fileId) was removed from \(response.channel)")
  case let .failure(error):
    print("An error occurred while removing the file: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.publish-file-request
// Assume this is a File that you want to publish to a channel
let someFile = PubNubLocalFileBase(
  channel: "my_channel",
  fileId: "fileId-from-PubNub",
  fileURL: URL(fileURLWithPath: "path/to/example.png")
)

// Provides additional message that can be send during a File publish
let publishRequest = PubNub.PublishFileRequest(
  additionalMessage: "Some additional message",
  customMessageType: "customMessageType"
)

// Publish the File to a channel
pubnub.publish(
  file: someFile,
  request: publishRequest
) { result in
  switch result {
  case let .success(timetoken):
    print("File Successfully Published at: \(timetoken)")
  case let .failure(error):
    print("Error publishing file: \(error.localizedDescription)")
  }
}
// snippet.end
// swiftlint:enable line_length
