//
//  URL+PubNub.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
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

// NOTE: Still currently in beta for macOS https://developer.apple.com/documentation/uniformtypeidentifiers/
#if canImport(UniformTypeIdentifiers)
  import UniformTypeIdentifiers
#endif

#if os(iOS) || os(watchOS) || os(tvOS)
  import MobileCoreServices
#elseif os(macOS)
  import CoreServices
#endif

public extension URL {
  /// Appends a news query items to an existing URL
  /// - parameters:
  ///   - queryItems: The `URLQueryItem` collection to append
  /// - returns: A new URL with the provided query items or nil if the appending failed
  func appending(queryItems: [URLQueryItem]) -> URL? {
    var urlComponents = URLComponents(string: absoluteString)

    if urlComponents?.queryItems != nil {
      urlComponents?.queryItems?.merge(queryItems)
    } else {
      urlComponents?.queryItems = queryItems
    }

    return urlComponents?.url
  }

  /// The size of the file found at the URL
  ///
  /// Will return a value of 0 if the file cannot be found
  var sizeOf: Int {
    if let fileResources = try? resourceValues(forKeys: [.fileSizeKey]),
       let fileSize = fileResources.fileSize {
      return fileSize
    }
    return 0
  }

  /// The content of the URL if one exists
  var contentType: String {
    #if canImport(UniformTypeIdentifiers)
      if #available(iOS 14.0, macOS 11.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, *) {
        // swiftlint:disable:next line_length
        guard let contentType = try? self.resourceValues(forKeys: [.contentTypeKey]).contentType?.preferredMIMEType else {
          return "application/octet-stream"
        }

        return contentType
      }

      return preferenceIdentifier()
    #else
      return preferenceIdentifier()
    #endif
  }

  private func preferenceIdentifier() -> String {
    let fileExtension = UTTypeCreatePreferredIdentifierForTag(
      kUTTagClassFilenameExtension, pathExtension as CFString, nil
    )

    if let fileExt = fileExtension?.takeRetainedValue(),
       let mimeType = UTTypeCopyPreferredTagWithClass(fileExt, kUTTagClassMIMEType)?.takeRetainedValue() {
      return mimeType as String
    }
    return "application/octet-stream"
  }

  internal func filenameWithoutExtension() -> String {
    // Default to last path if either path or extension are empty
    if pathExtension.isEmpty || lastPathComponent.isEmpty {
      return lastPathComponent
    }

    // pathExtension.count + 1 represents the extension and the assumed '.' seperator
    return String(lastPathComponent.prefix(lastPathComponent.count - (pathExtension.count + 1)))
  }
}
