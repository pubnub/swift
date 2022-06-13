//
//  Test+PubNubUserInterface.swift
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

@testable import PubNubUser
import PubNub

import XCTest

class PubNubUserInterfaceTests: XCTestCase {
  
  let testUser = PubNubUser(
    id: "TestUserId",
    name: "TestName",
    type: "TestType",
    status: "TestStatus",
    externalId: "TestExternalID",
    profileURL: URL(string: "http://example.com"),
    email: "TestEmail",
    custom: nil,
    updated: Date.distantPast,
    eTag: "TestETag"
  )

  var mockSession = MockSession()
  
  lazy var pubnub = PubNub(
    configuration: .init(publishKey: "mock-pub", subscribeKey: "mock-sub", userId: "TestUserId"),
    session: mockSession
  )

  let singleValueJSON = """
{
"status": 200,
"data": {
    "id": "TestUserId",
    "name": "TestName",
    "type": "TestType",
    "status": "TestStatus",
    "externalId": "TestExternalID",
    "profileUrl": "http://example.com",
    "email": "TestEmail",
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
    "id": "TestUserId",
    "name": "TestName",
    "type": "TestType",
    "status": "TestStatus",
    "externalId": "TestExternalID",
    "profileUrl": "http://example.com",
    "email": "TestEmail",
    "custom": null,
    "updated": "0001-01-01T00:00:00.000Z",
    "eTag": "TestETag"
  }]
}
"""

  func testUserSort_RawValue() {
    XCTAssertEqual(PubNub.UserSort.id(ascending: true).rawValue, "id")
    XCTAssertEqual(PubNub.UserSort.name(ascending: true).rawValue, "name")
    XCTAssertEqual(PubNub.UserSort.type(ascending: true).rawValue, "type")
    XCTAssertEqual(PubNub.UserSort.status(ascending: true).rawValue, "status")
    XCTAssertEqual(PubNub.UserSort.updated(ascending: true).rawValue, "updated")
  }

  func testUserSort_Ascending() {
    XCTAssertEqual(PubNub.UserSort.id(ascending: true).ascending, true)
    XCTAssertEqual(PubNub.UserSort.name(ascending: true).ascending, true)
    XCTAssertEqual(PubNub.UserSort.type(ascending: false).ascending, false)
    XCTAssertEqual(PubNub.UserSort.status(ascending: false).ascending, false)
    XCTAssertEqual(PubNub.UserSort.updated(ascending: true).ascending, true)
  }

  func testUserSort_RouterParameter_Ascending() {
    XCTAssertEqual(
      PubNub.UserSort.id(ascending: true).routerParameter, "id"
    )
  }

  func testUserSort_RouterParameter_Descending() {
    XCTAssertEqual(
      PubNub.UserSort.type(ascending: false).routerParameter, "type:desc"
    )
  }

  func testUser_FetchUsers() {
    let expectation = XCTestExpectation(description: "Fetch Users API")
    
    let testRouterEndpoint = ObjectsUUIDRouter.Endpoint.all(
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
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsUUIDRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      return .success(.init(
        data: multiValueJSON.data(using: .utf8)
      ))
    }
    
    // Validate Outputs
    pubnub.fetchUsers(sort: [.id(ascending: true)]) { [weak self] result in
      switch result {
      case .success((let users, let next)):
        XCTAssertEqual(users.first, self?.testUser)
        XCTAssertEqual(next as? PubNub.Page, PubNub.Page())
      case .failure(let error):
        XCTFail("Failed due to error \(error)")
      }
      expectation.fulfill()
    }
  
    wait(for: [expectation], timeout: 1.0)
  }

  func testUser_FetchUser_ConfigUserId() {
    let expectation = XCTestExpectation(description: "Fetch User API")
    
    let testRouterEndpoint = ObjectsUUIDRouter.Endpoint.fetch(
      metadataId: pubnub.configuration.userId,
      customFields: true
    )
    
    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsUUIDRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      return .success(.init(data: singleValueJSON.data(using: .utf8)))
    }
    
    // Validate Outputs
    pubnub.fetchUser { [weak self] result in
      switch result {
      case .success(let user):
        XCTAssertEqual(user, self?.testUser)
      case .failure(let error):
        XCTFail("Failed due to error \(error)")
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testUser_CreateUser() {
    let expectation = XCTestExpectation(description: "Fetch User API")
    
    let testRouterEndpoint = ObjectsUUIDRouter.Endpoint.set(
      metadata: PubNubUUIDMetadataBase(
        metadataId: pubnub.configuration.userId,
        name: testUser.name,
        type: testUser.type,
        status: testUser.status,
        externalId: testUser.externalId,
        profileURL: testUser.profileURL?.absoluteString,
        email: testUser.email,
        custom: testUser.custom?.flatJSON,
        updated: nil,
        eTag: nil
      ),
      customFields: true
    )
    
    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsUUIDRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      
      return .success(.init(
        data: singleValueJSON.data(using: .utf8)
      ))
    }
    
    // Validate Outputs
    pubnub.createUser(
      name: testUser.name,
      type: testUser.type,
      status: testUser.status,
      externalId: testUser.externalId,
      profileUrl: testUser.profileURL,
      email: testUser.email,
      custom: testUser.custom
    ) { [weak self] result in
      switch result {
      case .success(let user):
        XCTAssertEqual(user, self?.testUser)
      case .failure(let error):
        XCTFail("Failed due to error \(error)")
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testUser_UpdateUser() {
    let expectation = XCTestExpectation(description: "Fetch User API")
    
    let testRouterEndpoint = ObjectsUUIDRouter.Endpoint.set(
      metadata: PubNubUUIDMetadataBase(
        metadataId: pubnub.configuration.userId,
        name: testUser.name,
        type: testUser.type,
        status: testUser.status,
        externalId: testUser.externalId,
        profileURL: testUser.profileURL?.absoluteString,
        email: testUser.email,
        custom: testUser.custom?.flatJSON,
        updated: nil,
        eTag: nil
      ),
      customFields: true
    )
    
    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsUUIDRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      
      return .success(.init(
        data: singleValueJSON.data(using: .utf8)
      ))
    }
    
    // Validate Outputs
    pubnub.updateUser(
      name: testUser.name,
      type: testUser.type,
      status: testUser.status,
      externalId: testUser.externalId,
      profileUrl: testUser.profileURL,
      email: testUser.email,
      custom: testUser.custom
    ) { [weak self] result in
      switch result {
      case .success(let user):
        XCTAssertEqual(user, self?.testUser)
      case .failure(let error):
        XCTFail("Failed due to error \(error)")
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testUser_RemoveUser() {
    let expectation = XCTestExpectation(description: "Fetch User API")
    
    let testRouterEndpoint = ObjectsUUIDRouter.Endpoint.remove(
      metadataId: pubnub.configuration.uuid
    )
    
    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsUUIDRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      return .success(.init(
        data: singleValueJSON.data(using: .utf8)
      ))
    }
    
    // Validate Outputs
    pubnub.removeUser { result in
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
