//
//  ODBObject.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/24/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

public typealias ODBDictionary = [String: ODBObject]

public protocol ODBObject {

	var name: String { get }
	var isTable: Bool { get }
	var isRootTable: Bool { get }
	var parentTable: ODBTable? { get }
	var path: ODBPath? { get }
	func delete()
}
