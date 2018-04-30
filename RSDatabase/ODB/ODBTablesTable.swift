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

	func fetchSubtables(of table: ODBTable, database: FMDatabase) -> Set<ODBTable> {

		guard let rs: FMResultSet = database.executeQuery("select * from odb_tables where parent_id = ?", withArgumentsIn: [table.uniqueID]) else {
			return Set<ODBTable>()
		}

		return rs.mapToSet{ table(with: $0) }
	}
}

private extension ODBTablesTable {

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
