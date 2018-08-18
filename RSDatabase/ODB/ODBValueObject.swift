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

	// ODBObject protocol properties
	public let name: String
	public let parentTable: ODBTable?
	public let odb: ODB

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
	}

	public func delete() { // ODBObject

		odb.deleteObject(self)
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(uniqueID)
		hasher.combine(odb)
	}

	public static func ==(lhs: ODBValueObject, rhs: ODBValueObject) -> Bool {

		return lhs.uniqueID == rhs.uniqueID && lhs.odb === rhs.odb
	}
}
