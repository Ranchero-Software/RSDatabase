//
//  ODBError.swift
//  RSDatabase
//
//  Created by Brent Simmons on 4/21/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import Foundation

public struct ODBError: Error {

	public enum ODBErrorType {

		case undefined
	}

	public let errorType: ODBErrorType
	public let path: ODBPath?

	init(errorType: ODBErrorType, path: ODBPath?) {

		self.errorType = errorType
		self.path = path
	}

	static func undefined(path: ODBPath) -> ODBError {

		return ODBError(errorType: .undefined, path: path)
	}
}
