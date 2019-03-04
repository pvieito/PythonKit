import XCTest

import PythonKitTests

var tests = [XCTestCaseEntry]()
tests += PythonKitTests.__allTests()

XCTMain(tests)
