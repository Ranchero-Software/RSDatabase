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

	init(uniqueID: Int, name: String, parentTable: ODBTable?, isRootTable: Bool, delegate: ODBTableDelegate) {

		self.uniqueID = uniqueID
		self.name = name
		self.parentTable = parentTable
		self.isRootTable = isRootTable
		self.delegate = delegate
		self.hashValue = uniqueID
	}

	public subscript(_ key: String) -> ODBObject? {
		get {
			return children![key.odbLowercased()]
		}
		set {
			children![key.odbLowercased()] = newValue
		}
	}

	public func deleteChildren() {
		// TODO: set children to empty dictionary; tell delegate to delete tables and objects for this table
	}

	public func setValue(_ value: ODBValue, key: String) {

	}

	public static func ==(lhs: ODBTable, rhs: ODBTable) -> Bool {

		return lhs.uniqueID == rhs.uniqueID
	}
}

extension ODBTable: ODBObject {

	public var path: ODBPath? {
		return nil // TODO
	}

	public var value: ODBValue? {
		return nil
	}

	public var children: ODBDictionary? {
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

	public func delete() {
		// TODO
	}

}
