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
	public let odb: ODB
	public var parentTable: ODBTable?
	public var name: String
	private var _children: ODBDictionary?

	public var children: ODBDictionary {
		get {
			if _children == nil {
				_children = odb.fetchChildren(of: self)
			}
			return _children!
		}
		set {
			_children = newValue
		}
	}

	public var path: ODBPath? {
		if isRootTable {
			return ODBPath.root
		}
		guard let parentTablePath = parentTable?.path else {
			return nil
		}
		return parentTablePath + name
	}

	init(uniqueID: Int, name: String, parentTable: ODBTable?, isRootTable: Bool, odb: ODB) {

		self.uniqueID = uniqueID
		self.name = name
		self.parentTable = parentTable
		self.isRootTable = isRootTable
		self.odb = odb
	}

	public subscript(_ name: String) -> ODBObject? {
		return children[name.odbLowercased()]
	}

	public func deleteChildren() -> Bool {

		odb.deleteChildren(of: self)
		return true
	}

	public func deleteChild(_ object: ODBObject) {

		odb.deleteObject(object)
	}

	public func deleteObject(name: String) -> Bool {

		guard let child = self[name] else {
			return false
		}
		deleteChild(child)
		return true
	}

	public func addSubtable(name: String) -> ODBTable? {

		guard let subtable = odb.insertTable(name: name, parent: self) else {
			return nil
		}
		addChild(name: name, object: subtable)
		return subtable
	}

	public func setValue(_ value: ODBValue, name: String) -> Bool {

		guard let valueObject = odb.insertValueObject(name: name, value: value, parent: self) else {
			return false
		}
		addChild(name: name, object: valueObject)
		return true
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(uniqueID)
		hasher.combine(odb)
	}

	public static func ==(lhs: ODBTable, rhs: ODBTable) -> Bool {
		return lhs.uniqueID == rhs.uniqueID && lhs.odb == rhs.odb
	}
}

private extension ODBTable {

	func addChild(name: String, object: ODBObject) {
		let _ = deleteObject(name: name)
		children[name.odbLowercased()] = object
	}
}
