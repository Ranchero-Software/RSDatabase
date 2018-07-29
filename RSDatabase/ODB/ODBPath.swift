//
//  ODBPath.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/21/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

/**
	An ODBPath is an array like ["system", "verbs", "apps", "Xcode"] plus an associated ODB.
	The first element in the array may be "root". If so, it’s ignored: "root" is implied.
	An empty array or ["root"] refers to the root table.
*/

public final class ODBPath: Hashable {

	let elements: [String]
	let lowercasedElements: [String]
	let name: String
	let isRoot: Bool
	weak var odb: ODB?
	let odbFilepath: String

	/// The optional ODBObject at this path.
	public var object: ODBObject? {
		return resolvedObject()
	}

	/// The optional ODBTable at this path. Returns nil if undefined or is a value.
	public var table: ODBTable? {
		return object as? ODBTable
	}

	/// The optional ODBValue at this path. Returns nil if undefined or is a table.
	public var value: ODBValue? {
		guard let valueObject = object as? ODBValueObject else {
			return nil
		}
		return valueObject.value
	}

	/// The optional path to the parent table. Nil if path is to the root table.
	public let parentTablePath: ODBPath?

	public var parentTable: ODBTable? {
		return parentTablePath?.table
	}

	init(elements: [String], odb: ODB) {

		let canonicalElements = ODBPath.dropLeadingRootElement(from: elements)
		self.elements = canonicalElements
		self.lowercasedElements = canonicalElements.map{ $0.odbLowercased() }

		if canonicalElements.count < 1 {
			self.name = ODB.rootTableName
			self.isRoot = true
			self.parentTablePath = nil
		}
		else {
			self.name = canonicalElements.last!
			self.isRoot = false
			self.parentTablePath = odb.path(elements: Array(elements.dropLast()))
		}

		self.odb = odb
		self.odbFilepath = odb.filepath
	}

	public static func root(_ odb: ODB) -> ODBPath {

		return ODBPath(elements: [String](), odb: odb)
	}

	public func pathByAdding(_ element: String) -> ODBPath? {

		return odb?.path(elements + [element])
	}

	public func setValue(_ value: ODBValue) -> Bool {

		// If not defined or is root table, return false.

		precondition(ODB.isLocked)
		guard let parentTable = parentTable else {
			return false
		}
		return parentTable.setValue(value, name: name)
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

		if let object = object {
			return object as? ODBTable // Return existing table, or nil if it’s an ODBValueObject
		}

		guard let parentTable = parentTablePath?.ensureTable() else {
			return nil
		}
		return parentTable.addSubtable(name: name)
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(lowercasedElements)
		hasher.combine(odbFilepath)
	}

	public static func ==(lhs: ODBPath, rhs: ODBPath) -> Bool {

		return lhs.odbFilepath == rhs.odbFilepath && lhs.lowercasedElements == rhs.lowercasedElements
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
