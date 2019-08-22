//
//  ResponseOperator.swift
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

// MARK: - Response Decoder

public protocol ResponseDecoder where Payload: Codable {
  associatedtype Payload

  func decode(response: Response<Data>) -> Result<Response<Payload>, Error>
  func decodeError(endpoint: Endpoint, request: URLRequest, response: HTTPURLResponse, for data: Data?) -> PNError?
  func decrypt(response: Response<Payload>) -> Result<Response<Payload>, Error>
}

extension ResponseDecoder {
  func decodeError(endpoint: Endpoint, request: URLRequest, response: HTTPURLResponse, for data: Data?) -> PNError? {
    return decodeDefaultError(endpoint: endpoint, request: request, response: response, for: data)
  }

  func decode(response: Response<Data>) -> Result<Response<Payload>, Error> {
    do {
      let decodedPayload = try Constant.jsonDecoder.decode(Payload.self, from: response.payload)

      let decodedResponse = Response<Payload>(router: response.router,
                                              request: response.request,
                                              response: response.response,
                                              data: response.data,
                                              payload: decodedPayload)

      return .success(decodedResponse)
    } catch {
      return .failure(PNError
        .endpointFailure(.jsonDataDecodeFailure(response.data, with: error),
                         response.endpoint,
                         response.request,
                         response.response))
    }
  }

  func decrypt(response: Response<Payload>) -> Result<Response<Payload>, Error> {
    return .success(response)
  }

  func decodeDefaultError(
    endpoint: Endpoint,
    request: URLRequest,
    response: HTTPURLResponse,
    for data: Data?
  ) -> PNError? {
    // Attempt to decode based on general system response payload
    if let data = data, !(data.isEmpty || String(bytes: data, encoding: .utf8) == "{}") {
      let generalErrorPayload = try? Constant.jsonDecoder.decode(GenericServicePayloadResponse.self,
                                                                 from: data)
      let pnError = PNError.convert(endpoint: endpoint,
                                    generalError: generalErrorPayload,
                                    request: request,
                                    response: response)

      return pnError
    }

    // Use the code to determine the error
    let generalErrorPayload = GenericServicePayloadResponse(message: "No Message Received",
                                                            service: "No Service Received",
                                                            status: .init(rawValue: response.statusCode),
                                                            error: true)
    return PNError.convert(endpoint: endpoint,
                           generalError: generalErrorPayload,
                           request: request,
                           response: response)
  }
}

// MARK: - Request: Response Handling

extension Request {
  public func response<D: ResponseDecoder>(
    on queue: DispatchQueue = .main,
    decoder responseDecoder: D,
    completion: @escaping (Result<Response<D.Payload>, Error>) -> Void
  ) {
    appendResponseCompletion { [weak self] in
      guard let strongSelf = self else {
        return
      }

      switch self?.error {
      case let .some(error as PNError):
        queue.async { completion(.failure(error)) }
        return
      case let .some(error):
        queue.async { completion(.failure(PNError.unknownError(error, strongSelf.endpoint))) }
        return
      default:
        break
      }

      // Ensure that we have valid request, response, and data
      guard let urlRequest = self?.urlRequest,
        let urlResponse = self?.urlResponse,
        let router = self?.router else {
        queue.async { completion(.failure(PNError
            .unknown(ErrorDescription.PNError.missingRequestResponse,
                     strongSelf.endpoint))) }

        return
      }

      let dataResponse = Response<Data>(router: router,
                                        request: urlRequest,
                                        response: urlResponse,
                                        payload: self?.data ?? Data())

      // Decode the Response
      switch dataResponse.router.decode(response: dataResponse, decoder: responseDecoder) {
      case let .success(decodedResponse):
        self?.sessionStream?.emitDidDecode(dataResponse)

        queue.async {
          completion(responseDecoder.decrypt(response: decodedResponse))
        }
      case let .failure(decodeError):
        self?.sessionStream?.emitFailedToDecode(dataResponse, with: decodeError)
        queue.async { completion(.failure(decodeError)) }
      }
    }
  }

  func appendResponseCompletion(_ closure: @escaping EmptyClosure) {
    // Add the completion closure to the request and wait for it to complete
    atomicState.lockedWrite { mutableState in
      mutableState.responseCompletionClosure = closure

      if mutableState.taskState == .finished {
        mutableState.taskState = .resumed
      }

      if mutableState.responseProcessingFinished {
        requestQueue.async { self.processResponseCompletion() }
      }
    }
  }

  func processResponseCompletion() {
    // Request is now complete, so fire the stored completion closure
    var responseCompletion: (() -> Void)?

    atomicState.lockedWrite { mutableState in
      responseCompletion = mutableState.responseCompletionClosure

      if mutableState.taskState.canTransition(to: .finished) {
        mutableState.taskState = .finished
      }

      mutableState.responseProcessingFinished = true
    }

    responseCompletion?()
  }
}
