//
//  ODBPath.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/21/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

/**
	An ODBPath is an array like ["system", "verbs", "apps", "Xcode"].
	The first element in the array may be "root". If so, it’s ignored: "root" is implied.
	An empty array or ["root"] refers to the root table.
	A path does not necessarily point to something that exists. It’s like file paths or URLs.
*/

public struct ODBPath: Hashable {

	/// The last element in the path. May not have same capitalization as canonical name in the database.
	public let name: String

	/// True if this path points to a root table.
	public let isRoot: Bool

	/// Root table name. Constant.
	public static let rootTableName = "root"

	/// Elements of the path minus any unneccessary initial "root" element.
	public let elements: [String]

	/// ODBPath that represents the root table.
	public static let root = ODBPath.path([String]())

	/// The optional path to the parent table. Nil only if path is to the root table.
	public var parentTablePath: ODBPath? {
		if isRoot {
			return nil
		}
		return ODBPath.path(Array(elements.dropLast()))
	}

	private let lowercasedElements: [String]
	private static var pathCache = [[String]: ODBPath]()
	private static let pathCacheLock = NSLock()

	private init(elements: [String]) {

		let canonicalElements = ODBPath.dropLeadingRootElement(from: elements)
		self.elements = canonicalElements
		self.lowercasedElements = canonicalElements.odbLowercased()

		if canonicalElements.count < 1 {
			self.name = ODBPath.rootTableName
			self.isRoot = true
		}
		else {
			self.name = canonicalElements.last!
			self.isRoot = false
		}
	}

	/// Create a path.
	public static func path(_ elements: [String]) -> ODBPath {

		pathCacheLock.lock()
		defer {
			pathCacheLock.unlock()
		}

		if let cachedPath = pathCache[elements] {
			return cachedPath
		}
		let path = ODBPath(elements: elements)
		pathCache[elements] = path
		return path
	}

	/// Create a path by adding an element.
	public func pathByAdding(_ element: String) -> ODBPath {
		return ODBPath.path(elements + [element])
	}

	/// Create a path by adding an element.
	public static func +(lhs: ODBPath, rhs: String) -> ODBPath {
		return lhs.pathByAdding(rhs)
	}

	/// Fetch the database object at this path.
	public func odbObject(with odb: ODB) -> ODBObject? {
		return resolvedObject(odb)
	}

	/// Fetch the value at this path.
	public func value(with odb: ODB) -> ODBValue? {
		return odbObject(with: odb) as? ODBValue
	}

	/// Set a value for this path. Will overwrite existing value or table.
	/// Return false if not defined or is root table.
	public func setValue(_ value: ODBValue, odb: ODB) -> Bool {
		return parentTable(with: odb)?.setValue(value, name: name) ?? false
	}

	/// Fetch the table at this path.
	public func table(with odb: ODB) -> ODBTable? {
		return odbObject(with: odb) as? ODBTable
	}

	/// Fetch the parent table. Nil if this is the root table or if table doesn’t exist.
	public func parentTable(with odb: ODB) -> ODBTable? {
		return parentTablePath?.table(with: odb)
	}

	/// Creates a table — will delete existing table.
	/// Returns nil if parent table doesn’t already exist. (See ensureTable.)
	public func createTable(with odb: ODB) -> ODBTable? {
		return parentTable(with: odb)?.addSubtable(name: name)
	}

	/// Return the table for the final item in the path.
	/// Won’t delete anything.
	/// Returns nil if the path contains an existing non-table (value) item.
	@discardableResult
	public func ensureTable(with odb: ODB) -> ODBTable? {
		if isRoot {
			return odb.rootTable
		}

		if let existingObject = odbObject(with: odb) {
			if let existingTable = existingObject as? ODBTable {
				return existingTable
			}
			return nil // It must be a value: don’t overwrite.
		}

		guard let parentTable = parentTablePath?.ensureTable(with: odb) else {
			return nil
		}
		return parentTable.addSubtable(name: name)
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(lowercasedElements)
	}

	public static func ==(lhs: ODBPath, rhs: ODBPath) -> Bool {
		return lhs.lowercasedElements == rhs.lowercasedElements
	}
}

private extension ODBPath {

	func resolvedObject(_ odb: ODB) -> ODBObject? {
		if isRoot {
			return odb.rootTable
		}
		return parentTable(with: odb)?[name]
	}

	static func dropLeadingRootElement(from elements: [String]) -> [String] {
		if elements.count < 1 {
			return elements
		}
		
		let firstElement = elements.first!
		if firstElement.odbLowercased() == ODBPath.rootTableName {
			return Array(elements.dropFirst())
		}

		return elements
	}
}
