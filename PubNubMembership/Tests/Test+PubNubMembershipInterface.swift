//
//  Test+PubNubMembershipInterface.swift
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

@testable import PubNubMembership
import PubNub
import PubNubUser
import PubNubSpace

import XCTest

class PubNubMembershipInterfaceTests: XCTestCase {
  let testMembership = PubNubMembership(
    user: PubNubUser(id: "TestUserId"),
    space: PubNubSpace(id: "TestSpaceId"),
    status: "TestStatus",
    custom: MembershipCustom(value: "Tester"),
    updated: Date.distantFuture,
    eTag: "TestETag"
  )

  var mockSession = MockSession()
  
  lazy var pubnub = PubNub(
    configuration: .init(publishKey: "mock-pub", subscribeKey: "mock-sub", userId: "config-userId"),
    session: mockSession
  )
  
  let multiValueJSON = """
{
"status": 200,
"data": [{
    "uuid": {"id": "TestUserId"},
    "channel": {"id": "TestSpaceId"},
    "status": "TestStatus",
    "custom": {"value": "Tester"},
    "updated": "4001-01-01T00:00:00.000Z",
    "eTag": "TestETag"
  }]
}
"""

  func testMembership_UserMembershipSort_RouterParameter() {
    XCTAssertEqual(
      PubNub.UserMembershipSort.status(ascending: true).routerParameter,
      "status"
    )
    XCTAssertEqual(
      PubNub.UserMembershipSort.updated(ascending: true).routerParameter,
      "updated"
    )
    XCTAssertEqual(
      PubNub.UserMembershipSort.user(.id(ascending: true)).routerParameter,
      "uuid.id"
    )
  }

  func testMembership_UserMembershipSort_RouterParameter_Descending() {
    XCTAssertEqual(
      PubNub.UserMembershipSort.status(ascending: false).routerParameter,
      "status:desc"
    )
    XCTAssertEqual(
      PubNub.UserMembershipSort.updated(ascending: false).routerParameter,
      "updated:desc"
    )
    XCTAssertEqual(
      PubNub.UserMembershipSort.user(.id(ascending: false)).routerParameter,
      "uuid.id:desc"
    )
  }

  func testMembership_SpaceMembershipSort_RouterParameter_Ascending() {
    XCTAssertEqual(
      PubNub.SpaceMembershipSort.status(ascending: true).routerParameter,
      "status"
    )
    XCTAssertEqual(
      PubNub.SpaceMembershipSort.updated(ascending: true).routerParameter,
      "updated"
    )
    XCTAssertEqual(
      PubNub.SpaceMembershipSort.space(.id(ascending: true)).routerParameter,
      "channel.id"
    )
  }

  func testMembership_SpaceMembershipSort_RouterParameter_Descending() {
    XCTAssertEqual(
      PubNub.SpaceMembershipSort.status(ascending: false).routerParameter,
      "status:desc"
    )
    XCTAssertEqual(
      PubNub.SpaceMembershipSort.updated(ascending: false).routerParameter,
      "updated:desc"
    )
    XCTAssertEqual(
      PubNub.SpaceMembershipSort.space(.id(ascending: false)).routerParameter,
      "channel.id:desc"
    )
  }
  
