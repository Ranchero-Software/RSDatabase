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
	private var cache = [ODBPath: Any]()
	private let rootTable = ODBTable(databaseID: -1, parentTableID: nil, isRoot: true, scalars: nil)

	private static let tableCreationStatements = """
	CREATE TABLE if not EXISTS odb_tables (id INTEGER PRIMARY KEY AUTOINCREMENT, parent_id INTEGER, name TEXT NOT NULL, scalars TEXT);

	CREATE TABLE if not EXISTS odb_objects (id INTEGER PRIMARY KEY AUTOINCREMENT, odb_table_id INTEGER, name TEXT NOT NULL, type TEXT NOT NULL, value BLOB);
	"""

	public static let rootTableName = "root"
	
	private let _lock = NSLock()

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
		// Returns ODBTable, ODBObject, or a scalar value.

		lock()
		defer {
			unlock()
		}

		if let cachedObject = cache[path] {
			return cachedObject
		}

		guard let parent = _parentTable(for: path) else {
			return nil
		}

		if let scalar = parent.scalar(for: path.name) {
			cache[path] = scalar
			return scalar
		}
		if let table = table(for: path) {
			cache[path] = table
			return table
		}
		if let object = object(for: path) {
			cache[path] = object
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

		emptyCache()

		return false
	}

	public func setItem(item: Any, at path: ODBPath) throws {

		lock()
		defer {
			unlock()
		}

		if item is ODBTable {
			emptyCache()
		}
		cache[path] = item
	}

	public func move(item: Any, toTableAtPath: ODBPath) throws {

		lock()
		defer {
			unlock()
		}

		emptyCache()
	}

}

private extension ODB {

	func lock() {
		_lock.lock()
	}

	func unlock() {
		_lock.unlock()
	}

	func emptyCache() {

		cache.removeAll()
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
