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

	public let value: Any
	public let primitiveType: PrimitiveType
	public let applicationType: String? // Application-defined

	private static let trueValue = ODBValue(value: true, primitiveType: .boolean)
	private static let falseValue = ODBValue(value: false, primitiveType: .boolean)
	private static var integerValueCache = [Int: ODBValue]()
	private static let integerValueCacheLock = NSLock()

	public init(value: Any, primitiveType: PrimitiveType, applicationType: String?) {

		self.value = value
		self.primitiveType = primitiveType
		self.applicationType = applicationType
	}

	public init(value: Any, primitiveType: PrimitiveType) {

		self.init(value: value, primitiveType: primitiveType, applicationType: nil)
	}

	public static func bool(_ boolean: Bool) -> ODBValue {

		return boolean ? ODBValue.trueValue : ODBValue.falseValue
	}

	public static func integer(_ integer: Int) -> ODBValue {

		integerValueCacheLock.lock()
		defer {
			integerValueCacheLock.unlock()
		}

		if let cachedValue = integerValueCache[integer] {
			return cachedValue
		}
		let value = ODBValue(value: integer, primitiveType: .integer)
		integerValueCache[integer] = value
		return value
	}

	public static func double(_ double: Double) -> ODBValue {

		return ODBValue(value: double, primitiveType: .double)
	}

	public static func date(_ date: Date) -> ODBValue {

		return ODBValue(value: date, primitiveType: .double)
	}

	public static func string(_ string: String) -> ODBValue {

		return ODBValue(value: string, primitiveType: .string)
	}

	public static func data(_ data: Data) -> ODBValue {

		return ODBValue(value: data, primitiveType: .data)
	}

	public static func ==(lhs: ODBValue, rhs: ODBValue) -> Bool {

		if lhs.primitiveType != rhs.primitiveType || lhs.applicationType != rhs.applicationType {
			return false
		}

		switch lhs.primitiveType {
		case .boolean:
			return compareBooleans(lhs.value, rhs.value)
		case .integer:
			return compareIntegers(lhs.value, rhs.value)
		case .double:
			return compareDoubles(lhs.value, rhs.value)
		case .string:
			return compareStrings(lhs.value, rhs.value)
		case .data:
			return compareData(lhs.value, rhs.value)
		case .date:
			return compareDates(lhs.value, rhs.value)
		}
	}
}

private extension ODBValue {

	static func compareBooleans(_ left: Any, _ right: Any) -> Bool {

		guard let left = left as? Bool, let right = right as? Bool else {
			return false
		}
		return left == right
	}

	static func compareIntegers(_ left: Any, _ right: Any) -> Bool {

		guard let left = left as? Int, let right = right as? Int else {
			return false
		}
		return left == right
	}

	static func compareDoubles(_ left: Any, _ right: Any) -> Bool {

		guard let left = left as? Double, let right = right as? Double else {
			return false
		}
		return left == right
	}

	static func compareStrings(_ left: Any, _ right: Any) -> Bool {

		guard let left = left as? String, let right = right as? String else {
			return false
		}
		return left == right
	}

	static func compareData(_ left: Any, _ right: Any) -> Bool {

		guard let left = left as? Data, let right = right as? Data else {
			return false
		}
		return left == right
	}

	static func compareDates(_ left: Any, _ right: Any) -> Bool {

		guard let left = left as? Date, let right = right as? Date else {
			return false
		}
		return left == right
	}
}
