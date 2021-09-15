//
//  Typealias+PubNub.swift
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

// MARK: - Types

/// 17-digit precision unix time (UTC) since 1970
///
/// - important: A 64-bit `Double` has a max precision of 15-digits, so
///         any value derived from a `TimeInterval` will not be precise
///         enough to rely on when querying PubNub system APIs
public typealias Timetoken = UInt64

typealias AtomicInt = Atomic<Int32>

typealias QueryResult = Result<[URLQueryItem], Error>

// MARK: - Closures

/// A closure capable of validating a network response
typealias ValidationClosure = (HTTPRouter, URLRequest, HTTPURLResponse, Data?) -> Error?

public typealias ProgressTuple = (bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)

/// A snapshot of a File's tranmission progress
public typealias ProgressBlock = (ProgressTuple) -> Void

// MARK: - Tuples

/// A `Tuple` containing the `URLRequest` to upload the `fileURL`, and the fileId/filename the uploaded file will have once uploaded
public typealias FileUploadTuple = (request: URLRequest, fileId: String, filename: String)

/// A `Tuple` containing the `HTTPFileUploadTask` that completed, the `PubNubFile` that was uploaded, and the `Timetoken` when it was published
public typealias FileUploadSendSuccess = (task: HTTPFileUploadTask, file: PubNubFile, publishedAt: Timetoken)
