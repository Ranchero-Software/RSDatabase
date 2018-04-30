//
//  ODBObjectsTable.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/20/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

final class ODBObjectsTable: DatabaseTable {

	let name: String
	let queue: RSDatabaseQueue

	init(name: String, queue: RSDatabaseQueue) {

		self.name = name
		self.queue = queue
	}

	private struct Key {
		static let databaseID = "id"
		static let parentID = "odb_table_id"
		static let name = "name"
		static let primitiveType = "primitive_type"
		static let applicationType = "application_type"
		static let value = "value"
	}

	func fetchValueObjects(of table: ODBTable, database: FMDatabase) -> Set<ODBValueObject> {

		guard let rs: FMResultSet = database.executeQuery("select * from odb_objects where odb_table_id = ?", withArgumentsIn: [table.uniqueID]) else {
			return Set<ODBValueObject>()
		}

		return rs.mapToSet{ valueObject(with: $0) }
	}
}

private extension ODBObjectsTable {

	func valueObject(with row: FMResultSet) -> ODBValueObject {

		guard let value = value(with row: FMResultSet) else {
			return nil
		}
		guard let uniqueID = row.longLongInt(forColumn: Key.id) else {
			return nil
		}
		guard let parentID = row.longLongInt(forColumn: Key.parentID) else {
			return nil
		}
		guard let name = row.string(forColumn: Key.name) else {
			return nil
		}

		return ODBValueObject(uniqueID: uniqueID, parentTableID: parentID, name: name, value: value)
	}

	func value(with row: FMResultSet) -> ODBValue {

		let primitiveType = row.longLongInt(forColumn: Key.)
	}
}