  func testMembership_FetchMemberships_UserId() {
    let expectation = XCTestExpectation(description: "Fetch Memberships API")
    
    let testRouterEndpoint = ObjectsMembershipsRouter.Endpoint.fetchMemberships(
      uuidMetadataId: testMembership.user.id,
      customFields: [.custom],
      totalCount: false,
      filter: nil,
      sort: ["status"],
      limit: 100,
      start: nil,
      end: nil
    )

    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsMembershipsRouter)?.endpoint)
    }

    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      return .success(.init(
        data: multiValueJSON.data(using: .utf8)
      ))
    }

    // Validate Outputs
    pubnub.fetchMemberships(
      userId: testMembership.user.id,
      sort: [.status(ascending: true)]
    ) { [weak self] result in
      switch result {
      case .success((let memberships, let next)):
        XCTAssertEqual(memberships.first, self?.testMembership)
        XCTAssertEqual(next as? PubNub.Page, PubNub.Page())
      case .failure(let error):
        XCTFail("Failed due to error \(error)")
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testMembership_FetchMemberships_UserId_Configuration() {
    let expectation = XCTestExpectation(description: "Fetch Memberships API")
    
    let testRouterEndpoint = ObjectsMembershipsRouter.Endpoint.fetchMemberships(
      uuidMetadataId: pubnub.configuration.userId,
      customFields: [.custom],
      totalCount: false,
      filter: nil,
      sort: ["status"],
      limit: 100,
      start: nil,
      end: nil
    )
    
    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsMembershipsRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      return .success(.init(
        data: multiValueJSON.data(using: .utf8)
      ))
    }
  
    var responseMembership = testMembership
    responseMembership.user = PubNubUser(id: pubnub.configuration.userId)
    
    // Validate Outputs
    pubnub.fetchMemberships(sort: [.status(ascending: true)]) { result in
      switch result {
      case .success((let memberships, let next)):
        XCTAssertEqual(memberships.first, responseMembership)
        XCTAssertEqual(next as? PubNub.Page, PubNub.Page())
      case .failure(let error):
        XCTFail("Failed due to error \(error)")
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 155555.0)
  }

  func testMembership_FetchMemberships_SpaceId() {
    let expectation = XCTestExpectation(description: "Fetch Memberships API")
    
    let testRouterEndpoint = ObjectsMembershipsRouter.Endpoint.fetchMembers(
      channelMetadataId: testMembership.space.id,
      customFields: [.custom],
      totalCount: false,
      filter: nil,
      sort: ["status"],
      limit: 100,
      start: nil,
      end: nil
    )
    
    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsMembershipsRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      return .success(.init(
        data: multiValueJSON.data(using: .utf8)
      ))
    }
    
    // Validate Outputs
    pubnub.fetchMemberships(
      spaceId: testMembership.space.id,
      sort: [.status(ascending: true)]
    ) { [weak self] result in
      switch result {
      case .success((let memberships, let next)):
        XCTAssertEqual(memberships.first, self?.testMembership)
        XCTAssertEqual(next as? PubNub.Page, PubNub.Page())
      case .failure(let error):
        XCTFail("Failed due to error \(error)")
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testMembership_AddMembership_UserId_PubNubConfiguration() {
    let expectation = XCTestExpectation(description: "Fetch Membership API")
    
    let testRouterEndpoint = ObjectsMembershipsRouter.Endpoint.setMemberships(
      uuidMetadataId: pubnub.configuration.userId,
      customFields: nil,
      totalCount: false,
      changes: .init(
        set: [.init(
          metadataId: testMembership.space.id,
          status: testMembership.status,
          custom: testMembership.custom?.flatJSON)
        ],
        delete: []),
      filter: nil,
      sort: [],
      limit: 0,
      start: nil,
      end: nil
    )
    
    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsMembershipsRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      return .success(.init(
        data: multiValueJSON.data(using: .utf8)
      ))
    }
    
    // Validate Outputs
    pubnub.addMemberships(
      spaces: [.init(
        spaceId: testMembership.space.id, status: testMembership.status, custom: testMembership.custom
      )]
    ) { result in
      switch result {
      case .success:
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Failed due to error \(error)")
      }
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testMembership_AddMembership_UserId() {
    let expectation = XCTestExpectation(description: "Fetch Membership API")
    
    let testRouterEndpoint = ObjectsMembershipsRouter.Endpoint.setMemberships(
      uuidMetadataId: testMembership.user.id,
      customFields: nil,
      totalCount: false,
      changes: .init(
        set: [.init(
          metadataId: testMembership.space.id,
          status: testMembership.status,
          custom: testMembership.custom?.flatJSON)
        ],
        delete: []),
      filter: nil,
      sort: [],
      limit: 0,
      start: nil,
      end: nil
    )
    
    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsMembershipsRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      return .success(.init(
        data: multiValueJSON.data(using: .utf8)
      ))
    }
    
    // Validate Outputs
    pubnub.addMemberships(
      spaces: [.init(
        spaceId: testMembership.space.id, status: testMembership.status, custom: testMembership.custom
      )],
      to: testMembership.user.id
    ) { result in
      switch result {
      case .success:
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Failed due to error \(error)")
      }
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testMembership_AddMembership_SpaceId() {
    let expectation = XCTestExpectation(description: "Fetch Membership API")
    
    let testRouterEndpoint = ObjectsMembershipsRouter.Endpoint.setMembers(
      channelMetadataId: testMembership.space.id,
      customFields: nil,
      totalCount: false,
      changes: .init(
        set: [.init(
          metadataId: testMembership.user.id,
          status: testMembership.status,
          custom: testMembership.custom?.flatJSON)
        ],
        delete: []),
      filter: nil,
      sort: [],
      limit: 0,
      start: nil,
      end: nil
    )
    
    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsMembershipsRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      return .success(.init(
        data: multiValueJSON.data(using: .utf8)
      ))
    }
    
    // Validate Outputs
    pubnub.addMemberships(
      users: [.init(
        userId: testMembership.user.id, status: testMembership.status, custom: testMembership.custom
      )],
      to: testMembership.space.id
    ) { result in
      switch result {
      case .success:
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Failed due to error \(error)")
      }
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testMembership_UpdateMembership_UserId_PubNubConfiguration() {
    let expectation = XCTestExpectation(description: "Fetch Membership API")
    
    let testRouterEndpoint = ObjectsMembershipsRouter.Endpoint.setMemberships(
      uuidMetadataId: pubnub.configuration.userId,
      customFields: nil,
      totalCount: false,
      changes: .init(
        set: [.init(
          metadataId: testMembership.space.id,
          status: testMembership.status,
          custom: testMembership.custom?.flatJSON)
        ],
        delete: []),
      filter: nil,
      sort: [],
      limit: 0,
      start: nil,
      end: nil
    )
    
    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsMembershipsRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      return .success(.init(
        data: multiValueJSON.data(using: .utf8)
      ))
    }
    
    // Validate Outputs
    pubnub.updateMemberships(
      spaces: [.init(
        spaceId: testMembership.space.id, status: testMembership.status, custom: testMembership.custom
      )]
    ) { result in
      switch result {
      case .success:
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Failed due to error \(error)")
      }
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testMembership_UpdateMembership_UserId() {
    let expectation = XCTestExpectation(description: "Fetch Membership API")
    
    let testRouterEndpoint = ObjectsMembershipsRouter.Endpoint.setMemberships(
      uuidMetadataId: testMembership.user.id,
      customFields: nil,
      totalCount: false,
      changes: .init(
        set: [.init(
          metadataId: testMembership.space.id,
          status: testMembership.status,
          custom: testMembership.custom?.flatJSON)
        ],
        delete: []),
      filter: nil,
      sort: [],
      limit: 0,
      start: nil,
      end: nil
    )
    
    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsMembershipsRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      return .success(.init(
        data: multiValueJSON.data(using: .utf8)
      ))
    }
    
    // Validate Outputs
    pubnub.updateMemberships(
      spaces: [.init(
        spaceId: testMembership.space.id, status: testMembership.status, custom: testMembership.custom
      )],
      on: testMembership.user.id
    ) { result in
      switch result {
      case .success:
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Failed due to error \(error)")
      }
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testMembership_UpdateMembership_SpaceId() {
    let expectation = XCTestExpectation(description: "Fetch Membership API")
    
    let testRouterEndpoint = ObjectsMembershipsRouter.Endpoint.setMembers(
      channelMetadataId: testMembership.space.id,
      customFields: nil,
      totalCount: false,
      changes: .init(
        set: [.init(
          metadataId: testMembership.user.id,
          status: testMembership.status,
          custom: testMembership.custom?.flatJSON)
        ],
        delete: []),
      filter: nil,
      sort: [],
      limit: 0,
      start: nil,
      end: nil
    )
    
    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsMembershipsRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      return .success(.init(
        data: multiValueJSON.data(using: .utf8)
      ))
    }
    
    // Validate Outputs
    pubnub.updateMemberships(
      users: [.init(
        userId: testMembership.user.id, status: testMembership.status, custom: testMembership.custom
      )],
      on: testMembership.space.id
    ) { result in
      switch result {
      case .success:
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Failed due to error \(error)")
      }
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testMembership_RemoveMembership_UserId_PubNubConfiguration() {
    let expectation = XCTestExpectation(description: "Fetch Membership API")
    
    let testRouterEndpoint = ObjectsMembershipsRouter.Endpoint.setMemberships(
      uuidMetadataId: pubnub.configuration.userId,
      customFields: nil,
      totalCount: false,
      changes: .init(
        set: [],
        delete: [.init(
          metadataId: testMembership.space.id,
          status: nil,
          custom: nil)]),
      filter: nil,
      sort: [],
      limit: 0,
      start: nil,
      end: nil
    )
    
    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsMembershipsRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      return .success(.init(
        data: multiValueJSON.data(using: .utf8)
      ))
    }
    
    // Validate Outputs
    pubnub.removeMemberships(
      spaceIds: [testMembership.space.id]
    ) { result in
      switch result {
      case .success:
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Failed due to error \(error)")
      }
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testMembership_RemoveMembership_UserId() {
    let expectation = XCTestExpectation(description: "Fetch Membership API")
    
    let testRouterEndpoint = ObjectsMembershipsRouter.Endpoint.setMemberships(
      uuidMetadataId: testMembership.user.id,
      customFields: nil,
      totalCount: false,
      changes: .init(
        set: [],
        delete: [.init(
          metadataId: testMembership.space.id,
          status: nil,
          custom: nil)]),
      filter: nil,
      sort: [],
      limit: 0,
      start: nil,
      end: nil
    )
    
    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsMembershipsRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      return .success(.init(
        data: multiValueJSON.data(using: .utf8)
      ))
    }
    
    // Validate Outputs
    pubnub.removeMemberships(
      spaceIds: [testMembership.space.id],
      from: testMembership.user.id
    ) { result in
      switch result {
      case .success:
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Failed due to error \(error)")
      }
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testMembership_RemoveMembership_SpaceId() {
    let expectation = XCTestExpectation(description: "Fetch Membership API")
    
    let testRouterEndpoint = ObjectsMembershipsRouter.Endpoint.setMembers(
      channelMetadataId: testMembership.space.id,
      customFields: nil,
      totalCount: false,
      changes: .init(
        set: [],
        delete: [.init(
          metadataId: testMembership.user.id,
          status: nil,
          custom: nil)]),
      filter: nil,
      sort: [],
      limit: 0,
      start: nil,
      end: nil
    )
    
    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsMembershipsRouter)?.endpoint)
    }
    
    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      return .success(.init(
        data: multiValueJSON.data(using: .utf8)
      ))
    }
    
    // Validate Outputs
    pubnub.removeMemberships(
      userIds: [testMembership.user.id],
      from: testMembership.space.id
    ) { result in
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
