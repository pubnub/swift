//
//  PAMTokenStoreTests.swift
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

@testable import PubNub
import XCTest

// swiftlint:disable line_length

class PAMTokenStoreTests: XCTestCase {
  let config = PubNubConfiguration(publishKey: "", subscribeKey: "")
  static let version2Token = "p0F2AkF0Gl15f0JDdHRsGQWgQ3Jlc6REY2hhbqBDZ3JwoEN1c3KhbHVzZXItcmFpLTM3NxgfQ3NwY6BDcGF0pERjaGFuoENncnCgQ3VzcqBDc3BjoERtZXRhoENzaWdYIIOAScVS/Ws+OEq9W8NbZ7f+CPX9zUYGU0c1NPoxTzkE"
  static let userGroupToken = "p0F2AkF0Gl15f0JDdHRsGQWgQ3Jlc6REY2hhbqBDZ3JwoEN1c3KhaHRlc3RVc2VyGB9Dc3BjoWl0ZXN0U3BhY2UQQ3BhdKREY2hhbqBDZ3JwoEN1c3KgQ3NwY6BEbWV0YaBDc2lnWCCDgEnFUv1rPjhKvVvDW2e3/gj1/c1GBlNHNTT6MU85BA=="

  static let testToken = PAMToken(version: 2, timestamp: 1_568_243_522, ttl: 1440,
                                  resources: .init(channels: [:], groups: [:], users: ["testUser": .all], spaces: ["testSpace": .create]),
                                  patterns: .init(channels: [:], groups: [:], users: [:], spaces: [:]),
                                  meta: [:], signature: "838049C552FD6B3E384ABD5BC35B67B7FE08F5FDCD460653473534FA314F3904", rawValue: userGroupToken)

  var testUsers = ["testUser": testToken]
  var testSpaces = ["testSpace": testToken]
}

// MARK: Scanner

extension PAMTokenStoreTests {
  func testGetToken() {
    var pubnub = PubNub(configuration: config)
    pubnub.tokenStore = PAMTokenManagementSystem(users: testUsers, spaces: testSpaces)

    // Test for found
    let token = pubnub.getToken(for: "testUser")
    XCTAssertEqual(token, PAMTokenStoreTests.testToken)
  }

  func testGetToken_NotFound() {
    var pubnub = PubNub(configuration: config)
    pubnub.tokenStore = PAMTokenManagementSystem(users: testUsers, spaces: testSpaces)

    let token = pubnub.getToken(for: "testNone")
    XCTAssertNil(token)
  }

  func testGetTokenByResource() {
    var pubnub = PubNub(configuration: config)
    pubnub.tokenStore = PAMTokenManagementSystem(users: testUsers, spaces: testSpaces)

    let token = // Test for found
      pubnub.getToken(for: "testSpace", with: .space)
    XCTAssertEqual(token, PAMTokenStoreTests.testToken)
  }

  func testGetTokenByResource_NotFound() {
    var pubnub = PubNub(configuration: config)
    pubnub.tokenStore = PAMTokenManagementSystem(users: testUsers, spaces: testSpaces)

    // Test for not found
    let token = pubnub.getToken(for: "testSpace", with: .user)
    XCTAssertNil(token)
  }

  func testGetTokens() {
    var pubnub = PubNub(configuration: config)
    pubnub.tokenStore = PAMTokenManagementSystem(users: testUsers, spaces: testSpaces)

    let tokens = pubnub.getTokens(by: .user)
    XCTAssertEqual(tokens.count, 1)
  }

  func testGetAllTokens() {
    var pubnub = PubNub(configuration: config)
    pubnub.tokenStore = PAMTokenManagementSystem(users: testUsers, spaces: testSpaces)

    let tokens = pubnub.getAllTokens()
    XCTAssertEqual(tokens.count, 2)
  }

  func testSetToken() {
    var tms = PAMTokenManagementSystem()

    tms.set(token: PAMTokenStoreTests.userGroupToken)

    let token = tms.getToken(for: "testUser")
    XCTAssertEqual(token, PAMTokenStoreTests.testToken)
  }

  func testSetTokens() {
    var tms = PAMTokenManagementSystem()

    tms.set(tokens: [PAMTokenStoreTests.userGroupToken, PAMTokenStoreTests.version2Token])

    let token = tms.getToken(for: "testUser")
    XCTAssertEqual(token, PAMTokenStoreTests.testToken)

    let tokens = tms.getAllTokens()
    XCTAssertEqual(tokens[.user]?.count, 2)
    XCTAssertEqual(tokens[.space]?.count, 1)
  }

  // swiftlint:enable line_length
}
