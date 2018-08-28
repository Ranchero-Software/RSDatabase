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
	public func odbObject(with odb: ODB) throws -> ODBObject {
		return try resolvedObject(odb)
	}

	/// Fetch the value at this path.
	public func value(with odb: ODB) throws -> ODBValue {
		guard let valueObject = try odbObject(with: odb) as? ODBValueObject else {
			throw ODBError.notAValue(path: self)
		}
		return valueObject.value
	}

	/// Fetch the raw value at this path.
	public func rawValue(with odb: ODB) throws -> Any {
		let valueObject = try value(with: odb)
		return valueObject.rawValue
	}

	/// Set a value for this path. Will overwrite existing value or table.
	public func setValue(_ value: ODBValue, odb: ODB) throws {
		if isRoot {
			throw ODBError.illegalOperationOnRootTable(path: self)
		}
		let table = try parentTable(with: odb)!
		try table.setValue(value, name: name)
	}

	/// Set the raw value for this path. Will overwrite existing value or table.
	public func setRawValue(_ rawValue: Any, odb: ODB) throws {
		guard let value = ODBValue(rawValue: rawValue) else {
			throw ODBError.invalidDataType(rawValue: rawValue)
		}
		try setValue(value, odb: odb)
	}

	/// Delete value or table at this path.
	public func delete(from odb: ODB) throws {
		if isRoot {
			throw ODBError.illegalOperationOnRootTable(path: self)
		}
		let table = try parentTable(with: odb)!
		try table.deleteObject(name: name)
	}

	/// Fetch the table at this path.
	public func table(with odb: ODB) throws -> ODBTable? {
		let object = try odbObject(with: odb)
		guard let table = object as? ODBTable else {
			throw ODBError.notATable(path: self)
		}
		return table
	}

	/// Fetch the parent table. Nil if this is the root table.
	public func parentTable(with odb: ODB) throws -> ODBTable? {
		return try parentTablePath?.table(with: odb)
	}

	/// Creates a table — will delete existing table.
	public func createTable(with odb: ODB) throws -> ODBTable {
		if isRoot {
			throw ODBError.illegalOperationOnRootTable(path: self)
		}
		return try parentTable(with: odb)!.addSubtable(name: name)
	}

	/// Return the table for the final item in the path.
	/// Won’t delete anything.
	@discardableResult
	public func ensureTable(with odb: ODB) throws -> ODBTable {

		try odb.preflightCall()

		if isRoot {
			return odb.rootTable
		}

		do {
			let existingObject = try odbObject(with: odb)
			if let existingTable = existingObject as? ODBTable {
				return existingTable
			}
			throw ODBError.notATable(path: self) // It must be a value: don’t overwrite.
		} catch ODBError.undefined {

		} catch {
			throw error
		}

		let parentTable = try parentTablePath!.ensureTable(with: odb)
		return try parentTable.addSubtable(name: name)
	}

	// MARK: - Hashable

	public func hash(into hasher: inout Hasher) {
		hasher.combine(lowercasedElements)
	}

	// MARK: - Equatable

	public static func ==(lhs: ODBPath, rhs: ODBPath) -> Bool {
		return lhs.lowercasedElements == rhs.lowercasedElements
	}
}

private extension ODBPath {

	func resolvedObject(_ odb: ODB) throws -> ODBObject {
		try odb.preflightCall()
		if isRoot {
			return odb.rootTable
		}
		let table = try parentTable(with: odb)!
		return try table.object(for: name)
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
