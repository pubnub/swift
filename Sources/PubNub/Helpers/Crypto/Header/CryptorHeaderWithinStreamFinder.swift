//
//  CryptorHeaderFinder.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2023 PubNub Inc.
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
