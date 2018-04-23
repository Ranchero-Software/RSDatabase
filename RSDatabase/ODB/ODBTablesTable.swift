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

	func table(for databaseID: Int, in database: FMDatabase) -> ODBTable {

		guard let row = selectSingleRowWhere(key: Key.databaseID, equals: databaseID, in: database) else {
			return
		}

		
	}

	func fetchChildTables(of table: ODBTable, in database: FMDatabase) -> [String: ODBTable] {

		guard let resultSet = selectRowsWhere(key: Key.parentID, equals: table.databaseID, in: database) else {
			return [String: ODBTable]
		}

		var tableDictionary = [String: ODBTable]()
		while resultSet.next() {
			if let oneTable = table(with: resultSet) {
				tableDictionary[oneTable.name] = oneTable
			}
		}

		return tableDictionary
	}
}

private extension ODBTablesTable {

	func table(with row: FMResultSet) -> ODBTable? {

		guard let databaseID = row.longLongInt(forColumn: Key.id) else {
			return nil
		}
		guard let parentID = row.longLongInt(forColumn: Key.parentID) else {
			return nil
		}
		guard let name = row.string(forColumn: Key.name) else {
			return nil
		}

		return ODBTable(databaseID: databaseID, parentTableID: parentID, isRoot: false, delegate: tableDelegate)
	}
}
