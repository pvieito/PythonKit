import XCTest
import PythonKit

class PythonFunctionTests: XCTestCase {
    private var canUsePythonFunction: Bool {
        let versionMajor = Python.versionInfo.major
        let versionMinor = Python.versionInfo.minor
        return (versionMajor == 3 && versionMinor >= 1) || versionMajor > 3
    }
    
    func testPythonFunction() {
        guard canUsePythonFunction else {
            return
        }
        
        let pythonAdd = PythonFunction { (params: [PythonObject]) in
            let lhs = params[0]
            let rhs = params[1]
            return lhs + rhs
        }.pythonObject
        
        let pythonSum = pythonAdd(2, 3)
        XCTAssertNotNil(Double(pythonSum))
        XCTAssertEqual(pythonSum, 5)
    }
    
    // From https://www.geeksforgeeks.org/create-classes-dynamically-in-python
    func testPythonClassConstruction() {
        guard canUsePythonFunction else {
            return
        }
        
        let constructor = PythonInstanceMethod { (params: [PythonObject]) in
            let `self` = params[0]
            let arg = params[1]
            `self`.constructor_arg = arg
            return Python.None
        }

        // Instead of calling `print`, use this to test what would be output.
        var printOutput: String?

        let displayMethod = PythonInstanceMethod { (params: [PythonObject]) in
            // let `self` = params[0]
            let arg = params[1]
            printOutput = String(arg)
            return Python.None
        }

        let classMethodOriginal = PythonInstanceMethod { (params: [PythonObject]) in
            // let cls = params[0]
            let arg = params[1]
            printOutput = String(arg)
            return Python.None
        }

        // Did not explicitly convert `constructor` or `displayMethod` to PythonObject.
        // This is intentional, as the `PythonClass` initializer should take any
        // `PythonConvertible` and not just `PythonObject`.
        let classMethod = Python.classmethod(classMethodOriginal.pythonObject)

        let Geeks = PythonClass("Geeks", members: [
            // Constructor
            "__init__": constructor,
            
            // Data members
            "string_attribute": "Geeks 4 geeks!",
            "int_attribute": 1706256,
            
            // Member functions
            "func_arg": displayMethod,
            "class_func": classMethod,
        ]).pythonObject
        
        let obj = Geeks("constructor argument")
        XCTAssertEqual(obj.constructor_arg, "constructor argument")
        XCTAssertEqual(obj.string_attribute, "Geeks 4 geeks!")
        XCTAssertEqual(obj.int_attribute, 1706256)

        obj.func_arg("Geeks for Geeks")
        XCTAssertEqual(printOutput, "Geeks for Geeks")

        Geeks.class_func("Class Dynamically Created!")
        XCTAssertEqual(printOutput, "Class Dynamically Created!")
    }
    
    // There is a build error where passing a simple `PythonClass.Members` 
    // literal makes the literal's type ambiguous. It is confused with
    // `[String: PythonObject]`. To fix this error, we add a
    // `@_disfavoredOverload` attribute to the more specific initializer.
    func testPythonClassInitializer() {
        guard canUsePythonFunction else {
            return
        }
        
        let MyClass = PythonClass(
            "MyClass",
            superclasses: [Python.object],
            members: [
              "memberName": "memberValue",
            ]
        ).pythonObject
        
        let memberValue = MyClass().memberName
        XCTAssertEqual(String(memberValue), "memberValue")
    }
    
    func testPythonClassInheritance() {
        guard canUsePythonFunction else {
            return
        }
        
        var helloOutput: String?
        var helloWorldOutput: String?

        // Declare subclasses of `Python.Exception`

        let HelloException = PythonClass(
            "HelloException",
            superclasses: [Python.Exception],
            members: [
                "str_prefix": "HelloException-prefix ",
                
                "__init__": PythonInstanceMethod { (params: [PythonObject]) in
                    let `self` = params[0]
                    let message = "hello \(params[1])"
                    helloOutput = String(message)
                    
                    // Conventional `super` syntax causes problems; use this instead.
                    Python.Exception.__init__(self, message)
                    return Python.None
                },
                
                "__str__": PythonInstanceMethod { (`self`: PythonObject) in
                    return `self`.str_prefix + Python.repr(`self`)
                }
            ]
        ).pythonObject
        
        let HelloWorldException = PythonClass(
            "HelloWorldException",
            superclasses: [HelloException],
            members: [
                "str_prefix": "HelloWorldException-prefix ",
                
                "__init__": PythonInstanceMethod { (params: [PythonObject]) in
                    let `self` = params[0]
                    let message = "world \(params[1])"
                    helloWorldOutput = String(message)
                    
                    `self`.int_param = params[2]
                    
                    // Conventional `super` syntax causes problems; use this instead.
                    HelloException.__init__(self, message)
                    return Python.None
                },
                
                "custom_method": PythonInstanceMethod { (`self`: PythonObject) in
                    return `self`.int_param
                }
            ]
        ).pythonObject
        
        // Test that inheritance works as expected

        let error1 = HelloException("test 1")
        XCTAssertEqual(helloOutput, "hello test 1")
        XCTAssertEqual(Python.str(error1), "HelloException-prefix HelloException('hello test 1')")
        XCTAssertEqual(Python.repr(error1), "HelloException('hello test 1')")
        
        let error2 = HelloWorldException("test 1", 123)
        XCTAssertEqual(helloOutput, "hello world test 1")
        XCTAssertEqual(helloWorldOutput, "world test 1")
        XCTAssertEqual(Python.str(error2), "HelloWorldException-prefix HelloWorldException('hello world test 1')")
        XCTAssertEqual(Python.repr(error2), "HelloWorldException('hello world test 1')")
        XCTAssertEqual(error2.custom_method(), 123)
        XCTAssertNotEqual(error2.custom_method(), "123")
        
        // Test that subclasses behave like Python exceptions

        let testFunction = PythonFunction { (_: [PythonObject]) in
            throw HelloWorldException("EXAMPLE ERROR MESSAGE", 2)
        }.pythonObject
        
        do {
            try testFunction.throwing.dynamicallyCall(withArguments: [])
            XCTFail("testFunction did not throw an error.")
        } catch PythonError.exception(let error, _) {
            guard let description = String(error) else {
                XCTFail("A string could not be created from a HelloWorldException.")
                return
            }
            
            XCTAssertTrue(description.contains("EXAMPLE ERROR MESSAGE"))
            XCTAssertTrue(description.contains("HelloWorldException"))
        } catch {
            XCTFail("Got error that was not a Python exception: \(error.localizedDescription)")
        }
    }
}
