//
//  ODBValueObject.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/21/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

public struct ODBValueObject: ODBObject, Equatable {

	let uniqueID: Int
	let parentTableID: Int
	let name: String
	let value: ODBValue

	init(uniqueID: Int, parentTableID: Int, name: String, value: ODBValue) {

		self.uniqueID = uniqueID
		self.parentTableID = parentTableID
		self.name = name
		self.value = value
	}
}
