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
	weak var odb: ODB?
	public let hashValue: Int

	public var object: ODBObject? {
		return resolvedObject()
	}

	public var parentTablePath: ODBPath? {

		guard let odb = odb, elements.count > 0 else {
			return nil
		}
		return ODBPath(elements: Array(elements.dropLast()), odb: odb)
	}

	public var parentTable: ODBTable? {

		if isRoot {
			return nil
		}
		return parentTablePath?.object
	}

	init(elements: [String], odb: ODB) {

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

		self.odb = odb
		self.hashValue = ODBPath.hashValue(with: self.lowercasedElements)
	}

	public static func root(_ odb: ODB) -> ODBPath {

		return ODBPath(elements: [String](), odb: odb)
	}

	public func pathByAdding(_ element: String) -> ODBPath {

		return ODBPath(elements: elements + [element], odb: odb)
	}

	public func setValue(_ value: ODBValue) -> Bool {

		// If not defined or is root table, return false.

		precondition(ODB.isLocked)
		guard let parentTable = parentTable else {
			return false
		}
		parentTable.setValue(value, name: name)
	}

	public func createTable() -> ODBTable? {

		// Deletes any existing table.
		// Parent table must already exist, or it returns nil.

		precondition(ODB.isLocked)
		return parentTable?.addSubtable(name: name)
	}

	public func ensureTable() -> ODBTable? {

		// Won’t delete anything.
		// Return the table for the final item in the path.
		// Return nil if the path contains an existing non-table item.

		precondition(ODB.isLocked)
		if isRoot {
			return odb?.rootTable
		}

		
	}

	public static func ==(lhs: ODBPath, rhs: ODBPath) -> Bool {

		if lhs.lowercasedElements != rhs.lowercasedElements {
			return false
		}
		guard let leftODB = lhs.odb, let rightODB = rhs.odb else {
			if lhs.odb == nil && rhs.odb != nil {
				return false
			}
			if lhs.odb != nil && rhs.odb == nil {
				return false
			}
			return true //both nil
		}
		return leftODB === rightODB
	}
}

private extension ODBPath {

	func resolvedObject() -> ODBObject? {

		guard let odb = odb else {
			return nil
		}
		if isRoot {
			return odb.rootTable
		}
		guard let parentTablePath = parentTablePath, let parentTable = parentTablePath.object as? ODBTable else {
			return nil
		}
		return parentTable[name]
	}

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
