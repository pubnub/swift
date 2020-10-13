//
//  FileAPIViewController.swift
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

import UIKit

import PubNub

enum AlertMessageDirection: String {
  case upload = "Uploading"
  case download = "Downloading"
  case sync = "Syncing"
  case remove = "Removing"
}

class FileAPIViewController: UIViewController {
  // Outlets
  @IBOutlet var channelInput: UITextField!
  @IBOutlet var tableView: UITableView!

  // PubNub
  var pubnub: PubNub!
  var listener: SubscriptionListener?

  // Table Data Source
  var currentChannel: String?
  var fileDataSource = [LocalFileExample]()

  // Helpers
  var fileManager = FileManager.default
  var rootDirectory: URL?

  override func viewDidLoad() {
    super.viewDidLoad()

    // Table Delegates
    tableView.delegate = self
    tableView.dataSource = self

    // Setup File Listener
    let listener = SubscriptionListener()
    listener.didReceiveFileUpload = { [weak self] event in
      if let localFile = try? LocalFileExample(from: event.file) {
        self?.fileDataSource.append(localFile)
        self?.reloadFiles()
      }
    }
    pubnub.add(listener)
    self.listener = listener

    // Get root document directory
    rootDirectory = try? FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false
    )
  }

  // MARK: Action Outlets

  @IBAction func changeChannelPressed(_: Any) {
    if let channel = channelInput.text {
      updateCurrentChannel(to: channel)
    }
  }

  @IBAction func uploadFilePicker(_: Any) {
    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, macCatalyst 13.0, *) {
      // We copy to get the file into our app space; otherwise it's temporary URL
      // If you only care about uploading the file, and now storing the entire file locally then you can avoid copying here
      picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
    } else {
      picker = UIDocumentPickerViewController(documentTypes: ["public.data"], in: .import)
    }

    picker.delegate = self

    present(picker, animated: true)
  }

  // MARK: Helpers

  func progressAlertView(for progress: Progress, direction: AlertMessageDirection) -> UIAlertController {
    let alert = alertViewController(direction: direction)
    let progressView = UIProgressView(progressViewStyle: .default)
    progressView.setProgress(0.0, animated: true)
    progressView.frame = CGRect(x: 10, y: 70, width: 250, height: 0)
    progressView.observedProgress = progress
    alert.view.addSubview(progressView)
    return alert
  }

  func alertViewController(direction: AlertMessageDirection) -> UIAlertController {
    return UIAlertController(title: "File API", message: "\(direction.rawValue)...", preferredStyle: .alert)
  }

  func reloadFiles() {
    DispatchQueue.main.async { [weak self] in
      guard let strongSelf = self else { return }
      // Dirty way to de-duplicate a List
      strongSelf.fileDataSource = Array(Set(strongSelf.fileDataSource)).sorted(by: { $0.fileId < $1.fileId })
      self?.tableView.reloadData()
    }
  }

  func updateCurrentChannel(to channel: String) {
    if channel == currentChannel {
      return
    }

    let previousChannel = currentChannel

    // Set new current
    currentChannel = channel

    // Unsubscribe from previous
    if let unsubscribe = previousChannel {
      pubnub.unsubscribe(from: [unsubscribe])
    }

    // Present alert that we're syncing
    present(alertViewController(direction: .sync), animated: true)

    // Subscribe to File changes
    pubnub.subscribe(to: [channel])

    // Remove Files
    fileDataSource.removeAll()

    // Collect Local Files
    if let channelDirectory = rootDirectory?.appendingPathComponent(channel) {
      // Create the channel directory
      if !fileManager.fileExists(atPath: channelDirectory.path) {
        do {
          try fileManager.createDirectory(at: channelDirectory, withIntermediateDirectories: true, attributes: [:])
        } catch {
          print("Failed to create channel directory")
        }
      }

      // Get the files from the channel directory
      let files = fileManager.files(in: channelDirectory)

      // Convert file
      fileDataSource = files.compactMap { try? LocalFileExample(from: $0, for: channel) }
    }

    // Collect remote files
    pubnub.listFiles(channel: channel) { [weak self] result in
      switch result {
      case let .success((files, _)):

        files.forEach { file in
          // Check if the fileId exists, and replace
          if let index = self?.fileDataSource.firstIndex(where: { $0.fileId == file.fileId }) {
            if let newLocalFile = try? LocalFileExample(from: file) {
              self?.fileDataSource[index] = newLocalFile
            }
          } else if let newLocalFile = try? LocalFileExample(from: file) {
            self?.fileDataSource.append(newLocalFile)
          }
        }

        self?.reloadFiles()

      case let .failure(error):
        print("File List eUIProgressViewrror: \(error)")
      }

      self?.dismiss(animated: true)
    }
  }

  func syncFile(file: LocalFileExample) {
    switch (file.existsLocally, file.existsRemotely) {
    case (true, true):
      print("The \(file) already exists in all places")
    case (true, false):
      print("The \(file) should start uploading")
      send(.file(url: file.fileURL), channel: file.channel)

    case (false, true):
      print("The \(file) should start downloding")
      download(file)

    case (false, false):
      // We should remove the file
      print("The \(file) does not exist either remotely nor locally")
    }
  }

  func send(_ content: PubNub.FileUploadContent, channel: String) {
    let remoteFilename = (content.rawContent as? URL)?.lastPathComponent ?? "unknown.txt"

    pubnub.send(
      content,
      channel: channel,
      remoteFilename: remoteFilename
    ) { [weak self] (task: HTTPFileUploadTask) in
      DispatchQueue.main.async {
        if let progressView = self?.progressAlertView(for: task.progress, direction: .upload) {
          self?.present(progressView, animated: true)
        }
      }
    } completion: { [weak self] result in
      switch result {
      case let .success((_, newFile as PubNubLocalFile, _)):
        if let newLocal = try? LocalFileExample(from: newFile) {
          self?.fileDataSource.removeAll(where: { $0.fileId == newLocal.fileId })
          self?.fileDataSource.append(newLocal)
        }
      case let .success(response):
        if let newFile = try? LocalFileExample(from: response.file) {
          self?.fileDataSource.removeAll(where: { $0.fileId == newFile.fileId })
          self?.fileDataSource.append(newFile)
        }
      case let .failure(error):
        print("Error uploading file \(error)")
      }

      DispatchQueue.main.async {
        self?.fileDataSource.sort(by: { $0.fileId < $1.fileId })
        self?.tableView.reloadData()
        self?.dismiss(animated: true)
      }
    }
  }

  func download(_ file: LocalFileExample) {
    pubnub.download(
      file: file, toFileURL: file.fileURL
    ) { [weak self] (task: HTTPFileDownloadTask) in
      DispatchQueue.main.async {
        if let progressView = self?.progressAlertView(for: task.progress, direction: .download) {
          self?.present(progressView, animated: true)
        }
      }
    } completion: { [weak self] result in
      switch result {
      case let .success(response):

        if let newLocal = try? LocalFileExample(from: response.file) {
          self?.fileDataSource.removeAll(where: { $0.fileId == newLocal.fileId })
          self?.fileDataSource.append(newLocal)
        }

        self?.reloadFiles()

      case let .failure(error):
        print("Error downloading file \(error)")
      }

      DispatchQueue.main.async {
        self?.dismiss(animated: true)
      }
    }
  }
}

