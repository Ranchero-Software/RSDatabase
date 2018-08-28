//
//  ODBValue.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/24/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

public struct ODBValue: Hashable {

	public enum PrimitiveType: Int {
		case boolean
		case integer
		case double
		case date
		case string
		case data
	}

	public let rawValue: Any
	public let primitiveType: PrimitiveType
	public let applicationType: String? // Application-defined

	private static let trueValue = ODBValue(rawValue: true, primitiveType: .boolean)
	private static let falseValue = ODBValue(rawValue: false, primitiveType: .boolean)
	private static var integerValueCache = [Int: ODBValue]()
	private static let integerValueCacheLock = NSLock()

	public init(rawValue: Any, primitiveType: PrimitiveType, applicationType: String?) {
		self.rawValue = rawValue
		self.primitiveType = primitiveType
		self.applicationType = applicationType
	}

	public init(rawValue: Any, primitiveType: PrimitiveType) {

		self.init(rawValue: rawValue, primitiveType: primitiveType, applicationType: nil)
	}

	public init?(rawValue: Any) {
		guard let primitiveType = ODBValue.primitiveTypeForRawValue(rawValue) else {
			return nil
		}
		self.init(rawValue: rawValue, primitiveType: primitiveType)
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
		let value = ODBValue(rawValue: integer, primitiveType: .integer)
		integerValueCache[integer] = value
		return value
	}

	public static func double(_ double: Double) -> ODBValue {

		return ODBValue(rawValue: double, primitiveType: .double)
	}

	public static func date(_ date: Date) -> ODBValue {

		return ODBValue(rawValue: date, primitiveType: .double)
	}

	public static func string(_ string: String) -> ODBValue {

		return ODBValue(rawValue: string, primitiveType: .string)
	}

	public static func data(_ data: Data) -> ODBValue {

		return ODBValue(rawValue: data, primitiveType: .data)
	}

	// MARK: - Hashable

	public func hash(into hasher: inout Hasher) {
		if let booleanValue = rawValue as? Bool {
			hasher.combine(booleanValue)
		}
		else if let integerValue = rawValue as? Int {
			hasher.combine(integerValue)
		}
		else if let doubleValue = rawValue as? Double {
			hasher.combine(doubleValue)
		}
		else if let stringValue = rawValue as? String {
			hasher.combine(stringValue)
		}
		else if let dataValue = rawValue as? Data {
			hasher.combine(dataValue)
		}
		else if let dateValue = rawValue as? Date {
			hasher.combine(dateValue)
		}
		
		hasher.combine(primitiveType)
		hasher.combine(applicationType)
	}

	// MARK: - Equatable

	public static func ==(lhs: ODBValue, rhs: ODBValue) -> Bool {

		if lhs.primitiveType != rhs.primitiveType || lhs.applicationType != rhs.applicationType {
			return false
		}

		switch lhs.primitiveType {
		case .boolean:
			return compareBooleans(lhs.rawValue, rhs.rawValue)
		case .integer:
			return compareIntegers(lhs.rawValue, rhs.rawValue)
		case .double:
			return compareDoubles(lhs.rawValue, rhs.rawValue)
		case .string:
			return compareStrings(lhs.rawValue, rhs.rawValue)
		case .data:
			return compareData(lhs.rawValue, rhs.rawValue)
		case .date:
			return compareDates(lhs.rawValue, rhs.rawValue)
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

	static func primitiveTypeForRawValue(_ rawValue: Any) -> ODBValue.PrimitiveType? {

		switch rawValue {
		case is Bool:
			return .boolean
		case is Int:
			return .integer
		case is Double:
			return .double
		case is Date:
			return .date
		case is String:
			return .string
		case is Data:
			return .data
		default:
			return nil
		}
	}
}
