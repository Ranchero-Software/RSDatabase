//
//  ODBObject.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/24/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

public typealias ODBDictionary = [String: ODBObject]

// ODBTable and ODBValueObject conform to ODBObject.

public protocol ODBObject {

	var name: String { get }
	var isRootTable: Bool { get }
	var parentTable: ODBTable? { get }
	var path: ODBPath? { get }
	var odb: ODB { get }

	func delete()
}

public extension ODBObject {

	func delete() {

		guard !isRootTable else {
			preconditionFailure("Can’t delete root table.")
		}
		guard let parentTable = parentTable else {
			preconditionFailure("Expected parent table for object, found nil.")
		}

		parentTable.deleteChild(self)
	}
}
