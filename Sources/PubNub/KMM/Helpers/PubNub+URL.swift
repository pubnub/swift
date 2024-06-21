//
//  PubNub+URL.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

extension PubNub {
  func generateFileDownloadURL(for file: PubNubFile) -> URL? {
    try? generateFileDownloadURL(
      channel: file.channel,
      fileId: file.fileId,
      filename: file.filename
    )
  }
}
