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
  
  func findHeader() throws -> (header: CryptorHeader, continuationStream: InputStream) {
    let possibleHeaderBytes = read(maxLength: 100)
    let parsingRes = try CryptorHeaderParser(data: possibleHeaderBytes).parseAndReturnProcessedBytes()
    let noOfBytesProcessedByParser = parsingRes.bytesProcessed.count
    let continuationStream: InputStream
    
    switch parsingRes.header {
    case .none:
      continuationStream = MultipartInputStream(
        inputStreams: [InputStream(data: possibleHeaderBytes), stream]
      )
    default:
      continuationStream = MultipartInputStream(
        inputStreams: [InputStream(data: possibleHeaderBytes.suffix(from: noOfBytesProcessedByParser)), stream]
      )
    }
    return (
      header: parsingRes.header,
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
      if numberOfBytesRead > 0 && buffer.count != numberOfBytesRead {
        buffer = Array(buffer[0 ..< numberOfBytesRead])
      }
      content += buffer
      
    } while numberOfBytesRead < maxLength && stream.hasBytesAvailable;
    
    return Data(
      bytes: content,
      count: content.count
    )
  }
}
