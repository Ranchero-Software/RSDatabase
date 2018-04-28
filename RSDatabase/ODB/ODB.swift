//
//  ODB.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/20/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

// Always call API or refer to ODB objects within an ODB.perform() call, which takes a block.
// Otherwise it’s not thread-safe, and behavior is undefined.
// Exception: ODBValue structs are valid outside an ODB.perform() call.

public final class ODB {

	let filepath: String
	private let queue: RSDatabaseQueue
	private let odbTablesTable: ODBTablesTable
	private let odbObjectsTable: ODBObjectsTable
	private let rootTable = ODBTable(databaseID: -1, parentTableID: nil, isRoot: true)
	public static let rootTableName = "root"
	public static let rootTableID = -1

	private static let tableCreationStatements = """
	CREATE TABLE if not EXISTS odb_tables (id INTEGER PRIMARY KEY AUTOINCREMENT, parent_id INTEGER NOT NULL, name TEXT NOT NULL);

	CREATE TABLE if not EXISTS odb_objects (id INTEGER PRIMARY KEY AUTOINCREMENT, odb_table_id INTEGER NOT NULL, name TEXT NOT NULL, primitive_type INTEGER NOT NULL, application_type TEXT, value BLOB);

	CREATE INDEX if not EXISTS odb_tables_parent_id_index on odb_tables (parent_id);
	CREATE INDEX if not EXISTS odb_objects_odb_table_id_index on odb_objects (parent_id);
	"""

	private static let lock = NSLock()

	public init(filepath: String) {

		self.filepath = filepath

		let queue = RSDatabaseQueue(filepath: filepath, excludeFromBackup: false)
		queue.createTables(usingStatements: ODB.tableCreationStatements)
		self.queue = queue

		self.odbTablesTable = ODBTablesTable(name: "odb_tables", queue: queue)
		self.odbObjectsTable = ODBObjectsTable(name: "odb_objects", queue: queue)
	}

	// MARK: - API

	public static func perform(_ block: () -> Void) {

		lock.lock()
		block()
		lock.unlock()
	}

	// The API below is path-based. See ODBObject, ODBTable, ODBValueObject, and ODBValue for more API.

	public func object(at path: ODBPath) -> ODBObject? {

		// If not defined, it returns nil.

		if path.isRoot {
			return rootTable
		}
		guard let parent = parentTable(for: path) else {
			return nil
		}
		return parent[path.name]
	}

	public func parentTable(for path: ODBPath) -> ODBTable? {

		if path.isRoot {
			return nil
		}
		return object(at: path.parentTablePath()) as? ODBTable
	}

	public func deleteObject(at path: ODBPath) -> Bool {

		// If not defined, return false.

		guard let parent = parentTable(for: path) else {
			return false
		}
		return parent[path.name] = nil
	}

	public func setValue(value: ODBValue, at path: ODBPath) -> Bool {

		// If not defined, return false.

		guard let parent = parentTable(for: path) else {
			return false
		}
		parent[path.name] = value
	}

	public func createTable(at path: ODBPath) -> ODBTable? {

		// Deletes any existing table.
		// Parent table must already exist, or it returns nil.

		guard let parent = parentTable(for: path) else {
			return nil
		}
		return parent.addSubtable(name: path.name)
	}

	public func ensureTable(at path: ODBPath) -> ODBTable? {

		// Won’t delete anything.
		// Return the table for the final item in the path.
		// Return nil if the path contains an existing non-table item.

		if path.isRoot {
			return rootTable
		}

		var pathNomad = []
		var table: ODBTable? = nil

		for element in path.elements {
			pathNomad += [element]
			let oneObject = object(at: pathNomad)

			if oneObject == nil {
				table = createTable(pathNomad.name, at: pathNomad)
			}
			else if oneObject is ODBTable {
				table = oneObject as! ODBTable
			}
			else {
				return nil // Object found — but not a table
			}
		}

		return table
	}
}

extension ODB: ODBTableDelegate {

	func fetchChildren(of table: ODBTable) -> [String: Any] {

		var children: [String: Any]? = nil

		queue.fetchSync { (database) in

			let rs = 

		}

		return children
	}
}

private extension ODB {

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
