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
// Recommended use: in your code, create references to ODB, ODBPath, and ODBValue,
// and use ODBObject, ODBTable, and ODBValueObject the least amount possible. Do not keep references to them.

public final class ODB: Hashable {

	public let filepath: String

	/// It’s an error to use the ODB once closed. This exists because somebody have kept a reference to the ODB.
	/// Call odb.close() when finished with it.
	public var isClosed = false

	static let rootTableID = -1
	public lazy var rootTable: ODBTable = {
		ODBTable(uniqueID: ODB.rootTableID, name: ODBPath.rootTableName, parentTable: nil, isRootTable: true, odb: self)
	}()

	private let queue: RSDatabaseQueue
	private var odbTablesTable: ODBTablesTable? = ODBTablesTable()
	private var odbValuesTable: ODBValuesTable? = ODBValuesTable()

	public init(filepath: String) {
		self.filepath = filepath
		let queue = RSDatabaseQueue(filepath: filepath, excludeFromBackup: false)
		queue.createTables(usingStatementsSync: ODB.tableCreationStatements)
		self.queue = queue
	}

	/// Call when finished, to make sure no stray references can do undefined things.
	/// It’s not necessary to call this on app termination.
	public func close() {
		isClosed = true
		odbValuesTable = nil
		odbTablesTable = nil
		rootTable.close()
	}

	/// Make sure it’s okay to use the odb — check that it hasn’t been closed.
	public func preflightCall() throws {
		if isClosed {
			throw ODBError.odbClosed(filePath: filepath)
		}
	}

	// MARK: - Hashable

	public func hash(into hasher: inout Hasher) {
		hasher.combine(filepath)
	}

	// MARK: - Equatable

	public static func ==(lhs: ODB, rhs: ODB) -> Bool {
		return lhs.filepath == rhs.filepath
	}
}

extension ODB {

	func deleteObject(_ object: ODBObject) throws {

		try preflightCall()

		if let valueObject = object as? ODBValueObject {
			let uniqueID = valueObject.uniqueID
			queue.update { (database) in
				self.odbValuesTable!.deleteObject(uniqueID: uniqueID, database: database)
			}
		}
		else if let tableObject = object as? ODBTable {
			let uniqueID = tableObject.uniqueID
			queue.update { (database) in
				self.odbTablesTable!.deleteTable(uniqueID: uniqueID, database: database)
			}
		}
		else {
			preconditionFailure("deleteObject: object neither ODBValueObject or ODBTable")
		}
	}

	func deleteChildren(of table: ODBTable) throws {

		try preflightCall()

		let parentUniqueID = table.uniqueID
		queue.update { (database) in
			self.odbTablesTable!.deleteChildTables(parentUniqueID: parentUniqueID, database: database)
			self.odbValuesTable!.deleteChildObjects(parentUniqueID: parentUniqueID, database: database)
		}
	}

	func insertTable(name: String, parent: ODBTable) throws -> ODBTable {

		try preflightCall()

		var table: ODBTable? = nil
		queue.fetchSync { (database) in
			table = self.odbTablesTable!.insertTable(name: name, parentTable: parent, odb: self, database: database)
		}
		return table!
	}

	func insertValueObject(name: String, value: ODBValue, parent: ODBTable) throws -> ODBValueObject {

		try preflightCall()

		var valueObject: ODBValueObject? = nil
		queue.updateSync { (database) in
			valueObject = self.odbValuesTable!.insertValueObject(name: name, value: value, parentTable: parent, database: database)
		}

		return valueObject!
	}

	func fetchChildren(of table: ODBTable) throws -> ODBDictionary {

		try preflightCall()

		var children = ODBDictionary()

		queue.fetchSync { (database) in

			let tables = self.odbTablesTable!.fetchSubtables(of: table, database: database, odb: self)
			let valueObjects = self.odbValuesTable!.fetchValueObjects(of: table, database: database)

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

private extension ODB {

	static let tableCreationStatements = """
	CREATE TABLE if not EXISTS odb_tables (id INTEGER PRIMARY KEY AUTOINCREMENT, parent_id INTEGER NOT NULL, name TEXT NOT NULL);

	CREATE TABLE if not EXISTS odb_values (id INTEGER PRIMARY KEY AUTOINCREMENT, odb_table_id INTEGER NOT NULL, name TEXT NOT NULL, primitive_type INTEGER NOT NULL, application_type TEXT, value BLOB);

	CREATE INDEX if not EXISTS odb_tables_parent_id_index on odb_tables (parent_id);
	CREATE INDEX if not EXISTS odb_values_odb_table_id_index on odb_values (odb_table_id);

	CREATE TRIGGER if not EXISTS odb_tables_after_delete_trigger_delete_subtables after delete on odb_tables begin delete from odb_tables where parent_id = OLD.id; end;
	CREATE TRIGGER if not EXISTS odb_tables_after_delete_trigger_delete_child_values after delete on odb_tables begin delete from odb_values where odb_table_id = OLD.id; end;
	"""
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
