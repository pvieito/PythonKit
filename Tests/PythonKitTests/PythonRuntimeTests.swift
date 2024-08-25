import XCTest
import PythonKit

class PythonRuntimeTests: XCTestCase {
    func testCheckVersion() {
        XCTAssertGreaterThanOrEqual(Python.versionInfo.major, 2)
        XCTAssertGreaterThanOrEqual(Python.versionInfo.minor, 0)
    }

    func testPythonList() {
        let list: PythonObject = [0, 1, 2]
        XCTAssertEqual("[0, 1, 2]", list.description)
        XCTAssertEqual(3, Python.len(list))
        XCTAssertEqual("[0, 1, 2]", Python.str(list))

        let polymorphicList = PythonObject(["a", 2, true, 1.5])
        XCTAssertEqual("a", polymorphicList[0])
        XCTAssertEqual(2, polymorphicList[1])
        XCTAssertEqual(true, polymorphicList[2])
        XCTAssertEqual(1.5, polymorphicList[3])
        XCTAssertEqual(1.5, polymorphicList[-1])

        XCTAssertEqual(4, polymorphicList.count as Int)
        XCTAssertEqual(4, polymorphicList.checking.count!)
        XCTAssertEqual(4, polymorphicList.throwing.count!)

        polymorphicList[2] = 2
        XCTAssertEqual(2, polymorphicList[2])
    }

    #if !os(Windows)
    func testPythonDict() {
        let dict: PythonObject = ["a": 1, 1: 0.5]
        XCTAssertEqual(2, Python.len(dict))
        XCTAssertEqual(1, dict["a"])
        XCTAssertEqual(0.5, dict[1])

        XCTAssertEqual(2, dict.count as Int)
        XCTAssertEqual(2, dict.checking.count!)
        XCTAssertEqual(2, dict.throwing.count!)

        dict["b"] = "c"
        XCTAssertEqual("c", dict["b"])
        dict["b"] = "d"
        XCTAssertEqual("d", dict["b"])

        // Dictionary initializer patch does not work on Python 2, but that
        // version is no longer being actively supported.
        guard Python.versionInfo.major >= 3 else {
            return
        }

        // Pandas DataFrame regression test spotted in Jupyter. This is
        // non-deterministic, so repeat it several times to ensure the bug does
        // not appear.
        for _ in 0..<15 {
            let records: [PythonObject] = [
                ["col 1": 3, "col 2": 5],
                ["col 1": 8, "col 2": 2]
            ]
            let records_description =
                "[{'col 1': 3, 'col 2': 5}, {'col 1': 8, 'col 2': 2}]"
            XCTAssertEqual(String(describing: records), records_description)

            let records_alt: [PythonObject] = [
                ["col 1": 3, "col 2": 5, "col 3": 4],
                ["col 1": 8, "col 2": 2, "col 3": 4]
            ]
            let records_alt_description =
                "[{'col 1': 3, 'col 2': 5, 'col 3': 4}, {'col 1': 8, 'col 2': 2, 'col 3': 4}]"
            XCTAssertEqual(String(describing: records_alt), records_alt_description)
        }
    }

    func testRange() {
        let slice = PythonObject(5..<10)
        XCTAssertEqual(Python.slice(5, 10), slice)
        XCTAssertEqual(5, slice.start)
        XCTAssertEqual(10, slice.stop)

        let range = Range<Int>(slice)
        XCTAssertNotNil(range)
        XCTAssertEqual(5, range?.lowerBound)
        XCTAssertEqual(10, range?.upperBound)

        XCTAssertNil(Range<Int>(PythonObject(5...)))
    }

    func testPartialRangeFrom() {
        let slice = PythonObject(5...)
        XCTAssertEqual(Python.slice(5, Python.None), slice)
        XCTAssertEqual(5, slice.start)

        let range = PartialRangeFrom<Int>(slice)
        XCTAssertNotNil(range)
        XCTAssertEqual(5, range?.lowerBound)

        XCTAssertNil(PartialRangeFrom<Int>(PythonObject(..<5)))
    }

    func testPartialRangeUpTo() {
        let slice = PythonObject(..<5)
        XCTAssertEqual(Python.slice(5), slice)
        XCTAssertEqual(5, slice.stop)

        let range = PartialRangeUpTo<Int>(slice)
        XCTAssertNotNil(range)
        XCTAssertEqual(5, range?.upperBound)

        XCTAssertNil(PartialRangeUpTo<Int>(PythonObject(5...)))
    }
    #endif

    func testStrideable() {
        let strideTo = stride(from: PythonObject(0), to: 100, by: 2)
        XCTAssertEqual(0, strideTo.min()!)
        XCTAssertEqual(98, strideTo.max()!)
        XCTAssertEqual([0, 2, 4, 6, 8], Array(strideTo.prefix(5)))
        XCTAssertEqual([90, 92, 94, 96, 98], Array(strideTo.suffix(5)))

        let strideThrough = stride(from: PythonObject(0), through: 100, by: 2)
        XCTAssertEqual(0, strideThrough.min()!)
        XCTAssertEqual(100, strideThrough.max()!)
        XCTAssertEqual([0, 2, 4, 6, 8], Array(strideThrough.prefix(5)))
        XCTAssertEqual([92, 94, 96, 98, 100], Array(strideThrough.suffix(5)))
    }

