//
//  XMLSerialization.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

class XMLSerialization: NSObject {
  enum XMLError: Error {
    case malformedXML
  }

  struct Header {
    let version: Double
    let encoding: String

    init(version: Double = 1.0, encoding: String = "UTF-8") {
      self.version = version
      self.encoding = encoding
    }

    func toXMLString() -> String? {
      return "<?xml version=\"\(version)\" encoding=\"\(encoding)\"?>\n"
    }
  }

  struct Element {
    let key: String

    var value: String?
    var children: [Element]

    init(
      key: String,
      value: String? = nil,
      children: [Element] = []
    ) {
      self.key = key
      self.value = value
      self.children = children
    }

    init(key: String, value: Any) {
      switch value {
      case let value as String:
        self.init(key: key, value: value, children: [])
      case let value as [String: Any]:
        self.init(key: key, value: nil, children: value.map { Element(key: $0.key, value: $0.value) })
      default:
        self.init(key: key, value: nil, children: [])
      }
    }

    /// Output as a dictionary
    func toDictionary() -> [String: Any] {
      // There was no nested values
      if let value = value, !value.isEmpty {
        return [key: value]
      } else {
        return children.reduce(into: [String: Any]()) { $0[$1.key] = $1.elementValue() }
      }
    }

    func elementValue() -> Any {
      if let value = value {
        return value
      } else {
        return children.map { [$0.key: $0.elementValue()] }
      }
    }

    mutating func append(_ element: Element) {
      children.append(element)
    }

    mutating func append(_ string: String) {
      if value != nil {
        value?.append(string)
      } else {
        value = string
      }
    }

    func toXMLString() -> String {
      if let value = value {
        return "<\(key)>\(value)</\(key)>\n"
      } else {
        var nested = "<\(key)>\n"
        for child in children {
          nested = "\(nested)\(child.toXMLString())"
        }
        return "\(nested)</\(key)>\n"
      }
    }
  }

  // Serializer
  var root: Element?

  var current: Element?
  var stack: [Element] = []

  static func parse(from data: Data) throws -> [String: Any] {
    let parser = XMLSerialization()

    return try parser.parse(with: data)?.toDictionary() ?? [:]
  }

  static func toXMLString(root key: String, header: Header = Header(), from dictionary: [String: Any]) -> String {
    guard let header = header.toXMLString() else {
      return ""
    }

    return "\(header)\(Element(key: key, value: dictionary).toXMLString())"
  }

  func parse(with data: Data) throws -> Element? {
    let parser = XMLParser(data: data)
    parser.delegate = self

    if parser.parse() {
      return root
    } else if let error = parser.parserError {
      throw error
    } else {
      throw XMLError.malformedXML
    }
  }

  func withCurrentElement(_ body: (inout Element) throws -> Void) rethrows {
    guard !stack.isEmpty else {
      return
    }

    try body(&stack[stack.count - 1])
  }
}

// MARK: Delegate

extension XMLSerialization: XMLParserDelegate {
  func parserDidStartDocument(_: XMLParser) {
    root = nil
    stack = []
  }

  func parser(
    _: XMLParser,
    didStartElement elementName: String,
    namespaceURI _: String?,
    qualifiedName _: String?,
    attributes _: [String: String] = [:]
  ) {
    let element = Element(key: elementName)
    stack.append(element)
  }

  func parser(
    _: XMLParser,
    didEndElement _: String,
    namespaceURI _: String?,
    qualifiedName _: String?
  ) {
    guard let element = stack.popLast() else { return }

    withCurrentElement { currentElement in
      currentElement.append(element)
    }

    if stack.isEmpty {
      root = element
    }
  }

  func parser(_: XMLParser, foundCharacters string: String) {
    let processedString = string.trimmingCharacters(in: .whitespacesAndNewlines)

    // Ignore line breaks and empty string
    guard processedString.count > 0, string.count != 0 else {
      return
    }

    withCurrentElement { currentElement in
      currentElement.append(processedString)
    }
  }
}
