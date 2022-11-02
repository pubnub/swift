//
//  PubNubObjectsTestHelpers.swift
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

import Foundation
import PubNub

extension PubNubContractTestCase {
    /// Use entity name to compose path on JSON with it's representation.
    ///
    /// - Parameter name: Entity name which is the same as name of file in which it is stored.
    /// - Returns: Full path to the file with entity information.
    private func entityDataPathByName(_ name: String) -> String {
        let filePath = "Features/data/\(name).json"
        let bundle = Bundle(for: PubNubContractTestCase.self)
        return (bundle.bundlePath as NSString).appendingPathComponent(filePath)
    }
    
    /// Load entity entity information from file.
    ///
    /// - Parameter filePath: Full path to the file with entity information.
    /// - returns: An updated `PubNubSpace` with the patched values, or the same object if no patch was applied.
    private func loadDataFile(_ filePath: String) -> Data? {
        guard let loadedData = try? NSData(contentsOfFile: filePath) as Data else {
            XCTAssert(false, "Unable to load data from: \(filePath)")
            return nil
        }
        
        return loadedData
    }
    
    /// Retrieve `UUID metadata` object information using owner name.
    ///
    /// - Parameter name: Entity name which is the same as name of file in which it is stored.
    /// - Returns: Parsed `PubNubUUIDMetadata` object or `nil` in case of parse / load error.
    func uuidMetadata(with name: String) -> PubNubUUIDMetadata? {
        guard let uuidData = loadDataFile(entityDataPathByName(name)) else { return nil }
        guard let uuidMetadata = try? Constant.jsonDecoder.decode(PubNubUUIDMetadataBase.self, from: uuidData) else {
            XCTAssert(false, "Unable to load / parse data for '\(name)' persona.")
            return nil
        }
        
        return uuidMetadata
    }
    
    /// Retrieve `channel metadata` object information using owner name.
    ///
    /// - Parameter name: Entity name which is the same as name of file in which it is stored.
    /// - Returns: Parsed `PubNubChannelMetadata` object or `nil` in case of parse / load error.
    func channelMetadata(with name: String) -> PubNubChannelMetadata? {
        guard let channelData = loadDataFile(entityDataPathByName(name)) else { return nil }
        guard let channelMetadata = try? Constant.jsonDecoder.decode(PubNubChannelMetadataBase.self, from: channelData) else {
            XCTAssert(false, "Unable to load / parse data for '\(name)' channel.")
            return nil
        }
        
        return channelMetadata
    }
}
