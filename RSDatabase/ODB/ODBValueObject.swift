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
	public let parentTable: ODBTable?
	public let name: String
	public let value: ODBValue?
	public let hashValue: Int
	public let isTable = false
	public let isRootTable = false
	public let children: ODBDictionary? = nil

	public var path: ODBPath? {
		return nil // TODO
	}

	init(uniqueID: Int, parentTable: ODBTable, name: String, value: ODBValue) {

		self.uniqueID = uniqueID
		self.parentTable = parentTable
		self.name = name
		self.value = value
		self.hashValue = uniqueID.hashValue
	}

	public func delete() {
		// TODO
	}

	public static func ==(lhs: ODBValueObject, rhs: ODBValueObject) -> Bool {

		return lhs.uniqueID == rhs.uniqueID
	}
}
