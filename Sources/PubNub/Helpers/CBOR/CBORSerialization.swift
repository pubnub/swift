//
//  CBORSerialization.swift
//  PubNub
//
//  Created by Craig Lane on 1/8/20.
//  Copyright © 2020 PubNub. All rights reserved.
//

import Foundation

enum CBORError: Error {
  case malformedCBOR
  case malformedString
  case missingKey
  case missingValue
  case missingBreak
  case missingTaggedValue
}

internal class CBORSerialization {
  open class func cborObject(from data: Data) throws -> Any {
    return try data.withUnsafeBytes { pointer in
      let reader = CBORReader(source: pointer)

      // Get top level object
      if let (dictionary, _) = try reader.parseDictionary(from: 0) {
        return dictionary
      } else if let (array, _) = try reader.parseArray(from: 0) {
        return array
      } else if let (singleValue, _) = try reader.parseValue(from: 0) {
        return singleValue
      } else {
        throw CBORError.malformedCBOR
      }
    }
  }
}

internal struct CBORReader {
  typealias Index = UnsafeRawBufferPointer.Index

  private let source: UnsafeRawBufferPointer

  internal init(source: UnsafeRawBufferPointer) {
    self.source = source
  }
}

extension CBORReader {
  internal func parseDictionary(from index: Index) throws -> ([String: Any], Index)? {
    guard let (value, endIndex) = try parseValue(from: index) else {
      return nil
    }

    guard let dictionary = value as? [String: Any] else {
      return nil
    }

    return (dictionary, endIndex)
  }

  internal func parseArray(from index: Index) throws -> ([Any], Index)? {
    guard let (value, endIndex) = try parseValue(from: index) else {
      return nil
    }

    guard let array = value as? [Any] else {
      return nil
    }

    return (array, endIndex)
  }

  internal func parseArray(from index: Index, for count: Int) throws -> ([Any], Index)? {
    var values = [Any]()
    var nextIndex = index

    for _ in 0 ..< count {
      // Determine the value
      guard let (value, endIndex) = try parseValue(from: nextIndex) else {
        throw CBORError.missingValue
      }

      values.append(value)
      nextIndex = endIndex
    }

    return (values, nextIndex)
  }

  internal func parsePairs(from index: Index, for pairCount: Int) throws -> ([String: Any], Index)? {
    var pairs = [String: Any]()
    var nextPairIndex = index

    for _ in 0 ..< pairCount {
      // Next value should be a Key
      guard let (anyKey, valueIndex) = try parseValue(from: nextPairIndex), let key = anyKey as? String else {
        throw CBORError.missingValue
      }

      // Followed by its value
      guard let (value, nextIndex) = try parseValue(from: valueIndex) else {
        throw CBORError.missingValue
      }

      nextPairIndex = nextIndex
      pairs[key] = value
    }

    return (pairs, nextPairIndex)
  }

