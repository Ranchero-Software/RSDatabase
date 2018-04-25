//
//  ODB.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/20/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

public final class ODB {

	let filepath: String
	private let queue: RSDatabaseQueue
	private let odbTablesTable: ODBTablesTable
	private let odbObjectsTable: ODBObjectsTable
	private let rootTable = ODBTable(databaseID: -1, parentTableID: nil, isRoot: true)
	public static let rootTableName = "root"

	private static let tableCreationStatements = """
	CREATE TABLE if not EXISTS odb_tables (id INTEGER PRIMARY KEY AUTOINCREMENT, parent_id INTEGER, name TEXT NOT NULL);

	CREATE TABLE if not EXISTS odb_objects (id INTEGER PRIMARY KEY AUTOINCREMENT, odb_table_id INTEGER NOT NULL, name TEXT NOT NULL, primitive_type INTEGER NOT NULL, application_type TEXT, value BLOB);

	CREATE INDEX if not EXISTS odb_tables_parent_id_index on odb_tables (parent_id);
	CREATE INDEX if not EXISTS odb_objects_odb_table_id_index on odb_objects (parent_id);
	"""

	private let recursiveLock = NSRecursiveLock()

	public init(filepath: String) {

		self.filepath = filepath

		let queue = RSDatabaseQueue(filepath: filepath, excludeFromBackup: false)
		queue.createTables(usingStatements: ODB.tableCreationStatements)
		self.queue = queue

		self.odbTablesTable = ODBTablesTable(name: "odb_tables", queue: queue)
		self.odbObjectsTable = ODBObjectsTable(name: "odb_objects", queue: queue)
	}

	// MARK: - API

	public func item(at path: ODBPath) -> Any? {

		// If not defined, it returns nil.
		// Returns ODBTable or ODBObject.

		lock()
		defer {
			unlock()
		}

		guard let parent = _parentTable(for: path) else {
			return nil
		}

		if let table = table(for: path) {
			return table
		}
		if let object = object(for: path) {
			return object
		}

		return nil
	}

	public func parentTable(for path: ODBPath) -> ODBTable? {

		lock()
		defer {
			unlock()
		}

		return _parentTable(for: path)
	}

	public func deleteItem(at path: ODBPath) -> Bool {

		lock()
		defer {
			unlock()
		}

		return false
	}

	public func setValue(value: ODBPath, at path: ODBPath) -> Bool {

		lock()
		defer {
			unlock()
		}
	}

	public func createTable(name: String, at path: ODBPath) -> Bool {

		
	}

	public func ensureTable(name: String, at path: ODBPath) -> Bool {

	}
}

extension ODB: ODBTableDelegate {

	func fetchChildren(of table: ODBTable) -> [String: Any] {

		lock()
		defer {
			unlock()
		}

		var children: [String: Any]? = nil

		queue.fetchSync { (database) in

			let rs = 

		}

		return children
	}
}

private extension ODB {

	func lock() {
		recursiveLock.lock()
	}

	func unlock() {
		recursiveLock.unlock()
	}

	func _parentTable(for path: ODBPath) -> ODBTable? {

		guard let parentPath = path.parentTablePath() else {
			return nil
		}
		if parentPath.isRoot {
			return rootTable
		}

		return nil
	}

	func _item(at path: ODBPath) -> Any? {

		var nomad = rootTable
		if path.isRoot {
			return nomad
		}

		let numberOfElements = path.elements.count
		var indexOfElement = 0
		for element in path {

			let isLastElement = (indexOfElement >= numberOfElements - 1)
			if isLastElement {
				return nomad[element]
			}

			guard let child = nomad[element] as? ODBTable else {
				return nil
			}
			nomad = child

			indexOfElement += 1
		}
	}

	func table(for path: ODBPath) -> ODBTable? {

		return nil
	}

	func object(for path: ODBPath) -> ODBObject? {

		return nil
	}
}

public extension String {

	private static let lowercaseLocale = Locale(identifier: "en")

	public func odbLowercased() -> String {

		return self.lowercased(with: String.lowercaseLocale)
	}
}
