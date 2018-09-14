//
//  ODBRawValueTable.swift
//  RSDatabase
//
//  Created by Brent Simmons on 9/13/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

// Use this when you’re just getting/setting raw values from a table.

public struct ODBRawValueTable {

	let table: ODBTable

	public subscript(_ name: String) -> Any? {
		get {
			return table.rawValue(name)
		}
		set {
			if let rawValue = newValue {
				table.set(rawValue, name: name)
			}
			else {
				table.delete(name: name)
			}
		}
	}
}
