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
		static let uniqueID = "id"
		static let parentID = "odb_table_id"
		static let name = "name"
		static let primitiveType = "primitive_type"
		static let applicationType = "application_type"
		static let value = "value"
	}

	func fetchValueObjects(of table: ODBTable, database: FMDatabase) -> Set<ODBValueObject> {

		guard let rs = database.executeQuery("select * from odb_objects where odb_table_id = ?", withArgumentsIn: [table.uniqueID]) else {
			return Set<ODBValueObject>()
		}

		return rs.mapToSet{ valueObject(with: $0) }
	}
}

private extension ODBObjectsTable {

	func valueObject(with row: FMResultSet) -> ODBValueObject? {

		guard let value = value(with row: FMResultSet) else {
			return nil
		}
		guard let name = row.string(forColumn: Key.name) else {
			return nil
		}
		let uniqueID = row.longLongInt(forColumn: Key.uniqueID)
		let parentID = row.longLongInt(forColumn: Key.parentID)

		return ODBValueObject(uniqueID: uniqueID, parentTableID: parentID, name: name, value: value)
	}

	func value(with row: FMResultSet) -> ODBValue? {

		guard let primitiveType = ODBValue.PrimitiveType(rawValue: row.longLongInt(forColumn: Key.uniqueID)) else {
			return nil
		}
		guard let applicationType = row.string(forColumn: Key.applicationType) else {
			return nil
		}
		var value: Any? = nil

		switch primitiveType {
		case boolean:
			value = row.bool(forColumn: Key.value)
		case integer:
			value = row.longLongInt(forColumn: Key.value)
		case double:
			value = row.double(forColumn: Key.value)
		case string:
			value = row.string(forColumn: Key.value)
		case data:
			value = row.data(forColumn: Key.value)
		case date:
			value = row.date(forColumn: Key.value)
		}

		guard let fetchedValue = value else {
			return nil
		}

		return ODBValue(value: fetchedValue, primitiveType: primitiveType, applicationType: applicationType)
	}
}