    func testBinaryOps() {
        XCTAssertEqual(42, PythonObject(42))
        XCTAssertEqual(42, PythonObject(2) + PythonObject(40))
        XCTAssertEqual(2, PythonObject(2) * PythonObject(3) + PythonObject(-4))

        XCTAssertEqual("abcdef", PythonObject("ab") +
            PythonObject("cde") +
            PythonObject("") +
            PythonObject("f"))
        XCTAssertEqual("ababab", PythonObject("ab") * 3)

        var x = PythonObject(2)
        x += 3
        XCTAssertEqual(5, x)
        x *= 2
        XCTAssertEqual(10, x)
        x -= 3
        XCTAssertEqual(7, x)
        x /= 2
        XCTAssertEqual(3.5, x)
        x += -1
        XCTAssertEqual(2.5, x)
    }

    func testUnaryOps() {
        var x = PythonObject(5)
        x = -x
        XCTAssertEqual(-5, x)
        x = PythonObject(-5)
        x = -x
        XCTAssertEqual(5, x)
    }

    func testComparable() {
        let array: [PythonObject] = [-1, 10, 1, 0, 0]
        XCTAssertEqual([-1, 0, 0, 1, 10], array.sorted())
        let list: PythonObject = [-1, 10, 1, 0, 0]
        XCTAssertEqual([-1, 0, 0, 1, 10], list.sorted())
    }

    #if !os(Windows)
    func testHashable() {
        func compareHashValues(_ x: PythonConvertible) {
            let a = x.pythonObject
            let b = x.pythonObject
            XCTAssertEqual(a.hashValue, b.hashValue)
        }

        compareHashValues(1)
        compareHashValues(3.14)
        compareHashValues("asdf")
        compareHashValues(PythonObject(tupleOf: 1, 2, 3))
    }
    #endif

    func testRangeIteration() {
        for (index, val) in Python.range(5).enumerated() {
            XCTAssertEqual(PythonObject(index), val)
        }
    }

    func testErrors() {
        XCTAssertThrowsError(
            try PythonObject(1).__truediv__.throwing.dynamicallyCall(withArguments: 0)
        ) {
            guard case let PythonError.exception(exception, _) = $0 else {
                XCTFail("non-Python error: \($0)")
                return
            }
            XCTAssertEqual(exception.__class__.__name__, "ZeroDivisionError")
        }
    }

    #if !os(Windows)
    func testTuple() {
        let element1: PythonObject = 0
        let element2: PythonObject = "abc"
        let element3: PythonObject = [0, 0]
        let element4: PythonObject = ["a": 0, "b": "c"]
        let pair = PythonObject(tupleOf: element1, element2)
        let (pair1, pair2) = pair.tuple2
        XCTAssertEqual(element1, pair1)
        XCTAssertEqual(element2, pair2)

        let triple = PythonObject(tupleOf: element1, element2, element3)
        let (triple1, triple2, triple3) = triple.tuple3
        XCTAssertEqual(element1, triple1)
        XCTAssertEqual(element2, triple2)
        XCTAssertEqual(element3, triple3)

        let quadruple = PythonObject(tupleOf: element1, element2, element3, element4)
        let (quadruple1, quadruple2, quadruple3, quadruple4) = quadruple.tuple4
        XCTAssertEqual(element1, quadruple1)
        XCTAssertEqual(element2, quadruple2)
        XCTAssertEqual(element3, quadruple3)
        XCTAssertEqual(element4, quadruple4)

        XCTAssertEqual(element2, quadruple[1])
    }
    #endif

    func testMethodCalling() {
        let list: PythonObject = [1, 2]
        list.append(3)
        XCTAssertEqual([1, 2, 3], list)

        // Check method binding.
        let append = list.append
        append(4)
        XCTAssertEqual([1, 2, 3, 4], list)

        // Check *args/**kwargs behavior: `str.format(*args, **kwargs)`.
        let greeting: PythonObject = "{0} {first} {last}!"
        XCTAssertEqual("Hi John Smith!",
                       greeting.format("Hi", first: "John", last: "Smith"))
        XCTAssertEqual("Hey Jane Doe!",
                       greeting.format("Hey", first: "Jane", last: "Doe"))
    }

