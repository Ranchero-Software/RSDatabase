//
//  ODBTable.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/21/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

protocol ODBTableDelegate {

	func fetchChildren(of: ODBTable) -> [String: Any]
}

public class ODBTable: ODBObject, Hashable {

	let uniqueID: Int
	let isRoot: Bool
	weak var delegate: ODBTableDelegate?
	var parentTableID: Int?
	let hashValue: Int

	var children: [String: Any] {
		get {
			if _children == nil {
				_children = delegate?.fetchChildren(of: self)
			}

			if let children = _children {
				return children
			}
			return [String: Any]
		}
		set {
			_children = newValue
		}
	}
	private var _children: [String: Any]?

	init(uniqueID: Int, parentTableID: Int?, isRoot: Bool, delegate: ODBTableDelegate) {

		self.uniqueID = uniqueID
		self.parentTableID = parentTableID
		self.isRoot = isRoot
		self.delegate = delegate
		self.hashValue = uniqueID
	}

	public subscript(_ key: String) -> ODBObject? {
		get {
			return children[key.odbLowercased()]
		}
	}

	public func deleteChildren() {

	}

	public func setValue(_ value: ODBValue, key: String) {

	}

	public static func ==(lhs: ODBTable, rhs: ODBTable) -> Bool {

		return lhs.uniqueID == rhs.uniqueID
	}
}


