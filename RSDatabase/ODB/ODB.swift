//
//  ODB.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/20/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

// Always call API or refer to ODB objects within an ODB.perform() call, which takes a block.
// Otherwise it’s not thread-safe. It will crash. On purpose.
// Exception: ODBValue structs are valid outside an ODB.perform() call.

public final class ODB {

	public let filepath: String

	public lazy var rootTable: ODBTable = {
		ODBTable(uniqueID: -1, name: ODB.rootTableName, parentTable: nil, isRootTable: true, delegate: self)
	}()

	static let rootTableName = "root"
	static let rootTableID = -1

	private let queue: RSDatabaseQueue
	private let odbObjectsTable = ODBObjectsTable()
	private lazy var odbTablesTable: ODBTablesTable = {
		return ODBTablesTable(delegate: self)
	}()

	private static let tableCreationStatements = """
	CREATE TABLE if not EXISTS odb_tables (id INTEGER PRIMARY KEY AUTOINCREMENT, parent_id INTEGER NOT NULL, name TEXT NOT NULL);

	CREATE TABLE if not EXISTS odb_objects (id INTEGER PRIMARY KEY AUTOINCREMENT, odb_table_id INTEGER NOT NULL, name TEXT NOT NULL, primitive_type INTEGER NOT NULL, application_type TEXT, value BLOB);

	CREATE INDEX if not EXISTS odb_tables_parent_id_index on odb_tables (parent_id);
	CREATE INDEX if not EXISTS odb_objects_odb_table_id_index on odb_objects (odb_table_id);

	CREATE TRIGGER if not EXISTS odb_tables_after_delete_trigger_delete_subtables after delete on odb_tables begin delete from odb_tables where parent_id = OLD.id; end;
	CREATE TRIGGER  if not EXISTS odb_tables_after_delete_trigger_delete_child_objects after delete on odb_tables begin delete from odb_objects where odb_table_id = OLD.id; end;
	"""

	private static let lock = NSLock()
	private static var isLocked = false

	public init(filepath: String) {

		self.filepath = filepath

		let queue = RSDatabaseQueue(filepath: filepath, excludeFromBackup: false)
		queue.createTables(usingStatements: ODB.tableCreationStatements)
		self.queue = queue
	}

	// MARK: - API

	public static func perform(_ block: () -> Void) {

		lock.lock()
		isLocked = true

		defer {
			isLocked = false
			lock.unlock()
		}

		block()
	}

	// The API below is path-based. See ODBObject, ODBTable, ODBValueObject, and ODBValue for more API.

	public func object(at path: ODBPath) -> ODBObject? {

		// If not defined, it returns nil.

		precondition(ODB.isLocked)

		if path.isRoot {
			return rootTable
		}
		guard let parent = parentTable(for: path) else {
			return nil
		}
		return parent[path.name]
	}

	public func parentTable(for path: ODBPath) -> ODBTable? {

		precondition(ODB.isLocked)

		if path.isRoot {
			return nil
		}
		guard let parentTablePath = path.parentTablePath() else {
			return nil
		}
		return object(at: parentTablePath) as? ODBTable
	}

	public func deleteObject(at path: ODBPath) -> Bool {

		// If not defined, return false.

		precondition(ODB.isLocked)

		guard let parent = parentTable(for: path) else {
			return false
		}
		return parent.deleteObject(name: path.name)
	}

	public func setValue(value: ODBValue, at path: ODBPath) -> Bool {

		// If not defined, return false.

		precondition(ODB.isLocked)

		guard let parent = parentTable(for: path) else {
			return false
		}
		return parent.setValue(value, name: path.name)
	}

	public func createTable(at path: ODBPath) -> ODBTable? {

		// Deletes any existing table.
		// Parent table must already exist, or it returns nil.

		precondition(ODB.isLocked)

		guard let parent = parentTable(for: path) else {
			return nil
		}
		return parent.addSubtable(name: path.name)
	}

	public func ensureTable(at path: ODBPath) -> ODBTable? {

		// Won’t delete anything.
		// Return the table for the final item in the path.
		// Return nil if the path contains an existing non-table item.

		precondition(ODB.isLocked)

		if path.isRoot {
			return rootTable
		}

		var pathNomad = ODBPath.root
		var table: ODBTable? = nil

		for element in path.elements {
			pathNomad = pathNomad.pathByAdding(element)
			let oneObject = object(at: pathNomad)

			if oneObject == nil {
				table = createTable(at: pathNomad)
			}
			else if oneObject is ODBTable {
				table = oneObject as? ODBTable
			}
			else {
				return nil // Object found — but not a table
			}
		}

		return table
	}
}

extension ODB: ODBTableDelegate {

	func deleteObject(_: ODBObject) {

	}

	func deleteChildren(of: ODBTable) {

	}

	func insertTable(name: String, parent: ODBTable) -> ODBTable? {

		precondition(ODB.isLocked)

		queue.fetchSync { (database) in

			
		}
	}

	func insertValueObject(name: String, value: ODBValue, parent: ODBTable) -> ODBValueObject? {

	}

	func fetchChildren(of table: ODBTable) -> ODBDictionary {

		precondition(ODB.isLocked)

		var children = ODBDictionary()

		queue.fetchSync { (database) in

			let tables = self.odbTablesTable.fetchSubtables(of: table, database: database)
			let valueObjects = self.odbObjectsTable.fetchValueObjects(of: table, database: database)

			// Keys are lower-cased, since we case-insensitive lookups.

			for valueObject in valueObjects {
				let lowerName = valueObject.name.odbLowercased()
				children[lowerName] = valueObject
			}

			for table in tables {
				let lowerName = table.name.odbLowercased()
				children[lowerName] = table
			}
		}

		return children
	}
}

public extension String {

	private static let lowercaseLocale = Locale(identifier: "en")

	public func odbLowercased() -> String {

		return self.lowercased(with: String.lowercaseLocale)
	}
}
