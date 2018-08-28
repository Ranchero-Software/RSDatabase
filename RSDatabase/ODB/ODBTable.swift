//
//  ODBTable.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/21/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

public final class ODBTable: ODBObject, Hashable {

	let uniqueID: Int
	public let isRootTable: Bool
	public weak var odb: ODB?
	public var parentTable: ODBTable?
	public var name: String
	private let odbFilePath: String
	private var _children: ODBDictionary?

	public var children: ODBDictionary {
		get {
			if _children == nil {
				do {
					_children = try odb?.fetchChildren(of: self)
				}
				catch {}
			}
			return _children ?? ODBDictionary()
		}
		set {
			_children = newValue
		}
	}

	init(uniqueID: Int, name: String, parentTable: ODBTable?, isRootTable: Bool, odb: ODB) {
		self.uniqueID = uniqueID
		self.name = name
		self.parentTable = parentTable
		self.isRootTable = isRootTable
		self.odb = odb
		self.odbFilePath = odb.filepath
	}

	public func object(for name: String) throws -> ODBObject {
		try odb?.preflightCall()
		guard let obj = children[name.odbLowercased()] else {
			throw ODBError.undefined(path: try path() + name)
		}
		return obj
	}

	public func path() throws -> ODBPath {
		try odb?.preflightCall()
		if isRootTable {
			return ODBPath.root
		}
		return try parentTable!.path() + name
	}

	public func deleteChildren() throws {
		let odb = try strongODB()
		try odb.deleteChildren(of: self)
	}

	public func deleteChild(_ object: ODBObject) throws {
		let odb = try strongODB()
		try odb.deleteObject(object)
	}

	public func deleteObject(name: String) throws {
		let child = try object(for: name)
		try deleteChild(child)
	}

	public func addSubtable(name: String) throws -> ODBTable {
		let odb = try strongODB()
		let subtable = try odb.insertTable(name: name, parent: self)
		try addChild(name: name, object: subtable)
		return subtable
	}

	public func setValue(_ value: ODBValue, name: String) throws {
		let odb = try strongODB()
		let valueObject = try odb.insertValueObject(name: name, value: value, parent: self)
		try addChild(name: name, object: valueObject)
	}

	// MARK: - Hashable

	public func hash(into hasher: inout Hasher) {
		hasher.combine(uniqueID)
		hasher.combine(odb)
	}

	// MARK: - Equatable

	public static func ==(lhs: ODBTable, rhs: ODBTable) -> Bool {
		return lhs.uniqueID == rhs.uniqueID && lhs.odb == rhs.odb
	}
}

extension ODBTable {

	func close() {
		// Called from ODB when database is closing.
		if let rawChildren = _children {
			rawChildren.forEach { (key: String, value: ODBObject) in
				if let table = value as? ODBTable {
					table.close()
				}
			}
		}
		_children = nil
		parentTable = nil
		odb = nil
	}
}
private extension ODBTable {

	func strongODB() throws -> ODB {
		guard let odb = odb else {
			throw ODBError.odbClosed(filePath: odbFilePath)
		}
		try odb.preflightCall()
		return odb
	}

	func addChild(name: String, object: ODBObject) throws {
		let _ = try deleteObject(name: name)
		children[name.odbLowercased()] = object
	}
}
