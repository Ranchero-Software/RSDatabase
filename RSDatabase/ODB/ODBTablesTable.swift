//
//  ODBTablesTable.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/20/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

final class ODBTablesTable: DatabaseTable {

	let name: String
	let queue: RSDatabaseQueue

	init(name: String, queue: RSDatabaseQueue) {

		self.name = name
		self.queue = queue
	}
}
