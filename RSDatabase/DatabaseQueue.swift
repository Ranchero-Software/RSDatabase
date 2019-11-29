//
//  DatabaseQueue.swift
//  RSDatabase
//
//  Created by Brent Simmons on 11/13/19.
//  Copyright © 2019 Brent Simmons. All rights reserved.
//

import Foundation
import SQLite3

public typealias DatabaseBlock = (FMDatabase) -> Void

/// This manages a serial queue and a SQLite database.
/// It replaces RSDatabaseQueue, which is deprecated.

public final class DatabaseQueue {

	/// Check to see if the queue is suspended. Read-only.
	/// Calling suspend() and resume() will change the value of this property.
	public var isSuspended: Bool {
		return _isSuspended
	}

	private var _isSuspended = true
	private var isCallingDatabase = false
	private let database: FMDatabase
	private let databasePath: String
	private let serialDispatchQueue: DispatchQueue

	/// When init returns, the database will not be suspended: it will be ready for database calls.
	public init(databasePath: String, excludeFromBackup: Bool = false) {
		self.serialDispatchQueue = DispatchQueue(label: "DatabaseQueue - \(databasePath)")
		self.databasePath = databasePath
		self.database = FMDatabase(path: databasePath)!

		if excludeFromBackup {
			var databaseURL = URL(fileURLWithPath: databasePath, isDirectory: false)
			var resourceValues = URLResourceValues()
			resourceValues.isExcludedFromBackup = true
			try? databaseURL.setResourceValues(resourceValues)
		}

		resume()
	}

	// MARK: - Suspend and Resume

	/// Close the SQLite database and don’t allow database calls until resumed.
	/// This is for iOS, where we need to close the SQLite database in some conditions.
	/// After calling suspend, if you call into the database before calling resume, the app will crash.
	/// This is by design.
	public func suspend() {
		guard !isSuspended else {
			return
		}
		runInDatabaseSync{ database in
			database.close()
			_isSuspended = true
		}
	}

	/// Open the SQLite database. Allow database calls again.
	/// This is also for iOS.
	public func resume() {
		guard isSuspended else {
			return
		}
		database.open()
		database.executeStatements("PRAGMA synchronous = 1;")
		database.setShouldCacheStatements(true)
		_isSuspended = false
	}

	// MARK: - Make Database Calls

	// These will crash if the queue is suspended. This is by design.
	// Do not call these if the database is suspended.

	/// Run a DatabaseBlock synchronously. This call will block the main thread
	/// potentially for a while, depending on how long it takes to execute
	/// the DatabaseBlock *and* depending on how many other calls have been
	/// scheduled on the queue. Use sparingly — prefer async versions.
	public func runInDatabaseSync(_ databaseBlock: DatabaseBlock) {
		serialDispatchQueue.sync {
			self._runInDatabase(self.database, databaseBlock, false)
		}
	}

	/// Run a DatabaseBlock asynchronously.
	public func runInDatabase(_ databaseBlock: @escaping DatabaseBlock) {
		serialDispatchQueue.async {
			self._runInDatabase(self.database, databaseBlock, false)
		}
	}

	/// Run a DatabaseBlock wrapped in a transaction asynchronously.
	/// Transactions help performance significantly when updating the database.
	public func runInTransaction(_ databaseBlock: @escaping DatabaseBlock) {
		serialDispatchQueue.async {
			self._runInDatabase(self.database, databaseBlock, true)
		}
	}

	/// Run all the lines that start with "create".
	/// Use this to create tables, indexes, etc.
	public func runCreateStatements(_ statements: String) {
		runInDatabase { database in
			statements.enumerateLines { (line, stop) in
				if line.lowercased().hasPrefix("create") {
					database.executeStatements(line)
				}
				stop = false
			}
		}
	}

	/// Compact the database. This should be done from time to time —
	/// weekly-ish? — to keep up the performance level of a database.
	/// Generally a thing to do at startup, if it’s been a while
	/// since the last vacuum() call. You almost certainly want to call
	/// vacuumIfNeeded instead.
	public func vacuum() {
		runInDatabase { database in
			database.executeStatements("vacuum;")
		}
	}

	/// Vacuum the database if it’s been more than daysBetweenVacuums since the last vacuum.
	/// Normally you would call this right after initing a DatabaseQueue.
	public func vacuumIfNeeded(daysBetweenVacuums: Int) {
		let defaultsKey = "DatabaseQueue-LastVacuumDate-\(databasePath)"
		let minimumVacuumInterval = TimeInterval(daysBetweenVacuums * (60 * 60 * 24)) // Doesn’t have to be precise
		let now = Date()
		let cutoffDate = now - minimumVacuumInterval
		if let lastVacuumDate = UserDefaults.standard.object(forKey: defaultsKey) as? Date {
			if lastVacuumDate < cutoffDate {
				vacuum()
				UserDefaults.standard.set(now, forKey: defaultsKey)
			}
			return
		}

		// Never vacuumed — almost certainly a new database.
		// Just set the LastVacuumDate pref to now and skip vacuuming.
		UserDefaults.standard.set(now, forKey: defaultsKey)
	}
}

private extension DatabaseQueue {

	func _runInDatabase(_ database: FMDatabase, _ databaseBlock: DatabaseBlock, _ useTransaction: Bool) {
		precondition(!isCallingDatabase)
		precondition(!isSuspended)
		isCallingDatabase = true
		autoreleasepool {
			if useTransaction {
				database.beginTransaction()
			}
			databaseBlock(database)
			if useTransaction {
				database.commit()
			}
		}
		isCallingDatabase = false
	}
}
