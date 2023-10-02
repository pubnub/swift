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
  public override func setup() {
    startCucumberHookEventsListening()
    
    var cryptorKind: String = ""
    var cipherKey: String = ""
    var randomIV: Bool = true
    var otherCryptors: [String] = []
    
    Given("Crypto module with '(.*)' cryptor") { args, userInfo in
      cryptorKind = args?.first as? String ?? ""
    }
    Given("Legacy code with '(.*)' cipher key and '(.*)' vector") { args, userInfo in
      cipherKey = args?.first as? String ?? ""
      randomIV = args?.first ?? "" == "random"
    }
    Given("Crypto module with default '(.*)' and additional '(.*)'") { args, userInfo in
      cryptorKind = args?.first ?? ""
      otherCryptors = [args?.last ?? ""]
    }
    Match(["*"], "with '(.*)' cipher key") { args, userInfo in
      cipherKey = args?.first ?? ""
    }
    Match(["*"], "with '(.*)' vector") { args, userInfo in
      randomIV = args?.first ?? "" == "random"
    }
    When("I decrypt '(.*)' file") { args, userInfo in
      let fileName = args?.first ?? ""
      let localUrl = self.localUrl(for: fileName)
      let inputStream = InputStream(url: localUrl)!
      let outputUrl = self.generateTestOutputUrl()
      
      let cryptorModule = self.createCryptorModule(cryptorKind, key: cipherKey, withRandomIV: randomIV)
      let encryptedStreamData = EncryptedStreamResult(stream: inputStream, contentLength: localUrl.sizeOf)
      let decryptingRes = cryptorModule.decrypt(stream: encryptedStreamData, to: outputUrl)
      
      Then("I receive '(.*)'") { thenArgs, _ in
        switch thenArgs?.first ?? "" {
        case "unknown cryptor error":
          XCTAssertTrue(self.failureIfAny(from: decryptingRes)?.reason == .unknownCryptorError)
        case "decryption error":
          XCTAssertTrue(self.failureIfAny(from: decryptingRes)?.reason == .decryptionError)
        case "success":
          XCTAssertNotNil(try? decryptingRes.get())
        default:
          XCTFail("Unsupported outcome")
        }
      }
    }
    When("I encrypt '(.*)' file as 'binary'") { args, userInfo in
      let fileName = args?.first ?? ""
      let cryptorModule = self.createCryptorModule(cryptorKind, key: cipherKey, withRandomIV: randomIV)
      let localFileUrl = self.localUrl(for: fileName)
      let inputData = try! Data(contentsOf: localFileUrl)
      let encryptedDataRes = cryptorModule.encrypt(data: inputData)
      
      Then("Successfully decrypt an encrypted file with legacy code") { _, _ in
        let decryptedData = try! cryptorModule.decrypt(data: try! encryptedDataRes.get()).get()
        XCTAssertEqual(inputData, decryptedData)
      }
      Then("I receive 'encryption error'") { _, _ in
        guard case .failure(let failure) = encryptedDataRes else {
          XCTFail("Encryption error is expected"); return;
        }
        XCTAssertTrue(failure.reason == .encryptionError)
      }
    }
    When("I encrypt '(.*)' file as 'stream'") { args, userInfo in
      let fileName = args?.first ?? ""
      let cryptorModule = self.createCryptorModule(cryptorKind, key: cipherKey, withRandomIV: randomIV)
      let localFileUrl = self.localUrl(for: fileName)
      let inputStream = InputStream(url: localFileUrl)!
      let encryptRes = cryptorModule.encrypt(stream: inputStream, contentLength: localFileUrl.sizeOf)
      let outputURL = self.generateTestOutputUrl()

      Then("Successfully decrypt an encrypted file with legacy code") { _, _ in
        cryptorModule.decrypt(stream: try! encryptRes.get(), to: outputURL)
        
        let expectedData = try! Data(contentsOf: localFileUrl)
        let receivedData = try! Data(contentsOf: outputURL)
        XCTAssertEqual(expectedData, receivedData)
      }
      
      Then("I receive 'encryption error'") { _, _ in
        guard case .failure(let failure) = encryptRes else {
          XCTFail("Encryption error is expected"); return;
        }
        XCTAssertTrue(failure.reason == .encryptionError)
      }
    }
    
    When("I decrypt '(.*)' file as 'binary'") { args, _ in
      let fileName = args?.first ?? ""
      let cryptorModule = self.createCryptorModule(cryptorKind, additional: otherCryptors, key: cipherKey, withRandomIV: randomIV)
      let localFileUrl = self.localUrl(for: fileName)
      let localData = try! Data(contentsOf: localFileUrl)
      let decryptResult = cryptorModule.decrypt(data: localData)
            
      Then("Decrypted file content equal to the '(.*)' file content") { thenArgs, _ in
        let fileNameToCompare = thenArgs?.first ?? ""
        let fileNameUrlToCompare = self.localUrl(for: fileNameToCompare)
        let expectedData = try! Data(contentsOf: fileNameUrlToCompare)
        let receivedData = try! decryptResult.get()
        XCTAssertEqual(expectedData, receivedData)
      }
      
      Then("I receive 'decryption error'") { _, _ in
        guard case .failure(let failure) = decryptResult else {
          XCTFail("Decryption error is expected"); return;
        }
        XCTAssertTrue(failure.reason == .decryptionError)
      }
    }
    
    When("I decrypt '(.*)' file as 'stream'") { args, _ in
      let fileName = args?.first ?? ""
      let cryptorModule = self.createCryptorModule(cryptorKind, key: cipherKey, withRandomIV: randomIV)
      let localFileUrl = self.localUrl(for: fileName)
      let stream = InputStream(url: localFileUrl)!
      let outputUrl = self.generateTestOutputUrl()
      
      let decryptRes = cryptorModule.decrypt(
        stream: EncryptedStreamResult(stream: stream, contentLength: localFileUrl.sizeOf),
        to: outputUrl
      )
      
      Then("Decrypted file content equal to the '(.*)' file content") { thenArgs, _ in
        let expectedFileName = thenArgs?.first ?? ""
        let decodedData = try! Data(contentsOf: outputUrl)
        let expectedData = try! Data(contentsOf: self.localUrl(for: expectedFileName))
        XCTAssertEqual(decodedData, expectedData)
      }
      
      Then("I receive 'decryption error'") { _, _ in
        guard case .failure(let failure) = decryptRes else {
          XCTFail("Decryption error is expected"); return;
        }
        XCTAssertTrue(failure.reason == .decryptionError)
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
  
  func createCryptorModule(_ id: String, additional cryptors: [String] = [], key: String, withRandomIV: Bool) -> CryptorModule {
    let additionalCryptors = cryptors.map { id -> Cryptor in
      id == "acrh" ? AESCBCCryptor(key: key) : LegacyCryptor(key: key, withRandomIV: withRandomIV)
    }
    return CryptorModule(
      default: id == "acrh" ? AESCBCCryptor(key: key) : LegacyCryptor(key: key, withRandomIV: withRandomIV),
      cryptors: additionalCryptors
    )
  }
  
  func failureIfAny<Success, Error>(from result: Result<Success, Error>) -> Error? {
    guard case .failure(let failure) = result else { return nil }
    return failure
  }
  
  func generateTestOutputUrl() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  }
}
