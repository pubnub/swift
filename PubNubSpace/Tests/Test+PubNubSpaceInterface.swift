//
//  Test+PubNubSpaceInterface.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2022 PubNub Inc.
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

@testable import PubNubSpace
import PubNub

import XCTest

class PubNubSpaceInterfaceTests: XCTestCase {
  
  let testSpace = PubNubSpace(
    id: "TestSpaceId",
    name: "TestName",
    type: "TestType",
    status: "TestStatus",
    spaceDescription: "TestDescription",
    custom: nil,
    updated: Date.distantPast,
    eTag: "TestETag"
  )
  
  var mockSession = MockSession()
  
  lazy var pubnub = PubNub(
    configuration: .init(publishKey: "mock-pub", subscribeKey: "mock-sub", userId: "TestSpaceId"),
    session: mockSession
  )
  
  let singleValueJSON = """
{
"status": 200,
"data": {
    "id": "TestSpaceId",
    "name": "TestName",
    "type": "TestType",
    "status": "TestStatus",
    "description": "TestDescription",
    "custom": null,
    "updated": "0001-01-01T00:00:00.000Z",
    "eTag": "TestETag"
  }
}
"""
  
  let multiValueJSON = """
{
"status": 200,
"data": [{
    "id": "TestSpaceId",
    "name": "TestName",
    "type": "TestType",
    "status": "TestStatus",
    "description": "TestDescription",
    "custom": null,
    "updated": "0001-01-01T00:00:00.000Z",
    "eTag": "TestETag"
  }]
}
"""
  
  func testSpaceSort_RawValue() {
    XCTAssertEqual(PubNub.SpaceSort.id(ascending: true).rawValue, "id")
    XCTAssertEqual(PubNub.SpaceSort.name(ascending: true).rawValue, "name")
    XCTAssertEqual(PubNub.SpaceSort.type(ascending: true).rawValue, "type")
    XCTAssertEqual(PubNub.SpaceSort.status(ascending: true).rawValue, "status")
    XCTAssertEqual(PubNub.SpaceSort.updated(ascending: true).rawValue, "updated")
  }
  
  func testSpaceSort_Ascending() {
    XCTAssertEqual(PubNub.SpaceSort.id(ascending: true).ascending, true)
    XCTAssertEqual(PubNub.SpaceSort.name(ascending: true).ascending, true)
    XCTAssertEqual(PubNub.SpaceSort.type(ascending: false).ascending, false)
    XCTAssertEqual(PubNub.SpaceSort.status(ascending: false).ascending, false)
    XCTAssertEqual(PubNub.SpaceSort.updated(ascending: true).ascending, true)
  }
  
  func testSpaceSort_RouterParameter_Ascending() {
    XCTAssertEqual(
      PubNub.SpaceSort.id(ascending: true).routerParameter, "id"
    )
  }
  
  func testSpaceSort_RouterParameter_Descending() {
    XCTAssertEqual(
      PubNub.SpaceSort.type(ascending: false).routerParameter, "type:desc"
    )
  }
  
  func testSpace_FetchSpaces() {
    let expectation = XCTestExpectation(description: "Fetch Spaces API")
    
    let testRouterEndpoint = ObjectsChannelRouter.Endpoint.all(
      customFields: true,
      totalCount: true,
      filter: nil,
      sort: ["id"],
      limit: 100,
      start: nil,
      end: nil
    )
    
    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsChannelRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      return .success(.init(
        data: multiValueJSON.data(using: .utf8)
      ))
    }
    
    // Validate Outputs
    pubnub.fetchSpaces(sort: [.id(ascending: true)]) { [weak self] result in
      switch result {
      case .success((let spaces, let next)):
        XCTAssertEqual(spaces.first, self?.testSpace)
        XCTAssertEqual(next as? PubNub.Page, PubNub.Page())
      case .failure(let error):
        XCTFail("Failed due to error \(error)")
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testSpace_FetchSpace_ConfigSpaceId() {
    let expectation = XCTestExpectation(description: "Fetch Space API")
    
    let testRouterEndpoint = ObjectsChannelRouter.Endpoint.fetch(
      metadataId: testSpace.id,
      customFields: true
    )
    
    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsChannelRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      return .success(.init(data: singleValueJSON.data(using: .utf8)))
    }
    
    // Validate Outputs
    pubnub.fetchSpace(spaceId: testSpace.id) { [weak self] result in
      switch result {
      case .success(let space):
        XCTAssertEqual(space, self?.testSpace)
      case .failure(let error):
        XCTFail("Failed due to error \(error)")
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testSpace_CreateSpace() {
    let expectation = XCTestExpectation(description: "Fetch Space API")
    
    let testRouterEndpoint = ObjectsChannelRouter.Endpoint.set(
      metadata: PubNubChannelMetadataBase(
        metadataId: testSpace.id,
        name: testSpace.name,
        type: testSpace.type,
        status: testSpace.status,
        channelDescription: testSpace.spaceDescription,
        custom: testSpace.custom?.flatJSON,
        updated: nil,
        eTag: nil
      ),
      customFields: true
    )
    
    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsChannelRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      
      return .success(.init(
        data: singleValueJSON.data(using: .utf8)
      ))
    }
    
    // Validate Outputs
    pubnub.createSpace(
      spaceId: testSpace.id,
      name: testSpace.name,
      type: testSpace.type,
      status: testSpace.status,
      description: testSpace.spaceDescription,
      custom: testSpace.custom
    ) { [weak self] result in
      switch result {
      case .success(let space):
        XCTAssertEqual(space, self?.testSpace)
      case .failure(let error):
        XCTFail("Failed due to error \(error)")
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testSpace_UpdateSpace() {
    let expectation = XCTestExpectation(description: "Fetch Space API")
    
    let testRouterEndpoint = ObjectsChannelRouter.Endpoint.set(
      metadata: PubNubChannelMetadataBase(
        metadataId: testSpace.id,
        name: testSpace.name,
        type: testSpace.type,
        status: testSpace.status,
        channelDescription: testSpace.spaceDescription,
        custom: testSpace.custom?.flatJSON,
        updated: nil,
        eTag: nil
      ),
      customFields: true
    )
    
    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsChannelRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      
      return .success(.init(
        data: singleValueJSON.data(using: .utf8)
      ))
    }
    
    // Validate Outputs
    pubnub.updateSpace(
      spaceId: testSpace.id,
      name: testSpace.name,
      type: testSpace.type,
      status: testSpace.status,
      description: testSpace.spaceDescription,
      custom: testSpace.custom
    ) { [weak self] result in
      switch result {
      case .success(let space):
        XCTAssertEqual(space, self?.testSpace)
      case .failure(let error):
        XCTFail("Failed due to error \(error)")
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testSpace_RemoveSpace() {
    let expectation = XCTestExpectation(description: "Fetch Space API")
    
    let testRouterEndpoint = ObjectsChannelRouter.Endpoint.remove(
      metadataId: pubnub.configuration.uuid
    )
    
    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsChannelRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      return .success(.init(
        data: singleValueJSON.data(using: .utf8)
      ))
    }
    
    // Validate Outputs
    pubnub.removeSpace(spaceId: testSpace.id) { result in
      switch result {
      case .success:
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Failed due to error \(error)")
      }
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
}
