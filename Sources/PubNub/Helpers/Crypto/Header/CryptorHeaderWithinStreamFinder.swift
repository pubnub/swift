//
//  CryptorHeaderWithinStreamFinder.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

struct CryptorHeaderWithinStreamFinder {
  let stream: InputStream
  
  // Attempts to find CryptorHeader in the given InputStream.
  // Returns InputStream that immediately follows CryptorHeader
  func findHeader() throws -> (header: CryptorHeader, cryptorDefinedData: Data, continuationStream: InputStream) {
    let buffer = read(maxLength: 1024)
    let header = try CryptorHeaderParser(data: buffer).parse()
    let headerLength = header.length()
    
    let continuationStream: InputStream
    let cryptorDefinedData: Data
    
    switch header {
    case .none:
      // There is no CryptorHeader, so all supplied buffer bytes belong to the contents of the File
      cryptorDefinedData = Data()
      continuationStream = MultipartInputStream(inputStreams: [InputStream(data: buffer), stream])
    case .v1(_, let dataLength):
      // Detects whether it's safe to extract metadata
      guard headerLength + dataLength < buffer.count else {
        throw PubNubError(.decryptionFailure, additional: ["Cannot extract metadata for CryptorHeader v1"])
      }
      // Extracts Cryptor-defined data from the supplied buffer
      cryptorDefinedData = buffer.subdata(in: headerLength..<headerLength + dataLength)
      // Extracts possible bytes from the supplied buffer that follow metadata. These bytes are File content
      let exceedFileContent = InputStream(data: buffer.suffix(from: headerLength + dataLength))
      // Returns final InputStream that follows CryptorHeader
      continuationStream = MultipartInputStream(inputStreams: [exceedFileContent, stream])
    }
    
    return (
      header: header,
      cryptorDefinedData: cryptorDefinedData,
      continuationStream: continuationStream
    )
  }
  
  private func read(maxLength: Int) -> Data {
    var buffer = [UInt8](repeating: 0, count: maxLength)
    var numberOfBytesRead = 0
    var content: [UInt8] = []
    
    if stream.streamStatus == .notOpen {
      stream.open()
    }
    repeat {
      numberOfBytesRead = stream.read(
        &buffer,
        maxLength: maxLength
      )
      guard numberOfBytesRead > 0 else {
        break;
      }
      if buffer.count != numberOfBytesRead {
        content += Array(buffer[0 ..< numberOfBytesRead])
      } else {
        content += buffer
      }
    } while numberOfBytesRead < maxLength && stream.hasBytesAvailable;
    
    return Data(
      bytes: content,
      count: content.count
    )
  }
}