// MARK: - Table View Delegates

extension FileAPIViewController: UITableViewDelegate {}
extension FileAPIViewController: UITableViewDataSource {
  func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    return fileDataSource.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "FileAPICell", for: indexPath) as? FileCell else {
      return UITableViewCell()
    }

    let file = fileDataSource[indexPath.row]

    cell.fileId?.text = file.fileId
    cell.fileName?.text = file.filename
    cell.fileSize?.text = "\(file.size) Bytes"

    switch (file.existsLocally, file.existsRemotely) {
    case (true, true):
      cell.fileStatus?.image = UIImage(systemName: "checkmark.icloud")
    case (true, false):
      cell.fileStatus?.image = UIImage(systemName: "icloud.and.arrow.up")
    case (false, true):
      cell.fileStatus?.image = UIImage(systemName: "icloud.and.arrow.down")
    case (false, false):
      // We should remove the file
      print("The \(file) does not exist either remotely nor locally")
    }
    return cell
  }

  func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    syncFile(file: fileDataSource[indexPath.row])
  }

  func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
    return true
  }

  func tableView(
    _: UITableView,
    trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
  ) -> UISwipeActionsConfiguration? {
    let file = fileDataSource[indexPath.row]

    let view = UIContextualAction(style: .normal, title: "View") { _, _, completion in
      let documentViewer = UIDocumentInteractionController(url: file.fileURL)
      documentViewer.delegate = self
      documentViewer.presentPreview(animated: true)
      completion(true)
    }

    let delete = UIContextualAction(style: .destructive, title: "Remove") { _, _, completion in
      self.present(self.alertViewController(direction: .remove), animated: true)
      self.pubnub.remove(fileId: file.fileId, filename: file.filename, channel: file.channel) { [weak self] _ in
        try? FileManager.default.removeItem(at: file.fileURL)

        self?.fileDataSource.removeAll(where: { $0.fileId == file.fileId })

        self?.tableView.reloadData()

        self?.dismiss(animated: true)
        completion(true)
      }
    }
    var actions = [UIContextualAction]()

    if fileDataSource[indexPath.row].existsLocally {
      actions.append(view)
    }
    actions.append(delete)

    let config = UISwipeActionsConfiguration(actions: actions)
    config.performsFirstActionWithFullSwipe = true

    return config
  }
}

// MARK: - Document Delegates

extension FileAPIViewController: UIDocumentInteractionControllerDelegate {
  func documentInteractionControllerViewControllerForPreview(
    _: UIDocumentInteractionController
  ) -> UIViewController {
    return self
  }
}

extension FileAPIViewController: UIDocumentPickerDelegate {
  func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    if let channel = channelInput.text {
      for url in urls {
        send(.file(url: url), channel: channel)
      }
    }
  }
}
