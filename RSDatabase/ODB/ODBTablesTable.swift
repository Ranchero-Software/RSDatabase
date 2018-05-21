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
	weak var delegate: ODBTableDelegate?

	init(delegate: ODBTableDelegate) {

		self.delegate = delegate
	}

	private struct Key {
		static let uniqueID = "id"
		static let parentID = "parent_id"
		static let name = "name"
	}

	func fetchSubtables(of table: ODBTable, database: FMDatabase) -> Set<ODBTable> {

		guard let rs: FMResultSet = database.executeQuery("select * from odb_tables where parent_id = ?", withArgumentsIn: [table.uniqueID]) else {
			return Set<ODBTable>()
		}

		return rs.mapToSet{ createTable(with: $0, parentTable: table) }
	}

	func insertTable(name: String, parentTable: ODBTable, database: FMDatabase) -> ODBTable? {

		guard let delegate = delegate else {
			return nil
		}

		let d: NSDictionary = [Key.parentID: parentTable.uniqueID, name: name]
		insertRow(d, insertType: .normal, in: database)
		let uniqueID = database.lastInsertRowId()
		return ODBTable(uniqueID: uniqueID, name: name, parentTable: parentTable, isRootTable: false, delegate: delegate)
	}
}

private extension ODBTablesTable {

	func createTable(with row: FMResultSet, parentTable: ODBTable) -> ODBTable? {

		guard let delegate = delegate else {
			return nil
		}
		guard let name = row.string(forColumn: Key.name) else {
			return nil
		}
		let uniqueID = Int(row.longLongInt(forColumn: Key.uniqueID))

		return ODBTable(uniqueID: uniqueID, name: name, parentTable: parentTable, isRootTable: false, delegate: delegate)
	}
}
