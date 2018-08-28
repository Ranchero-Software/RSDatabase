//
//  ODBError.swift
//  RSDatabase
//
//  Created by Brent Simmons on 8/26/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

public enum ODBError: Error {
	case undefined(path: ODBPath)
	case notATable(path: ODBPath)
	case notAValue(path: ODBPath)
	case invalidDataType(rawValue: Any)
	case odbClosed(filePath: String)
	case illegalOperationOnRootTable(path: ODBPath)
}
