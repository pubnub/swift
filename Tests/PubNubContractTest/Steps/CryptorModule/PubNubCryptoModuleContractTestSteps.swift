//
//  PubNubCryptoModuleContractTestSteps.swift
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

import Cucumberish
import Foundation
import PubNub
import XCTest
import CommonCrypto

public class PubNubCryptoModuleContractTestSteps: PubNubContractTestCase {
  var cryptorKind: String!
  var cipherKey: String!
  var randomIV: Bool = true
  var otherCryptors: [String] = []
  var cryptorModule: CryptorModule!
  
  var encryptDataRes: Result<Data, PubNubError>!
  var decryptDataRes: Result<Data, PubNubError>!
  var encryptStreamRes: Result<EncryptedStreamResult, PubNubError>!
  var decryptStreamRes: Result<InputStream, PubNubError>!
  
  var givenFileUrl: URL!
  var outputPath: URL!
  var encryptAsBinary: Bool!
  var decryptAsBinary: Bool!
  
  override public func handleBeforeHook() {
    cryptorKind = ""
    cipherKey = ""
    randomIV = true
    otherCryptors = []
    cryptorModule = nil
    
    encryptDataRes = nil
    decryptDataRes = nil
    encryptStreamRes = nil
    decryptStreamRes = nil
    
    givenFileUrl = nil
    outputPath = nil
    encryptAsBinary = nil
    decryptAsBinary = nil
    
    super.handleBeforeHook()
  }
  
