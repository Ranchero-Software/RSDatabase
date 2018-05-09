//
//  ODBTable.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/21/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

protocol ODBTableDelegate: class {

	func fetchChildren(of: ODBTable) -> ODBDictionary
	func deleteObject(_: ODBObject)
	func deleteChildren(of: ODBTable)
	func insertTable(name: String, parent: ODBTable) -> ODBTable?
	func insertValueObject(name: String, value: ODBValue, parent: ODBTable) -> ODBValueObject?
}

public class ODBTable: Hashable {

	let uniqueID: Int
	public let isRootTable: Bool
	public let isTable = true
	weak var delegate: ODBTableDelegate?
	public var parentTable: ODBTable?
	public var name: String
	public let hashValue: Int
	private var _children: ODBDictionary?

	public var children: ODBDictionary {
		get {
			if _children == nil {
				_children = delegate?.fetchChildren(of: self)
			}
			return _children!
		}
		set {
			_children = newValue
		}
	}

	init(uniqueID: Int, name: String, parentTable: ODBTable?, isRootTable: Bool, delegate: ODBTableDelegate) {

		self.uniqueID = uniqueID
		self.name = name
		self.parentTable = parentTable
		self.isRootTable = isRootTable
		self.delegate = delegate
		self.hashValue = uniqueID
	}

	public subscript(_ name: String) -> ODBObject? {
		return children[name.odbLowercased()]
	}

	public func deleteChildren() -> Bool {

		delegate?.deleteChildren(of: self)
	}

	public func deleteObject(_ object: ODBObject) {

		delegate?.deleteObject(object)
	}

	public func deleteObject(name: String) -> Bool {

		guard let child = self[name] else {
			return false
		}
		deleteObject(child)
	}

	public func addSubtable(name: String) -> Bool {

		guard let subtable = delegate?.insertTable(name: name, parent: self) else {
			return false
		}
		addChild(name: name, object: subtable)
	}

	public func setValue(_ value: ODBValue, name: String) -> Bool {

		guard let valueObject = delegate?.insertValueObject(name: name, value: value, parent: self) else {
			return false
		}
		addChild(name: name, object: valueObject)
		return true
	}

	public static func ==(lhs: ODBTable, rhs: ODBTable) -> Bool {

		return lhs.uniqueID == rhs.uniqueID
	}
}

private extension ODBTable {

	func addChild(name: String, object: ODBObject) {
		let _ = deleteObject(name: name)
		children[name.odbLowercased()] = object
	}
}

extension ODBTable: ODBObject {

	public var path: ODBPath? {
		return nil // TODO
	}

	public func delete() {
		deleteObject(self)
	}

}
