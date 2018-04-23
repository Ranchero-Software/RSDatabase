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
		static let type = "type"
		static let value = "value"
	}

	func fetchChildObjects(of table: ODBTable, in database: FMDatabase) -> [String: ODBObject] {

		guard let resultSet = selectRowsWhere(key: Key.parentID, equals: table.databaseID, in: database) else {
			return [String: ODBTable]
		}

		var objectDictionary = [String: ODBTable]()
		while resultSet.next() {
			if let oneObject = object(with: resultSet) {
				objectDictionary[oneObject.name] = oneObject
			}
		}

		return objectDictionary

	}
}

private extension ODBObjectsTable {

	func object(with row: FMResultSet) -> ODBObject {

		guard let databaseID = row.longLongInt(forColumn: Key.id) else {
			return nil
		}
		guard let parentID = row.longLongInt(forColumn: Key.parentID) else {
			return nil
		}
		guard let name = row.string(forColumn: Key.name) else {
			return nil
		}
		guard let type = row.string(forColumn: Key.type) else {
			return nil
		}

		
		return ODBTable(databaseID: databaseID, parentTableID: parentID, isRoot: false, delegate: tableDelegate)
	}
}