  public override func setup() {
    startCucumberHookEventsListening()
        
    Given("Crypto module with '(.*)' cryptor") { args, userInfo in
      self.cryptorKind = args?.first as? String ?? ""
    }
    Given("Legacy code with '(.*)' cipher key and '(.*)' vector") { args, userInfo in
      self.cipherKey = args?.first as? String ?? ""
      self.randomIV = args?.first ?? "" == "random"
    }
    Given("Crypto module with default '(.*)' and additional '(.*)'") { args, userInfo in
      self.cryptorKind = args?.first ?? ""
      self.otherCryptors = [args?.last ?? ""]
    }
    Match(["*"], "with '(.*)' cipher key") { args, userInfo in
      self.cipherKey = args?.first ?? ""
    }
    Match(["*"], "with '(.*)' vector") { args, userInfo in
      self.randomIV = args?.first ?? "" == "random"
    }
    When("I decrypt '(.*)' file") { args, userInfo in
      self.outputPath = self.generateTestOutputUrl()
      self.givenFileUrl = self.localUrl(for: args?.first ?? "")
      self.cryptorModule = self.createCryptorModule()
      self.decryptAsBinary = false
      
      let encryptedStreamResult = EncryptedStreamResult(
        stream: InputStream(url: self.givenFileUrl)!,
        contentLength: self.givenFileUrl.sizeOf
      )
      self.decryptStreamRes = self.cryptorModule.decrypt(
        streamData: encryptedStreamResult,
        to: self.outputPath
      )
    }
    
    When("I decrypt '(.*)' file as '(.*)'") { args, _ in
      self.givenFileUrl = self.localUrl(for: args?.first ?? "")
      self.outputPath = self.generateTestOutputUrl()
      self.cryptorModule = self.createCryptorModule()
      self.decryptAsBinary = args?.last == "binary"

      if self.decryptAsBinary {
        let dataToDecrypt = try! Data(contentsOf: self.givenFileUrl)
        self.decryptDataRes = self.cryptorModule.decrypt(data: dataToDecrypt)
      } else {
        let encryptedStreamResult = EncryptedStreamResult(
          stream: InputStream(url: self.givenFileUrl)!,
          contentLength: self.givenFileUrl.sizeOf
        )
        self.decryptStreamRes = self.cryptorModule.decrypt(
          streamData: encryptedStreamResult,
          to: self.outputPath
        )
      }
    }
    
    When("I encrypt '(.*)' file as '(.*)'") { args, userInfo in
      self.givenFileUrl = self.localUrl(for: args?.first ?? "")
      self.encryptAsBinary = args?.last == "binary"
      self.outputPath = self.generateTestOutputUrl()
      self.cryptorModule = self.createCryptorModule()
      
      if self.encryptAsBinary {
        let dataToEncrypt = try! Data(contentsOf: self.givenFileUrl)
        self.encryptDataRes = self.cryptorModule.encrypt(data: dataToEncrypt)
      } else {
        let streamToEncrypt = InputStream(url: self.givenFileUrl)!
        let contentLength = self.givenFileUrl.sizeOf
        self.encryptStreamRes = self.cryptorModule.encrypt(stream: streamToEncrypt, contentLength: contentLength)
      }
    }
    
    Then("I receive '(.*)'") { thenArgs, _ in
      switch thenArgs?.first ?? "" {
      case "decryption error":
        if self.decryptAsBinary {
          XCTAssertTrue(self.failureIfAny(from: self.decryptDataRes)?.reason == .decryptionFailure)
        } else {
          XCTAssertTrue(self.failureIfAny(from: self.decryptStreamRes)?.reason == .decryptionFailure)
        }
      case "encryption error":
        if self.encryptAsBinary {
          XCTAssertTrue(self.failureIfAny(from: self.encryptDataRes)?.reason == .encryptionFailure)
        } else {
          XCTAssertTrue(self.failureIfAny(from: self.encryptStreamRes)?.reason == .encryptionFailure)
        }
      case "unknown cryptor error":
        XCTAssertTrue(self.failureIfAny(from: self.decryptStreamRes)?.reason == .unknownCryptorFailure)
      case "success":
        XCTAssertNotNil(try? self.decryptStreamRes?.get())
      default:
        XCTFail("Unsupported outcome")
      }
    }
    
    Then("Successfully decrypt an encrypted file with legacy code") { _, _ in
      let expectedData = try! Data(contentsOf: self.givenFileUrl)
      
      if self.encryptAsBinary {
        let encryptedData = try! self.encryptDataRes.get()
        let decryptedData = try! self.cryptorModule.decrypt(data: encryptedData).get()
        XCTAssertEqual(expectedData, decryptedData)
      } else {
        self.cryptorModule.decrypt(streamData: try! self.encryptStreamRes.get(), to: self.outputPath)
        let decryptedData = try! Data(contentsOf: self.outputPath)
        XCTAssertEqual(expectedData, decryptedData)
      }
    }
    
    Then("Decrypted file content equal to the '(.*)' file content") { thenArgs, _ in
      let fileNameUrlToCompare = self.localUrl(for: thenArgs?.first ?? "")
      let expectedData = try! Data(contentsOf: fileNameUrlToCompare)

      if self.decryptAsBinary {
        XCTAssertEqual(expectedData, try! self.decryptDataRes.get())
      } else {
        XCTAssertEqual(expectedData, try! Data(contentsOf: self.outputPath))
      }
    }
  }
}

fileprivate extension PubNubCryptoModuleContractTestSteps {
  func localUrl(for fileName: String) -> URL {
    let bundlePath = Bundle(for: Self.self).bundlePath
    let finalPath = bundlePath.appending("/Features/encryption/assets/\(fileName)")

    return URL(fileURLWithPath: finalPath)
  }
  
  func createCryptorModule() -> CryptorModule {
    CryptorModule(
      default: self.createCryptor(for: self.cryptorKind),
      cryptors: self.otherCryptors.map { self.createCryptor(for: $0) }
    )
  }
  
  func createCryptor(for stringIdentifier: String) -> Cryptor {
    if stringIdentifier == "acrh" {
      return AESCBCCryptor(key: self.cipherKey)
    } else {
      return LegacyCryptor(key: self.cipherKey, withRandomIV: self.randomIV)
    }
  }
  
  func failureIfAny<Success, Error>(from result: Result<Success, Error>?) -> Error? {
    guard case .failure(let failure) = result else {
      return nil
    }
    return failure
  }
  
  func generateTestOutputUrl() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  }
}
