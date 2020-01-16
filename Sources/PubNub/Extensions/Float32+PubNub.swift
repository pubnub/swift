//
//  Float32+PubNub.swift
//  PubNub
//
//  Created by Craig Lane on 1/8/20.
//  Copyright © 2020 PubNub. All rights reserved.
//

import Foundation

extension Float32 {
  static func float16(from value: UInt16) -> Float32 {
    if (value & 0x7FFF) > 0x7C00 {
      return Float32.nan
    }
    if value == 0x7C00 {
      return Float32.infinity
    }
    if value == 0xFC00 {
      return -Float32.infinity
    }
    var nonSignBit = UInt32(value & 0x7FFF)
    var signBit = UInt32(value & 0x8000)
    let exponent = UInt32(value & 0x7C00)
    // Align mantissa on MSB
    nonSignBit <<= 13
    // Shift sign bit into position
    signBit <<= 16
    // Adjust bias
    nonSignBit += 0x3800_0000
    // Denormals-as-zero
    nonSignBit = (exponent == 0 ? 0 : nonSignBit)
    // Re-insert sign bit
    nonSignBit |= signBit
    return Float32(bitPattern: nonSignBit)
  }
}
