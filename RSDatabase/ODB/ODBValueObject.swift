//
//  ODBValueObject.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/21/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

public struct ODBValueObject: ODBObject, Hashable {

	let uniqueID: Int
	public let value: ODBValue
	public let hashValue: Int

	// ODBObject protocol properties
	public let name: String
	public let parentTable: ODBTable?
	public weak var odb: ODB?

	public var isTable: Bool {
		return false
	}

	public var isRootTable: Bool {
		return false
	}

	public var path: ODBPath? {
		return nil // TODO
	}

	init(uniqueID: Int, parentTable: ODBTable, name: String, value: ODBValue, odb: ODB) {

		self.uniqueID = uniqueID
		self.parentTable = parentTable
		self.name = name
		self.value = value
		self.odb = odb
		self.hashValue = uniqueID ^ name.hashValue
	}

	public func delete() { // ODBObject

		odb?.deleteObject(self)
	}

	public static func ==(lhs: ODBValueObject, rhs: ODBValueObject) -> Bool {

		if lhs.uniqueID != rhs.uniqueID {
			return false
		}
		guard let leftODB = lhs.odb, let rightODB = rhs.odb else {
			return false
		}
		return leftODB === rightODB
	}
}
