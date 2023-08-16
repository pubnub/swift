//
//  PresenceLeaveRequest.swift
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

class PresenceLeaveRequest {
  let channels: [String]
  let groups: [String]
  
  private let configuration: PubNubConfiguration
  private let session: SessionReplaceable
  private let sessionResponseQueue: DispatchQueue
  private var request: RequestReplaceable?
  
  init(
    channels: [String],
    groups: [String],
    configuration: PubNubConfiguration,
    session: SessionReplaceable,
    sessionResponseQueue: DispatchQueue
  ) {
    self.channels = channels
    self.groups = groups
    self.configuration = configuration
    self.session = session
    self.sessionResponseQueue = sessionResponseQueue
  }
  
  func execute(completionBlock: @escaping (Result<Void, PubNubError>) -> Void) {
    request = session.request(with: PresenceRouter(
      .leave(channels: channels, groups: groups),
      configuration: configuration), requestOperator: nil
    )
    request?.validate().response(on: sessionResponseQueue, decoder: GenericServiceResponseDecoder()) { result in
      switch result {
      case .success(_):
        completionBlock(.success(()))
      case .failure(let error):
        completionBlock(.failure(error as? PubNubError ?? PubNubError(.unknown, underlying: error)))
      }
    }
  }
  
  func cancel() {
    request?.cancel(PubNubError(.clientCancelled))
  }
}