  // swiftlint:disable:next cyclomatic_complexity function_body_length
  internal func parseValue(from index: Index) throws -> (Any, Index)? {
    // Pull out head value
    let value = source[index]
    // Get the next index
    let nextIndex = source.index(after: index)

    // Determine the value type
    switch value {
      // MARK: Positive Int

    // The 5-bit additional information is either the integer itself (for additional information values 0 through 23)
    // or the length of additional data.
    case 0x00 ... 0x17: // 0...23 Used directly as the data value.
      return (Int(value), nextIndex)
    case 0x18: // Next byte is uint8_t in data value section
      let (value, endIndex): (UInt8, Index) = try source.byteValue(from: nextIndex)
      return (value, endIndex)
    case 0x19: // Next 2 bytes uint16_t in data value section
      let (value, endIndex): (UInt16, Index) = try source.byteValue(from: nextIndex)
      return (value, endIndex)
    case 0x1A: // Next 4 bytes is uint32_t in data value section
      let (value, endIndex): (UInt32, Index) = try source.byteValue(from: nextIndex)
      return (value, endIndex)
    case 0x1B: // Next 8 bytes is uint64_t in data value section
      let (value, endIndex): (UInt64, Index) = try source.byteValue(from: nextIndex)
      return (value, endIndex)

      // MARK: Negative Int

    // The encoding follows the rules for unsigned integers (major type 0);
    // except that the value is then -1 minus the encoded unsigned integer.
    case 0x20 ... 0x37: // 0...23 Used directly as the data value.
      return (Int(value) * -1 - 1, nextIndex)
    case 0x38: // Next byte is uint8_t in data value section
      let (element, endIndex) = try source.byteValue(from: nextIndex) as (UInt8, Index)
      return (Int(element) * -1 - 1, endIndex)
    case 0x39: // Next 2 bytes uint16_t in data value section
      let (element, endIndex) = try source.byteValue(from: nextIndex) as (UInt16, Index)
      return (Int(element) * -1 - 1, endIndex)
    case 0x3A: // Next 4 bytes is uint32_t in data value section
      let (element, endIndex) = try source.byteValue(from: nextIndex) as (UInt32, Index)
      return (Int(element) * -1 - 1, endIndex)
    case 0x3B: // Next 8 bytes is uint64_t in data value section
      let (element, endIndex) = try source.byteValue(from: nextIndex) as (UInt64, Index)
      return (Int(element) * -1 - 1, endIndex)

      // MARK: Byte String

    // The string's length in bytes is represented following the rules for positive integers (major type 0).
    case 0x40 ... 0x57: // Used directly as the data length specifier.
      // Get the value of the string
      let endIndex = nextIndex.advanced(by: Int(value - 0x40))
      let strBytes = source[nextIndex ..< endIndex]

      guard let string = String(data: Data(strBytes), encoding: .utf8) else {
        return (Data(strBytes).hexEncodedString, endIndex)
      }
      return (string, endIndex)
    case 0x58: // Next byte is uint8_t for payload length
      // Turn the sequence into an Int
      let (strLength, strIndex) = try source.byteValue(from: nextIndex) as (UInt8, Index)

      // Get the value of the string
      let endIndex = strIndex.advanced(by: Int(strLength))
      let strBytes = source[strIndex ..< endIndex]

      guard let string = String(data: Data(strBytes), encoding: .utf8) else {
        return (Data(strBytes).hexEncodedString, endIndex)
      }
      return (string, endIndex)
    case 0x59: // Next 2 bytes uint16_t for payload length
      // Turn the sequence into an Int
      let (strLength, strIndex) = try source.byteValue(from: nextIndex) as (UInt16, Index)

      // Get the value of the string
      let endIndex = strIndex.advanced(by: Int(strLength))
      let strBytes = source[strIndex ..< endIndex]

      guard let string = String(data: Data(strBytes), encoding: .utf8) else {
        return (Data(strBytes).hexEncodedString, endIndex)
      }
      return (string, endIndex)
    case 0x5A: // Next 4 bytes is uint32_t for payload length
      // Turn the sequence into an Int
      let (strLength, strIndex) = try source.byteValue(from: nextIndex) as (UInt32, Index)

      // Get the value of the string
      let endIndex = strIndex.advanced(by: Int(strLength))
      let strBytes = source[strIndex ..< endIndex]

      guard let string = String(data: Data(strBytes), encoding: .utf8) else {
        return (Data(strBytes).hexEncodedString, endIndex)
      }
      return (string, endIndex)
    case 0x5B: // Next 8 bytes is uint64_t for payload length
      // Turn the sequence into an Int
      let (strLength, strIndex) = try source.byteValue(from: nextIndex) as (UInt64, Index)

      // Get the value of the string
      let endIndex = strIndex.advanced(by: Int(strLength))
      let strBytes = source[strIndex ..< endIndex]

      guard let string = String(data: Data(strBytes), encoding: .utf8) else {
        return (Data(strBytes).hexEncodedString, endIndex)
      }
      return (string, endIndex)
    case 0x5F: // Start of Indefinite String
      // Concatenation of definite-length strings, till next corresponding "Break" Code.
      guard let endIndex = source.nextBreakIndex(from: index) else {
        throw CBORError.missingBreak
      }
      let strBytes = source[index ..< endIndex]

      guard let string = String(data: Data(strBytes), encoding: .utf8) else {
        return (Data(strBytes).hexEncodedString, endIndex)
      }
      return (string, endIndex)

      // MARK: UTF-8 String

    // A text string, specifically a string of Unicode characters that is encoded as UTF-8 [RFC3629].
    case 0x60 ... 0x77:
      // Get the value of the string
      let endIndex = nextIndex.advanced(by: Int(value - 0x60))
      let strBytes = source[nextIndex ..< endIndex]

      guard let string = String(data: Data(strBytes), encoding: .utf8) else {
        throw CBORError.malformedString
      }
      return (string, endIndex)
    case 0x78: // Next byte is uint8_t for payload length
      // Turn the sequence into an Int
      let (strLength, strIndex) = try source.byteValue(from: nextIndex) as (UInt8, Index)

      // Get the value of the string
      let endIndex = strIndex.advanced(by: Int(strLength))

      guard let string = String(data: Data(source[strIndex ..< endIndex]), encoding: .utf8) else {
        throw CBORError.malformedString
      }
      return (string, endIndex)
    case 0x79: // Next 2 bytes uint16_t for payload length
      // Turn the sequence into an Int
      let (strLength, strIndex) = try source.byteValue(from: nextIndex) as (UInt16, Index)

      // Get the value of the string
      let endIndex = strIndex.advanced(by: Int(strLength))

      guard let string = String(data: Data(source[index ..< endIndex]), encoding: .utf8) else {
        throw CBORError.malformedString
      }
      return (string, endIndex)
    case 0x7A: // Next 4 bytes is uint32_t for payload length
      // Turn the sequence into an Int
      let (strLength, strIndex) = try source.byteValue(from: nextIndex) as (UInt32, Index)

      // Get the value of the string
      let endIndex = strIndex.advanced(by: Int(strLength))

      guard let string = String(data: Data(source[index ..< endIndex]), encoding: .utf8) else {
        throw CBORError.malformedString
      }
      return (string, endIndex)
    case 0x7B: // Next 8 bytes is uint64_t for payload length
      // Turn the sequence into an Int
      let (strLength, strIndex) = try source.byteValue(from: nextIndex) as (UInt64, Index)

      // Get the value of the string
      let endIndex = strIndex.advanced(by: Int(strLength))

      guard let string = String(data: Data(source[index ..< endIndex]), encoding: .utf8) else {
        throw CBORError.malformedString
      }
      return (string, endIndex)
    case 0x7F:
      guard let endIndex = source.nextBreakIndex(from: index) else {
        throw CBORError.missingBreak
      }

      guard let string = String(data: Data(source[index ..< endIndex]), encoding: .utf8) else {
        throw CBORError.malformedString
      }
      return (string, endIndex)

      // MARK: Array

    case 0x80 ... 0x97:
      if let (value, endArray) = try parseArray(from: nextIndex, for: Int(value - 0x80)) {
        return (value, endArray)
      }
      return nil
    case 0x98: // Next byte is uint8_t for payload length
      // Get array length
      let (arrayLength, endIndex) = try source.byteValue(from: nextIndex) as (UInt8, Index)
      if let (value, endArray) = try parseArray(from: endIndex, for: Int(arrayLength)) {
        return (value, endArray)
      }
      return nil
    case 0x99: // Next 2 bytes uint16_t for payload length
      // Get array length
      let (arrayLength, endIndex) = try source.byteValue(from: nextIndex) as (UInt16, Index)
      if let (value, endArray) = try parseArray(from: endIndex, for: Int(arrayLength)) {
        return (value, endArray)
      }
      return nil
    case 0x9A: // Next 4 bytes is uint32_t for payload length
      // Get array length
      let (arrayLength, endIndex) = try source.byteValue(from: nextIndex) as (UInt32, Index)
      if let (value, endArray) = try parseArray(from: endIndex, for: Int(arrayLength)) {
        return (value, endArray)
      }
      return nil
    case 0x9B: // Next 8 bytes is uint64_t for payload length
      // Get array length
      let (arrayLength, endIndex) = try source.byteValue(from: nextIndex) as (UInt64, Index)
      if let (value, endArray) = try parseArray(from: endIndex, for: Int(arrayLength)) {
        return (value, endArray)
      }
      return nil
    case 0x9F:
      // Implement array until break
      return ([], nextIndex)

      // MARK: Map

    case 0xA0 ... 0xB7:
      // Parse Pairs
      if let (value, endArray) = try parsePairs(from: nextIndex, for: Int(value - 0xA0)) {
        return (value, endArray)
      }
      return nil
    case 0xB8: // Next byte is uint8_t for payload length
      // Get Pair Count
      let (pairCount, endIndex) = try source.byteValue(from: nextIndex) as (UInt8, Index)
      // Parse Pairs
      if let (value, endArray) = try parsePairs(from: endIndex, for: Int(pairCount)) {
        return (value, endArray)
      }
      return nil
    case 0xB9: // Next 2 bytes uint16_t for payload length
      // Get Pair Count
      let (pairCount, endIndex) = try source.byteValue(from: nextIndex) as (UInt16, Index)
      // Parse Pairs
      if let (value, endArray) = try parsePairs(from: endIndex, for: Int(pairCount)) {
        return (value, endArray)
      }
      return nil
    case 0xBA: // Next 4 bytes is uint32_t for payload length
      // Get Pair Count
      let (pairCount, endIndex) = try source.byteValue(from: nextIndex) as (UInt32, Index)
      // Parse Pairs
      if let (value, endArray) = try parsePairs(from: endIndex, for: Int(pairCount)) {
        return (value, endArray)
      }
      return nil
    case 0xBB: // Next 8 bytes is uint64_t for payload length
      // Get Pair Count
      let (pairCount, endIndex) = try source.byteValue(from: nextIndex) as (UInt64, Index)
      // Parse Pairs
      if let (value, endArray) = try parsePairs(from: endIndex, for: Int(pairCount)) {
        return (value, endArray)
      }
      return nil
    case 0xBF:
      // Implement map until break
      return ([:], nextIndex)

      // MARK: Semantic Tag

    // Ignoring the tag for now; we will still parse the next value that the tag is meant to denote
    case 0xC0 ... 0xD7: // 0...23 Used directly as the data value.
      return try parseValue(from: nextIndex)
    case 0xD8: // Next byte is uint8_t in data value section
      let (_, valueIndex) = try source.byteValue(from: nextIndex) as (UInt8, Index)
      return try parseValue(from: valueIndex)
    case 0xD9: // Next 2 bytes uint16_t in data value section
      let (_, valueIndex) = try source.byteValue(from: nextIndex) as (UInt16, Index)
      return try parseValue(from: valueIndex)
    case 0xDA: // Next 4 bytes is uint32_t in data value section
      let (_, valueIndex) = try source.byteValue(from: nextIndex) as (UInt32, Index)
      return try parseValue(from: valueIndex)
    case 0xDB: // Next 8 bytes is uint64_t in data value section
      let (_, valueIndex) = try source.byteValue(from: nextIndex) as (UInt64, Index)
      return try parseValue(from: valueIndex)

      // MARK: Bool

    case 0xF4:
      return (false, nextIndex)
    case 0xF5:
      return (true, nextIndex)

      // MARK: Null

    case 0xF6:
      return (NSNull(), nextIndex)

      // MARK: Undefined

    case 0xF7:
      // Coding as a Null
      return (NSNull(), nextIndex)

      // MARK: Floats

    case 0xF8:
      return (Int(source[nextIndex]), source.index(after: nextIndex))
    case 0xF9:
      let (element, endIndex) = try source.byteValue(from: nextIndex) as (UInt16, Index)
      return (Float32.float16(from: element), endIndex)
    case 0xFA:
      let (value, endIndex): (Float32, Index) = try source.byteValue(from: nextIndex)
      return (value, endIndex)
    case 0xFB:
      let (value, endIndex): (Float64, Index) = try source.byteValue(from: nextIndex)
      return (value, endIndex)

      // MARK: Break

    case 0xFF:
      // NOTE: This should only be found from parsing: byte-string, utf-8 string, maps, and arrays
      return (NSNull(), nextIndex)
    default:
      return nil
    }
  }
}

extension UnsafeRawBufferPointer {
  func nextBreakIndex(from start: Index) -> Index? {
    // 0xFF is the CBOR code for `break`
    return self[start ..< endIndex].firstIndex(of: 0xFF)
  }

  func byteValue<T>(from start: Index) throws -> (T, Index) {
    let endRange = start.advanced(by: MemoryLayout<T>.size)
    return (try self[start ..< endRange].reversed().withUnsafeBytes { pointer -> T in
      guard let rawValue = pointer.bindMemory(to: T.self).baseAddress else {
        // Throw
        throw PubNubError(.unknown)
      }
      return rawValue.pointee
    }, endRange)
  }

  // swiftlint:disable:next file_length
}
