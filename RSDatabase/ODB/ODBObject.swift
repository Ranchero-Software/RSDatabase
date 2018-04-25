//
//  ODBObject.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/24/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation


protocol ODBObject {

	var name: String { get }
	var isTable: Bool { get }
	var isRootTable: Bool { get }
	var parentTable: ODBTable? { get }
	var path: ODBPath? { get }
	var children: ODBDictionary? { get } // Tables only
	var value: ODBValue? { get } // Value objects only
	func delete()
}
