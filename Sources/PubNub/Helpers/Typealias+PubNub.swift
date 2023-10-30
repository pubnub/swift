//
//  Typealias+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
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
