//
//  ODBTests.swift
//  RSDatabaseTests
//
//  Created by Brent Simmons on 8/27/18.
//  Copyright © 2018 Ranchero Software, LLC. All rights reserved.
//

import XCTest
import RSDatabase

class ODBTests: XCTestCase {

	func testODBCreation() {
		let f = pathForTestFile(name: "Test.odb")
		var odb: ODB? = ODB(filepath: f)
		odb!.close()
		odb = nil
		try! FileManager.default.removeItem(atPath: f)
	}


}

private extension ODBTests {

	func desktopFolderPath() -> String {
		let paths = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)
		let folder = paths[0]
		return folder.path
	}

	func pathForTestFile(name: String) -> String {
		let folder = desktopFolderPath()
		return (folder as NSString).appendingPathComponent(name)
	}
}
