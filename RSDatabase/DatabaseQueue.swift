//
//  DatabaseQueue.swift
//  RSDatabase
//
//  Created by Brent Simmons on 11/13/19.
//  Copyright © 2019 Brent Simmons. All rights reserved.
//

import Foundation
import SQLite3

public enum DatabaseQueueError: Error {
	case isSuspended
}

public typealias DatabaseQueueResult = Result<FMDatabase, DatabaseQueueError>

public extension DatabaseQueueResult {
	/// Convenience for getting the database from a DatabaseQueueResult.
	var database: FMDatabase? {
		switch self {
		case .success(let database):
			return database
		case .failure:
			return nil
		}
	}

	/// Convenience for getting the error from a DatabaseQueueResult.
	var error: DatabaseQueueError? {
		switch self {
		case .success:
			return nil
		case .failure(let error):
			return error
		}
	}
}

/// Block that executes database code or handles DatabaseQueueError.
public typealias DatabaseBlock = (DatabaseQueueResult) -> Void

/// Manage a serial queue and a SQLite database.
/// It replaces RSDatabaseQueue, which is deprecated.
/// Main-thread only.
/// Important note: on iOS, the queue can be suspended
/// in order to support background refreshing.
public final class DatabaseQueue {

	/// Check to see if the queue is suspended. Read-only.
	/// Calling suspend() and resume() will change the value of this property.
	/// This will return true only on iOS — on macOS it’s always false.
	public var isSuspended: Bool {
		#if os(iOS)
		precondition(Thread.isMainThread)
		return _isSuspended
		#else
		return false
		#endif
	}

	private var _isSuspended = true
	private var isCallingDatabase = false
	private let database: FMDatabase
	private let databasePath: String
	private let serialDispatchQueue: DispatchQueue

	/// When init returns, the database will not be suspended: it will be ready for database calls.
	public init(databasePath: String) {
		precondition(Thread.isMainThread)
		self.serialDispatchQueue = DispatchQueue(label: "DatabaseQueue - \(databasePath)")
		self.databasePath = databasePath
		self.database = FMDatabase(path: databasePath)!
		openDatabase()
		_isSuspended = false
	}

	// MARK: - Suspend and Resume

	/// Close the SQLite database and don’t allow database calls until resumed.
	/// This is for iOS, where we need to close the SQLite database in some conditions.
	///
	/// After calling suspend, if you call into the database before calling resume,
	/// your code will not run, and runInDatabaseSync and runInTransactionSync will
	/// both throw DatabaseQueueError.isSuspended.
	///
	/// On Mac, suspend() and resume() are no-ops, since there isn’t a need for them.
	public func suspend() {
		#if os(iOS)
		precondition(Thread.isMainThread)
		runInDatabaseSync{ result in
			result.database?.close()
			_isSuspended = true
		}
		#endif
	}

	/// Open the SQLite database. Allow database calls again.
	/// This is also for iOS.
	public func resume() {
		#if os(iOS)
		precondition(Thread.isMainThread)
		serialDispatchQueue.sync {
			if _isSuspended {
				openDatabase()
				_isSuspended = false
			}
		}
		#endif
	}

	// MARK: - Make Database Calls

	/// Run a DatabaseBlock synchronously. This call will block the main thread
	/// potentially for a while, depending on how long it takes to execute
	/// the DatabaseBlock *and* depending on how many other calls have been
	/// scheduled on the queue. Use sparingly — prefer async versions.
	public func runInDatabaseSync(_ databaseBlock: DatabaseBlock) {
		precondition(Thread.isMainThread)
		serialDispatchQueue.sync {
			self._runInDatabase(self.database, databaseBlock, false)
		}
	}

	/// Run a DatabaseBlock asynchronously.
	public func runInDatabase(_ databaseBlock: @escaping DatabaseBlock) {
		precondition(Thread.isMainThread)
		serialDispatchQueue.async {
			self._runInDatabase(self.database, databaseBlock, false)
		}
	}

	/// Run a DatabaseBlock wrapped in a transaction synchronously.
	/// Transactions help performance significantly when updating the database.
	/// Nevertheless, it’s best to avoid this because it will block the main thread —
	/// prefer the async `runInTransaction` instead.
	public func runInTransactionSync(_ databaseBlock: @escaping DatabaseBlock) {
		precondition(Thread.isMainThread)
		serialDispatchQueue.sync {
			self._runInDatabase(self.database, databaseBlock, true)
		}
	}

	/// Run a DatabaseBlock wrapped in a transaction asynchronously.
	/// Transactions help performance significantly when updating the database.
	public func runInTransaction(_ databaseBlock: @escaping DatabaseBlock) {
		precondition(Thread.isMainThread)
		serialDispatchQueue.async {
			self._runInDatabase(self.database, databaseBlock, true)
		}
	}

	/// Run all the lines that start with "create".
	/// Use this to create tables, indexes, etc.
	public func runCreateStatements(_ statements: String) throws {
		precondition(Thread.isMainThread)
		var error: DatabaseQueueError? = nil
		runInDatabaseSync { result in
			switch result {
			case .success(let database):
				statements.enumerateLines { (line, stop) in
					if line.lowercased().hasPrefix("create") {
						database.executeStatements(line)
					}
					stop = false
				}
			case .failure(let databaseError):
				error = databaseError
			}
		}
		if let error = error {
			throw(error)
		}
	}

	/// Compact the database. This should be done from time to time —
	/// weekly-ish? — to keep up the performance level of a database.
	/// Generally a thing to do at startup, if it’s been a while
	/// since the last vacuum() call. You almost certainly want to call
	/// vacuumIfNeeded instead.
	public func vacuum() {
		precondition(Thread.isMainThread)
		runInDatabase { result in
			result.database?.executeStatements("vacuum;")
		}
	}

	/// Vacuum the database if it’s been more than `daysBetweenVacuums` since the last vacuum.
	/// Normally you would call this right after initing a DatabaseQueue.
	///
	/// - Returns: true if database will be vacuumed.
	@discardableResult
	public func vacuumIfNeeded(daysBetweenVacuums: Int) -> Bool {
		precondition(Thread.isMainThread)
		let defaultsKey = "DatabaseQueue-LastVacuumDate-\(databasePath)"
		let minimumVacuumInterval = TimeInterval(daysBetweenVacuums * (60 * 60 * 24)) // Doesn’t have to be precise
		let now = Date()
		let cutoffDate = now - minimumVacuumInterval
		if let lastVacuumDate = UserDefaults.standard.object(forKey: defaultsKey) as? Date {
			if lastVacuumDate < cutoffDate {
				vacuum()
				UserDefaults.standard.set(now, forKey: defaultsKey)
				return true
			}
			return false
		}

		// Never vacuumed — almost certainly a new database.
		// Just set the LastVacuumDate pref to now and skip vacuuming.
		UserDefaults.standard.set(now, forKey: defaultsKey)
		return false
	}
}

private extension DatabaseQueue {

	func _runInDatabase(_ database: FMDatabase, _ databaseBlock: DatabaseBlock, _ useTransaction: Bool) {
		precondition(!isCallingDatabase)
		isCallingDatabase = true
		autoreleasepool {
			if _isSuspended {
				databaseBlock(.failure(.isSuspended))
			}
			else {
				if useTransaction {
					database.beginTransaction()
				}
				databaseBlock(.success(database))
				if useTransaction {
					database.commit()
				}
			}
		}
		isCallingDatabase = false
	}

	func openDatabase() {
		database.open()
		database.executeStatements("PRAGMA synchronous = 1;")
		database.setShouldCacheStatements(true)
	}
}
