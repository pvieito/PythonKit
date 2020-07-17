//
//  PythonLambdaTests.swift
//  
//

import XCTest
import PythonKit

class PythonLambdaTests: XCTestCase {
    let pmap = Python.map
    let plist = Python.list
    
    func testCheckVersion() {
        XCTAssertGreaterThanOrEqual(Python.versionInfo.major, 3)
        XCTAssertGreaterThanOrEqual(Python.versionInfo.minor, 7)
    }
    
    func testIntIntLambda() {
        let doubled = plist(pmap( 𝝺{x in x*2},  [-1, 20, 8] ))
        XCTAssertEqual(Array<Int>(doubled), [-2, 40, 16])
    }
    
    func testIntBoolLambda() {
        let even = plist(pmap( 𝝺{(x:Int) in x.isMultiple(of: 3) ? true : false},  [45, 56, 63] ))
        XCTAssertEqual(Array<Bool>(even) , [true, false, true])
    }
    
    func testIntStringLambda() {
        let strs = plist(pmap( 𝝺{(x:Int) in "\(x)"},  [-2,-3,100] ))
        XCTAssertEqual(Array<String>(strs), ["-2", "-3", "100"])
    }
    
    func testObjectStringLambda() {
        let strs = plist(pmap( 𝝺{(x:PythonObject) in "\(x)!!"},  PythonObject(["a", 2, true, 1.5] )))
        
        XCTAssertEqual(Array<String>(strs)!, ["a!!","2!!","True!!","1.5!!"])
    }
    
    func testBoolBoolLambda() {
        let bools = plist(pmap( 𝝺{x in !x},  [true, false, true] ))
        XCTAssertEqual(Array<Bool>(bools), [false, true, false])
    }
    
    func testObjectObjectLambda() {
        let objArray = plist(pmap( 𝝺{(x:PythonObject) in PythonObject([x])},  PythonObject(["a", 2, true, 1.5] )))
        XCTAssertEqual(["a"], objArray[0])
        XCTAssertEqual([2], objArray[1])
        XCTAssertEqual([true], objArray[2])
        XCTAssertEqual([1.5], objArray[3])
    }
    
    func testObjectObject_to_ObjectLambda() {
        let functools = Python.import("functools")
        let preduce = functools[dynamicMember: "reduce"]
        let nums = PythonObject([1,2,3,4,5])
        let reducer = 𝝺 { (x:PythonObject,y:PythonObject) -> PythonObject in PythonObject(Int(x)!+Int(y)!)  }
        
        let result = preduce( reducer, nums )
        
        XCTAssertEqual(15, Int(result)!)
    }
    
    func testLambdaDealloc() {
        let tripler = 𝝺{x in x*3}
        let tripled = plist(pmap( tripler,  [-1, 20, 8] ))
        tripler.dealloc()
        XCTAssertEqual(Array<Int>(tripled), [-3, 60, 24])

    }

    func testAutoDeallocatingLambdas() {
        var countRets = 0
        for _ in 1...10000 {
            // the count is to make sure the compiler doesn't try to cleverly optimize this away
            countRets += (𝝺{ Int($0) } >>> { l in self.plist(self.pmap(l , [3.4, 2.4, 1.2] ))  }).count
        }
        
        XCTAssertEqual(countRets, 30000)
    }
    
    func testStringLambda() {
        let len = PythonStringLambda(lambda: "x:len(x)")
        let results = plist(pmap( len, ["hello","bye",""]))
        XCTAssertEqual(results, [5, 3, 0])
    }
    
    func testExecuteAndStringLambda() {
        Python.execute("""
        def add5(i):
            return (i+5)
        """)

        let fiveAdder = PythonStringLambda(lambda: "i:add5(i)")
        let added = plist(pmap( fiveAdder , [10,12,14] ) )
        
        XCTAssertEqual(added, [15, 17, 19])
    }
}

