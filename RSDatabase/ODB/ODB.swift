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
// ODB.perform() calls are not nestable.

public final class ODB {

	public let filepath: String

	public lazy var rootTable: ODBTable = {
		ODBTable(uniqueID: -1, name: ODB.rootTableName, parentTable: nil, isRootTable: true, odb: self)
	}()

	static let rootTableName = "root"
	static let rootTableID = -1

	private let queue: RSDatabaseQueue

	private lazy var rootPath: ODBPath = {
		return ODBPath.root(self)
	}()

	private lazy var odbObjectsTable: ODBObjectsTable = {
		return ODBObjectsTable(odb: self)
	}()
	
	private lazy var odbTablesTable: ODBTablesTable = {
		return ODBTablesTable(odb: self)
	}()

	private static let tableCreationStatements = """
	CREATE TABLE if not EXISTS odb_tables (id INTEGER PRIMARY KEY AUTOINCREMENT, parent_id INTEGER NOT NULL, name TEXT NOT NULL);

	CREATE TABLE if not EXISTS odb_objects (id INTEGER PRIMARY KEY AUTOINCREMENT, odb_table_id INTEGER NOT NULL, name TEXT NOT NULL, primitive_type INTEGER NOT NULL, application_type TEXT, value BLOB);

	CREATE INDEX if not EXISTS odb_tables_parent_id_index on odb_tables (parent_id);
	CREATE INDEX if not EXISTS odb_objects_odb_table_id_index on odb_objects (odb_table_id);

	CREATE TRIGGER if not EXISTS odb_tables_after_delete_trigger_delete_subtables after delete on odb_tables begin delete from odb_tables where parent_id = OLD.id; end;
	CREATE TRIGGER if not EXISTS odb_tables_after_delete_trigger_delete_child_objects after delete on odb_tables begin delete from odb_objects where odb_table_id = OLD.id; end;
	"""

	private static let lock = NSLock()
	static var isLocked = false

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

	public func ensureTable(at path: ODBPath) -> ODBTable? {

		// Won’t delete anything.
		// Return the table for the final item in the path.
		// Return nil if the path contains an existing non-table item.

		precondition(ODB.isLocked)

		guard pathIsForThisODB(path) else {
			assertionFailure("path must refer to this ODB.")
			return nil
		}

		if path.isRoot {
			return rootTable
		}

		var pathNomad = rootPath
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

extension ODB {

	func deleteObject(_ object: ODBObject) {

		precondition(ODB.isLocked)

		if let valueObject = object as? ODBValueObject {
			let uniqueID = valueObject.uniqueID
			queue.update { (database) in
				self.odbObjectsTable.deleteObject(uniqueID: uniqueID, database: database)
			}
		}
		else if let tableObject = object as? ODBTable {
			let uniqueID = tableObject.uniqueID
			queue.update { (database) in
				self.odbTablesTable.deleteTable(uniqueID: uniqueID, database: database)
			}
		}
		else {
			preconditionFailure("deleteObject: object neither ODBValueObject or ODBTable")
		}
	}

	func deleteChildren(of table: ODBTable) {

		let parentUniqueID = table.uniqueID
		queue.update { (database) in
			self.odbTablesTable.deleteChildTables(parentUniqueID: parentUniqueID, database: database)
			self.odbObjectsTable.deleteChildObjects(parentUniqueID: parentUniqueID, database: database)
		}
	}

	func insertTable(name: String, parent: ODBTable) -> ODBTable? {

		precondition(ODB.isLocked)

		var table: ODBTable? = nil
		queue.fetchSync { (database) in
			table = self.odbTablesTable.insertTable(name: name, parentTable: parent, database: database)
		}
		return table
	}

	func insertValueObject(name: String, value: ODBValue, parent: ODBTable) -> ODBValueObject? {

		precondition(ODB.isLocked)

		var valueObject: ODBValueObject? = nil
		queue.updateSync { (database) in
			valueObject = self.odbObjectsTable.insertValueObject(name: name, value: value, parentTable: parent, database: database)
		}

		return valueObject
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
