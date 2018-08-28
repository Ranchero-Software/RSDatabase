//
//  ODBTableValueLookup.swift
//  RSDatabase
//
//  Created by Brent Simmons on 8/26/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

// Convenience to get/set values (ODBValue) in a table.
// You can keep a reference to this object.

public struct ODBTableValueLookup {

	public let path: ODBPath
	public let odb: ODB

	public func value(for name: String) throws -> ODBValue {
		return try path.value(with: odb)
	}

	public func setValue(_ value: ODBValue, for name: String) throws {
		let childPath = path + name
		try childPath.setValue(value, odb: odb)
	}

	public func rawValue(for name: String) throws -> Any {
		return try value(for: name).rawValue
	}

	public func setRawValue(_ rawValue: Any, for name: String) throws {
		guard let value = ODBValue(rawValue: rawValue) else {
			throw ODBError.invalidDataType(rawValue: rawValue)
		}
		try setValue(value, for: name)
	}
}

