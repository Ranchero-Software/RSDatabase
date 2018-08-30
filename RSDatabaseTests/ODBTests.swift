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
		let odb = genericTestODB()
		closeAndDelete(odb)
	}

	func testSimpleBoolStorage() {
		let odb = genericTestODB()
		let path = ODBPath.path(["testBool"])
		try! path.setRawValue(true, odb: odb)

		XCTAssertEqual(try! path.rawValue(with: odb) as! Bool, true)
		closeAndDelete(odb)
	}

	func testSimpleIntStorage() {
		let odb = genericTestODB()
		let path = ODBPath.path(["TestInt"])
		let intValue = 3487456
		try! path.setRawValue(intValue, odb: odb)

		XCTAssertEqual(try! path.rawValue(with: odb) as! Int, intValue)
		closeAndDelete(odb)
	}

	func testSimpleDoubleStorage() {
		let odb = genericTestODB()
		let path = ODBPath.path(["TestDouble"])
		let doubleValue = 3498.45745
		try! path.setRawValue(doubleValue, odb: odb)

		XCTAssertEqual(try! path.rawValue(with: odb) as! Double, doubleValue)
		closeAndDelete(odb)
	}

	func testReadSimpleBoolPerformance() {
		let odb = genericTestODB()
		let path = ODBPath.path(["TestBool"])
		try! path.setRawValue(true, odb: odb)
		XCTAssertEqual(try! path.rawValue(with: odb) as! Bool, true)

		self.measure {
			let _ = try! path.rawValue(with: odb)
		}
		closeAndDelete(odb)
	}

	func testReadAndCloseAndReadSimpleBool() {
		let f = pathForTestFile("testReadAndCloseAndReadSimpleBool.odb")
		var odb = ODB(filepath: f)
		let path = ODBPath.path(["testBool"])
		try! path.setRawValue(true, odb: odb)

		XCTAssertEqual(try! path.rawValue(with: odb) as! Bool, true)
		odb.close()

		odb = ODB(filepath: f)
		XCTAssertEqual(try! path.rawValue(with: odb) as! Bool, true)
		closeAndDelete(odb)
	}
}

private extension ODBTests {

	func desktopFolderPath() -> String {
		let paths = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)
		let folder = paths[0]
		return folder.path
	}

	func pathForTestFile(_ name: String) -> String {
		let folder = desktopFolderPath()
		return (folder as NSString).appendingPathComponent(name)
	}

	static var databaseFileID = 0;

	func pathForGenericTestFile() -> String {
		ODBTests.databaseFileID += 1
		return pathForTestFile("Test\(ODBTests.databaseFileID).odb")
	}

	func genericTestODB() -> ODB {
		let f = pathForGenericTestFile()
		return ODB(filepath: f)
	}

	func closeAndDelete(_ odb: ODB) {
		odb.close()
		try! FileManager.default.removeItem(atPath: odb.filepath)
	}
}
