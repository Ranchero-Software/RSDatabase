//
//  ODBValue.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/24/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

public struct ODBValue: Equatable {

	public enum PrimitiveType: Int {
		case boolean
		case integer
		case double
		case date
		case string
		case data
	}

	let value: Any
	let primitiveType: PrimitiveType
	let applicationType: String? // Application-defined

	init(value: Any, primitiveType: PrimitiveType, applicationType: String?) {

		self.value = value
		self.primitiveType = primitiveType
		self.applicationType = applicationType
	}

	public static func ==(lhs: ODBValue, rhs: ODBValue) -> Bool {

		if lhs.primitiveType != rhs.primitiveType || lhs.applicationType != rhs.applicationType {
			return false
		}

		switch lhs.primitiveType {
		case boolean:
			compareBooleans(lhs.value, rhs.value)
		case integer:
			compareIntegers(lhs.value, rhs.value)
		case double:
			compareDoubles(lhs.value, rhs.value)
		case string:
			compareStrings(lhs.value, rhs.value)
		case data:
			compareData(lhs.value, rhs.value)
		case date:
			compareDates(lhs.value, rhs.value)
		}
	}
}

private extension ODBValue {

	func compareBooleans(_ left: Any, _ right: Any) -> Bool {


	}

	func compareIntegers(_ left: Any, _ right: Any) -> Bool {


	}

	func compareDoubles(_ left: Any, _ right: Any) -> Bool {


	}

	func compareStrings(_ left: Any, _ right: Any) -> Bool {


	}

	func compareData(_ left: Any, _ right: Any) -> Bool {


	}

	func compareDates(_ left: Any, _ right: Any) -> Bool {

	}
}
