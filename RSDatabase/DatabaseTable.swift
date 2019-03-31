//
//  DatabaseTable.swift
//  RSDatabase
//
//  Created by Brent Simmons on 7/16/17.
//  Copyright © 2017 Ranchero Software, LLC. All rights reserved.
//

import Foundation

public protocol DatabaseTable {

	var name: String { get }
}

public extension DatabaseTable {
	
	// MARK: Fetching

	func selectRowsWhere(key: String, equals value: Any, in database: FMDatabase) -> FMResultSet? {
		
		return database.rs_selectRowsWhereKey(key, equalsValue: value, tableName: name)
	}

	func selectSingleRowWhere(key: String, equals value: Any, in database: FMDatabase) -> FMResultSet? {

		return database.rs_selectSingleRowWhereKey(key, equalsValue: value, tableName: name)
	}

	func selectRowsWhere(key: String, inValues values: [Any], in database: FMDatabase) -> FMResultSet? {

		if values.isEmpty {
			return nil
		}
		return database.rs_selectRowsWhereKey(key, inValues: values, tableName: name)
	}

	// MARK: Deleting

	func deleteRowsWhere(key: String, equalsAnyValue values: [Any], in database: FMDatabase) {
		
		if values.isEmpty {
			return
		}
		database.rs_deleteRowsWhereKey(key, inValues: values, tableName: name)
	}

	// MARK: Updating

	func updateRowsWithValue(_ value: Any, valueKey: String, whereKey: String, matches: [Any], database: FMDatabase) {
		
		let _ = database.rs_updateRows(withValue: value, valueKey: valueKey, whereKey: whereKey, inValues: matches, tableName: self.name)
	}
	
	func updateRowsWithDictionary(_ dictionary: DatabaseDictionary, whereKey: String, matches: Any, database: FMDatabase) {
		
		let _ = database.rs_updateRows(with: dictionary, whereKey: whereKey, equalsValue: matches, tableName: self.name)
	}
	
	// MARK: Saving

	func insertRows(_ dictionaries: [DatabaseDictionary], insertType: RSDatabaseInsertType, in database: FMDatabase) {

		dictionaries.forEach { (oneDictionary) in
			let _ = database.rs_insertRow(with: oneDictionary, insertType: insertType, tableName: self.name)
		}
	}

	func insertRow(_ rowDictionary: DatabaseDictionary, insertType: RSDatabaseInsertType, in database: FMDatabase) {

		insertRows([rowDictionary], insertType: insertType, in: database)
	}

	// MARK: Counting

	func numberWithCountResultSet(_ resultSet: FMResultSet) -> Int {

		guard resultSet.next() else {
			return 0
		}
		return Int(resultSet.int(forColumnIndex: 0))
	}

	func numberWithSQLAndParameters(_ sql: String, _ parameters: [Any], in database: FMDatabase) -> Int {

		if let resultSet = database.executeQuery(sql, withArgumentsIn: parameters) {
			return numberWithCountResultSet(resultSet)
		}
		return 0
	}

	// MARK: Mapping

	func mapResultSet<T>(_ resultSet: FMResultSet, _ callback: (_ resultSet: FMResultSet) -> T?) -> [T] {

		var objects = [T]()
		while resultSet.next() {
			if let obj = callback(resultSet) {
				objects += [obj]
			}
		}
		return objects
	}

	// MARK: Columns

	func containsColumn(_ columnName: String, in database: FMDatabase) -> Bool {
		if let resultSet = database.executeQuery("select * from \(name) limit 1;", withArgumentsIn: nil) {
			if let columnMap = resultSet.columnNameToIndexMap {
				if let _ = columnMap[columnName.lowercased()] {
					return true
				}
			}
		}
		return false
	}
}

public extension FMResultSet {

	func compactMap<T>(_ callback: (_ row: FMResultSet) -> T?) -> [T] {

		var objects = [T]()
		while next() {
			if let obj = callback(self) {
				objects += [obj]
			}
		}
		close()
		return objects
	}

	func mapToSet<T>(_ callback: (_ row: FMResultSet) -> T?) -> Set<T> {

		return Set(compactMap(callback))
	}
}

