//
//  ODB.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/20/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

// This is not thread-safe. Neither are the other ODB* objects and structs.
// It’s up to the caller to implement thread safety.
// Recommended use: in your code, create references to ODB and ODBPath,
// and use ODBObject, ODBTable, and ODBValueObject the least amount possible. Do not keep references to them.

public final class ODB: Hashable {

	public let filepath: String

	public lazy var rootTable: ODBTable = {
		ODBTable(uniqueID: -1, name: ODBPath.rootTableName, parentTable: nil, isRootTable: true, odb: self)
	}()

	static let rootTableID = -1

	private let queue: RSDatabaseQueue

	private lazy var odbValuesTable: ODBValuesTable = {
		return ODBValuesTable(odb: self)
	}()
	
	private lazy var odbTablesTable: ODBTablesTable = {
		return ODBTablesTable(odb: self)
	}()

	private static let tableCreationStatements = """
	CREATE TABLE if not EXISTS odb_tables (id INTEGER PRIMARY KEY AUTOINCREMENT, parent_id INTEGER NOT NULL, name TEXT NOT NULL);

	CREATE TABLE if not EXISTS odb_values (id INTEGER PRIMARY KEY AUTOINCREMENT, odb_table_id INTEGER NOT NULL, name TEXT NOT NULL, primitive_type INTEGER NOT NULL, application_type TEXT, value BLOB);

	CREATE INDEX if not EXISTS odb_tables_parent_id_index on odb_tables (parent_id);
	CREATE INDEX if not EXISTS odb_values_odb_table_id_index on odb_values (odb_table_id);

	CREATE TRIGGER if not EXISTS odb_tables_after_delete_trigger_delete_subtables after delete on odb_tables begin delete from odb_tables where parent_id = OLD.id; end;
	CREATE TRIGGER if not EXISTS odb_tables_after_delete_trigger_delete_child_values after delete on odb_tables begin delete from odb_values where odb_table_id = OLD.id; end;
	"""

	public init(filepath: String) {
		self.filepath = filepath

		let queue = RSDatabaseQueue(filepath: filepath, excludeFromBackup: false)
		queue.createTables(usingStatements: ODB.tableCreationStatements)
		self.queue = queue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(filepath)
	}

	public static func ==(lhs: ODB, rhs: ODB) -> Bool {
		return lhs.filepath == rhs.filepath
	}
}

extension ODB {

	func deleteObject(_ object: ODBObject) {

		if let valueObject = object as? ODBValueObject {
			let uniqueID = valueObject.uniqueID
			queue.update { (database) in
				self.odbValuesTable.deleteObject(uniqueID: uniqueID, database: database)
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
			self.odbValuesTable.deleteChildObjects(parentUniqueID: parentUniqueID, database: database)
		}
	}

	func insertTable(name: String, parent: ODBTable) -> ODBTable? {

		var table: ODBTable? = nil
		queue.fetchSync { (database) in
			table = self.odbTablesTable.insertTable(name: name, parentTable: parent, database: database)
		}
		return table
	}

	func insertValueObject(name: String, value: ODBValue, parent: ODBTable) -> ODBValueObject? {

		var valueObject: ODBValueObject? = nil
		queue.updateSync { (database) in
			valueObject = self.odbValuesTable.insertValueObject(name: name, value: value, parentTable: parent, database: database)
		}

		return valueObject
	}

	func fetchChildren(of table: ODBTable) -> ODBDictionary {

		var children = ODBDictionary()

		queue.fetchSync { (database) in

			let tables = self.odbTablesTable.fetchSubtables(of: table, database: database)
			let valueObjects = self.odbValuesTable.fetchValueObjects(of: table, database: database)

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

extension String {

	private static let lowercaseLocale = Locale(identifier: "en")

	func odbLowercased() -> String {
		return self.lowercased(with: String.lowercaseLocale)
	}
}

extension Array where Element == String {

	func odbLowercased() -> [String] {
		return self.map{ $0.odbLowercased() }
	}
}
