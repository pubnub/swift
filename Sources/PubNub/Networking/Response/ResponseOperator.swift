//
//  ResponseOperator.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - Response Decoder

/// The object responsible for decoding the raw response data
public protocol ResponseDecoder where Payload: Codable {
  associatedtype Payload

  /// The method called when attempting to decode the response data for a given Endpoint
  ///
  /// - Parameters:
  ///   - response: The raw `Response` to be decoded
  ///   - decoder: The `ResponseDecoder` used to decode the raw response data
  /// - Returns: The decoded payload or the error that occurred during the decoding process
  func decode(response: EndpointResponse<Data>) -> Result<EndpointResponse<Payload>, Error>

  /// The method called when attempting to decode the response error data for a given Endpoint
  ///
  /// - Parameters:
  ///   - endpoint: The endpoint that was requested
  ///   - request: The `URLRequest` that failed
  ///   - response: The `HTTPURLResponse` that was returned
  ///   - for: The `ResponseDecoder` used to decode the raw response data
  /// - Returns: The `PubNubError` that represents the response error
  func decodeError(router: HTTPRouter, request: URLRequest, response: HTTPURLResponse, for data: Data) -> PubNubError?

  /// The method called when attempting to decode the response error data for a given Endpoint
  ///
  /// - Parameters:
  ///   - response: The response to be decrypted
  /// - Returns: The decrypted Payload or an Error
  func decrypt(response: EndpointResponse<Payload>) -> Result<EndpointResponse<Payload>, Error>
}

public extension ResponseDecoder {
  func decodeError(router: HTTPRouter, request: URLRequest, response: HTTPURLResponse, for data: Data) -> PubNubError? {
    return decodeDefaultError(router: router, request: request, response: response, for: data)
  }

  func decode(response: EndpointResponse<Data>) -> Result<EndpointResponse<Payload>, Error> {
    do {
      let decodedPayload = try Constant.jsonDecoder.decode(Payload.self, from: response.payload)

      let decodedResponse = EndpointResponse<Payload>(router: response.router,
                                                      request: response.request,
                                                      response: response.response,
                                                      data: response.data,
                                                      payload: decodedPayload)

      return .success(decodedResponse)
    } catch {
      return .failure(PubNubError(.jsonDataDecodingFailure, response: response, error: error))
    }
  }

  func decrypt(response: EndpointResponse<Payload>) -> Result<EndpointResponse<Payload>, Error> {
    return .success(response)
  }

  func decodeDefaultError(
    router: HTTPRouter,
    request: URLRequest,
    response: HTTPURLResponse,
    for data: Data
  ) -> PubNubError? {
    // Attempt to decode based on general system response payload
    let generalErrorPayload = try? Constant.jsonDecoder.decode(GenericServicePayloadResponse.self, from: data)

    return PubNubError(reason: generalErrorPayload?.pubnubReason,
                       router: router, request: request, response: response,
                       additional: generalErrorPayload?.details,
                       affectedChannels: generalErrorPayload?.affectedChannels,
                       affectedChannelGroups: generalErrorPayload?.affectedChannelGroups)
  }
}

// MARK: - Request: Response Handling

extension Request {
  public func response<D: ResponseDecoder>(
    on queue: DispatchQueue = .main,
    decoder responseDecoder: D,
    completion: @escaping (Result<EndpointResponse<D.Payload>, Error>) -> Void
  ) {
    appendResponseCompletion { result in
      queue.async {
        completion(
          result.flatMap { response in
            // Decode the data response into the correct data type
            responseDecoder.decode(response: response).flatMap { decoded in
              // Do any decryption of the decoded data result
              responseDecoder.decrypt(response: decoded)
            }
          }
        )
      }
    }
  }

  func appendResponseCompletion(_ closure: @escaping (Result<EndpointResponse<Data>, Error>) -> Void) {
    // Add the completion closure to the request and wait for it to complete
    requestQueue.async { [weak self] in
      self?.atomicState.lockedWrite { mutableState in
        mutableState.responseCompletionClosure = closure
      }
    }
  }

  func processResponseCompletion(_ result: Result<EndpointResponse<Data>, Error>) {
    // Request is now complete, so fire the stored completion closure
    var responseCompletion: ((Result<EndpointResponse<Data>, Error>) -> Void)?

    atomicState.lockedWrite { state in
      responseCompletion = state.responseCompletionClosure

      if state.taskState.canTransition(to: .finished) {
        state.taskState = .finished
      }
    }

    responseCompletion?(result)
  }
}
