//
//  ODBTablesTable.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/20/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

final class ODBTablesTable: DatabaseTable {

	let name = "odb_tables"
	weak var tableDelegate: ODBTableDelegate?

	init(tableDelegate: ODBTableDelegate) {

		self.tableDelegate = tableDelegate
	}

	private struct Key {
		static let databaseID = "id"
		static let parentID = "parent_id"
		static let name = "name"
	}

	func fetchChildren(of table: ODBTable) -> [String: Any] {

		// Keys are lower-cased, since we case-insensitive lookups.
		
		let tables = fetchSubtables(of: table, database: database)
		let valueObjects = fetchValueObjects(of: table, database: database)

		var children = [String: ODBObject]()

		for valueObject in valueObjects {
			let lowerName = valueObject.name.odbLowercased()
			children[lowerName] = valueObject
		}

		for table in tables {
			let lowerName = table.name.odbLowercased()
			children[lowerName] = table
		}

		return children
	}
}

private extension ODBTablesTable {

	func fetchSubtables(of table: ODBTable, database: FMDatabase) -> Set<ODBTable> {

		guard let rs: FMResultSet = database.executeQuery("select * from odb_tables where parent_id = ?", withArgumentsIn: [table.uniqueID]) else {
			return Set<ODBTable>()
		}

		return rs.mapToSet{ table(with: $0) }
	}

	func fetchValueObjects(of table: ODBTable, database: FMDatabase) -> Set<ODBValueObject> {

		guard let rs: FMResultSet = database.executeQuery("select * from odb_objects where odb_table_id = ?", withArgumentsIn: [table.uniqueID]) else {
			return Set<ODBValueObject>()
		}

		return rs.mapToSet{ valueObject(with: $0) }
	}

	func table(with row: FMResultSet) -> ODBTable? {

		guard let uniqueID = row.longLongInt(forColumn: Key.id) else {
			return nil
		}
		guard let parentID = row.longLongInt(forColumn: Key.parentID) else {
			return nil
		}
		guard let name = row.string(forColumn: Key.name) else {
			return nil
		}

		return ODBTable(uniqueID: uniqueID, parentTableID: parentID, isRoot: false, delegate: tableDelegate)
	}
}
