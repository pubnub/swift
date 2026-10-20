//
//  CommonCryptoGCMStrategy.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import CommonCrypto
import Foundation

/// Fallback for OS versions that predate CryptoKit (e.g. iOS 12).
struct CommonCryptoGCMStrategy: AESGCMStrategy {
  private let blockSize = 16
  private let blocksPerChunk = 4096

  func open(key: Data, nonce: Data, ciphertext: Data, tag: Data) -> Data? {
    let cipherBytes = [UInt8](ciphertext)

    guard
      let hashKey = encryptBlocks(key: key, blocks: [UInt8](repeating: 0, count: blockSize)),
      let tagMask = encryptBlocks(key: key, blocks: counterBlock(nonce: nonce, counter: 1))
    else {
      return nil
    }

    var ghash = GHash(hashKey: hashKey)
    ghash.update(cipherBytes)
    let expectedTag = zip(ghash.finish(cipherBitCount: UInt64(cipherBytes.count) * 8), tagMask).map { $0 ^ $1 }

    guard constantTimeEquals(expectedTag, [UInt8](tag)) else {
      return nil
    }
    return applyKeystream(key: key, nonce: nonce, input: cipherBytes).map { Data($0) }
  }

  /// Counter mode starting at `inc32(J0)`, which is counter value 2 for a 96-bit nonce
  private func applyKeystream(key: Data, nonce: Data, input: [UInt8]) -> [UInt8]? {
    var output = [UInt8]()
    output.reserveCapacity(input.count)

    var counter: UInt32 = 2
    var offset = 0

    while offset < input.count {
      let chunkLength = min(blocksPerChunk * blockSize, input.count - offset)
      let blockCount = (chunkLength + blockSize - 1) / blockSize

      var counterBlocks = [UInt8]()
      counterBlocks.reserveCapacity(blockCount * blockSize)

      for _ in 0..<blockCount {
        counterBlocks += counterBlock(nonce: nonce, counter: counter)
        counter = counter &+ 1
      }
      guard let keystream = encryptBlocks(key: key, blocks: counterBlocks) else {
        return nil
      }
      for index in 0..<chunkLength {
        output.append(input[offset + index] ^ keystream[index])
      }
      offset += chunkLength
    }
    return output
  }

  private func counterBlock(nonce: Data, counter: UInt32) -> [UInt8] {
    [UInt8](nonce) + [
      UInt8(truncatingIfNeeded: counter >> 24),
      UInt8(truncatingIfNeeded: counter >> 16),
      UInt8(truncatingIfNeeded: counter >> 8),
      UInt8(truncatingIfNeeded: counter)
    ]
  }

  /// Encrypts whole blocks with raw AES (ECB, no padding). Each block is processed independently.
  private func encryptBlocks(key: Data, blocks: [UInt8]) -> [UInt8]? {
    let outputCapacity = blocks.count
    var output = [UInt8](repeating: 0, count: outputCapacity)
    var bytesMoved = 0

    let status = key.withUnsafeBytes { keyBytes in
      CCCrypt(
        CCOperation(kCCEncrypt),
        CCAlgorithm(kCCAlgorithmAES),
        CCOptions(kCCOptionECBMode),
        keyBytes.baseAddress,
        key.count,
        nil,
        blocks,
        blocks.count,
        &output,
        outputCapacity,
        &bytesMoved
      )
    }
    guard status == kCCSuccess, bytesMoved == outputCapacity else {
      return nil
    }
    return output
  }

  private func constantTimeEquals(_ lhs: [UInt8], _ rhs: [UInt8]) -> Bool {
    guard lhs.count == rhs.count else {
      return false
    }
    var difference: UInt8 = 0
    for index in 0..<lhs.count {
      difference |= lhs[index] ^ rhs[index]
    }
    return difference == 0
  }
}

/// GHASH over GF(2^128) with an empty AAD. Blocks are handled as two big-endian 64-bit halves.
private struct GHash {
  private typealias Block = (high: UInt64, low: UInt64)

  private static let blockSize = 16
  private static let reductionConstant: UInt64 = 0xE100_0000_0000_0000

  private let hashKey: Block
  private var state: Block = (0, 0)

  init(hashKey: [UInt8]) {
    self.hashKey = Self.block(from: hashKey, at: 0)
  }

  /// Absorbs the ciphertext, zero-padding the final partial block
  mutating func update(_ bytes: [UInt8]) {
    var offset = 0

    while offset < bytes.count {
      var block = Array(bytes[offset..<min(offset + Self.blockSize, bytes.count)])
      block += [UInt8](repeating: 0, count: Self.blockSize - block.count)
      absorb(Self.block(from: block, at: 0))
      offset += Self.blockSize
    }
  }

  /// Absorbs the length block (0 AAD bits, `cipherBitCount` ciphertext bits) and returns the digest
  mutating func finish(cipherBitCount: UInt64) -> [UInt8] {
    absorb((0, cipherBitCount))
    return Self.bytes(from: state)
  }

  private mutating func absorb(_ block: Block) {
    state = multiply((state.high ^ block.high, state.low ^ block.low), by: hashKey)
  }

  /// Bit-by-bit multiplication. Uses masks instead of branches, so timing does not depend on the data.
  private func multiply(_ x: Block, by y: Block) -> Block {
    var product: Block = (0, 0)
    var value = y

    for bitIndex in 0..<128 {
      let bit = bitIndex < 64 ? (x.high >> UInt64(63 - bitIndex)) & 1 : (x.low >> UInt64(127 - bitIndex)) & 1
      let addMask = 0 &- bit
      product.high ^= value.high & addMask
      product.low ^= value.low & addMask

      let reduceMask = 0 &- (value.low & 1)
      value.low = (value.low >> 1) | (value.high << 63)
      value.high = (value.high >> 1) ^ (Self.reductionConstant & reduceMask)
    }
    return product
  }

  private static func block(from bytes: [UInt8], at offset: Int) -> Block {
    var high: UInt64 = 0
    var low: UInt64 = 0

    for index in 0..<8 {
      high = (high << 8) | UInt64(bytes[offset + index])
      low = (low << 8) | UInt64(bytes[offset + 8 + index])
    }
    return (high, low)
  }

  private static func bytes(from block: Block) -> [UInt8] {
    var result = [UInt8]()
    result.reserveCapacity(blockSize)

    for half in [block.high, block.low] {
      for index in 0..<8 {
        result.append(UInt8(truncatingIfNeeded: half >> UInt64(56 - 8 * index)))
      }
    }
    return result
  }
}
