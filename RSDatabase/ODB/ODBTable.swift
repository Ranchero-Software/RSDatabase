//
//  ODBTable.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/21/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

typealias ODBScalarDictionary = [String: Any]

public class ODBTable {

	let databaseID: Int
	let isRoot: Bool
	var parentTableID: Int?
	var scalars: ODBScalarDictionary?

	init(databaseID: Int, parentTableID: Int?, isRoot: Bool, scalars: ODBScalarDictionary?) {

		self.databaseID = databaseID
		self.parentTableID = parentTableID
		self.scalars = scalars
		self.isRoot = isRoot
	}

	func scalar(for name: String) -> Any? {

		guard let scalars = scalars else {
			return nil
		}

		if let value = scalars[name] {
			return value
		}

		let lowerName = name.odbLowercased()
		for (key, value) in scalars {
			if lowerName == key.odbLowercased() {
				return value
			}
		}

		return nil
	}

}