    func testConvertibleFromPython() {
        // Ensure that we cover the -1 case as this is used by Python
        // to signal conversion errors.
        let minusOne: PythonObject = -1
        let zero: PythonObject = 0
        let five: PythonObject = 5
        let half: PythonObject = 0.5
        let string: PythonObject = "abc"

        #if !os(Windows)
        XCTAssertEqual(-1, Int(minusOne))
        XCTAssertEqual(-1, Int8(minusOne))
        XCTAssertEqual(-1, Int16(minusOne))
        XCTAssertEqual(-1, Int32(minusOne))
        XCTAssertEqual(-1, Int64(minusOne))
        #endif
        XCTAssertEqual(-1.0, Float(minusOne))
        XCTAssertEqual(-1.0, Double(minusOne))

        XCTAssertEqual(0, Int(zero))
        XCTAssertEqual(0.0, Double(zero))

        XCTAssertEqual(5, UInt(five))
        XCTAssertEqual(5, UInt8(five))
        XCTAssertEqual(5, UInt16(five))
        XCTAssertEqual(5, UInt32(five))
        XCTAssertEqual(5, UInt64(five))
        XCTAssertEqual(5.0, Float(five))
        XCTAssertEqual(5.0, Double(five))

        XCTAssertEqual(0.5, Float(half))
        XCTAssertEqual(0.5, Double(half))
        // Python rounds down in this case.
        // XCTAssertEqual(0, Int(half))

        XCTAssertEqual("abc", String(string))

        XCTAssertNil(String(zero))
        #if !os(Windows)
        XCTAssertNil(Int(string))
        #endif
        XCTAssertNil(Double(string))
    }

    func testPythonConvertible() {
        let minusOne: PythonObject = -1
        let five: PythonObject = 5

        XCTAssertEqual(minusOne, Int(-1).pythonObject)
        XCTAssertEqual(minusOne, Int8(-1).pythonObject)
        XCTAssertEqual(minusOne, Int16(-1).pythonObject)
        XCTAssertEqual(minusOne, Int32(-1).pythonObject)
        XCTAssertEqual(minusOne, Int64(-1).pythonObject)
        XCTAssertEqual(minusOne, Float(-1).pythonObject)
        XCTAssertEqual(minusOne, Double(-1).pythonObject)

        XCTAssertEqual(five, UInt(5).pythonObject)
        XCTAssertEqual(five, UInt8(5).pythonObject)
        XCTAssertEqual(five, UInt16(5).pythonObject)
        XCTAssertEqual(five, UInt32(5).pythonObject)
        XCTAssertEqual(five, UInt64(5).pythonObject)
        XCTAssertEqual(five, Float(5).pythonObject)
        XCTAssertEqual(five, Double(5).pythonObject)
    }

    // SR-9230: https://bugs.swift.org/browse/SR-9230
    func testSR9230() {
      let pythonDict = Python.dict(a: "a", b: "b")
      XCTAssertEqual(Python.len(pythonDict), 2)
    }

    // TF-78: isType() consumed refcount for type objects like `PyBool_Type`.
    func testPythonRefCount() {
        let b: PythonObject = true
        for _ in 0...20 {
            // This triggers isType(), which used to crash after repeated invocation
            // because of reduced refcount for `PyBool_Type`.
            _ = Bool.init(b)
        }
    }

    func testPythonBytes() {
        let bytes = PythonBytes([UInt8(1), UInt8(2), UInt8(3), UInt8(4)])
        bytes.withUnsafeBytes {
            XCTAssertEqual(Array($0), [1, 2, 3, 4])
        }
    }

    func testPythonBytesInt8() {
        let bytes = PythonBytes([Int8(1), Int8(2), Int8(3), Int8(4)])
        bytes.withUnsafeBytes {
            XCTAssertEqual(Array($0), [1, 2, 3, 4])
        }
    }

    func testPythonBytesNonContiguousSequence() {
        let bytes = PythonBytes(CollectionOfOne(UInt8(1)))
        bytes.withUnsafeBytes {
            XCTAssertEqual(Array($0), [1])
        }
    }

    func testPythonBytesNonContiguousSequenceInt8() {
        let bytes = PythonBytes(CollectionOfOne(Int8(1)))
        bytes.withUnsafeBytes {
            XCTAssertEqual(Array($0), [1])
        }
    }

    func testBytesConversion() {
        let bytes = PythonBytes(CollectionOfOne(UInt8(1)))
        let otherBytes = PythonBytes(bytes.pythonObject)
        otherBytes?.withUnsafeBytes {
            XCTAssertEqual(Array($0), [1])
        }
        XCTAssertEqual(bytes, otherBytes)
    }

    /// Tests an emulation of the Python `with` statement.
    ///
    /// Mirrors:
    /// ```python
    /// with open('temp', 'w') as opened_file:
    ///      opened_file.write('Contents')
    /// with open('temp', 'r') as opened_file:
    ///      contents = opened_file.read()
    /// ```
    func testWith() {
        Python.with(Python.open("temp", "w")) { opened_file in
            opened_file.write("Contents")
        }
        Python.with(Python.open("temp", "r")) { opened_file in
            let contents = opened_file.read()
            XCTAssertEqual("Contents", String(contents)!)
        }
    }
}
