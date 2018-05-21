//
//  ODBPath.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/21/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

// A path is an array like ["system", "verbs", "apps", "Xcode"].
// The first element in the array may be "root". If so, it’s ignored: "root" is implied.
// An empty array or ["root"] refers to the root table.

public struct ODBPath: Hashable {

	let elements: [String]
	let lowercasedElements: [String]
	let name: String
	let isRoot: Bool
	public let hashValue: Int

	init(elements: [String]) {

		let canonicalElements = ODBPath.dropLeadingRootElement(from: elements)
		self.elements = canonicalElements
		self.lowercasedElements = canonicalElements.map{ $0.odbLowercased() }

		if canonicalElements.count < 1 {
			self.name = ODB.rootTableName
			self.isRoot = true
		}
		else {
			self.name = canonicalElements.last!
			self.isRoot = false
		}

		self.hashValue = ODBPath.hashValue(with: self.lowercasedElements)
	}

	static let root = ODBPath(elements: [String]())

	public func pathByAdding(_ element: String) -> ODBPath {

		return ODBPath(elements: elements + [element])
	}

	public func parentTablePath() -> ODBPath? {

		if elements.count < 1 {
			return nil
		}

		return ODBPath(elements: Array(elements.dropLast()))
	}

	public static func ==(lhs: ODBPath, rhs: ODBPath) -> Bool {

		return lhs.lowercasedElements == rhs.lowercasedElements
	}
}

private extension ODBPath {

	static func hashValue(with elements: [String]) -> Int {

		return elements.reduce(0) { (result, element) -> Int in
			return result + element.hashValue
		}
	}

	static func dropLeadingRootElement(from elements: [String]) -> [String] {

		if elements.count < 1 {
			return elements
		}
		let firstElement = elements.first!
		if firstElement.odbLowercased() == ODB.rootTableName {
			return Array(elements.dropFirst())
		}

		return elements
	}
}
