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

        let pythonAdd = PythonFunction { args in
            let lhs = args[0]
            let rhs = args[1]
            return lhs + rhs
        }.pythonObject

        let pythonSum = pythonAdd(2, 3)
        XCTAssertNotNil(Double(pythonSum))
        XCTAssertEqual(pythonSum, 5)

        // Test function with keyword arguments

        // Since there is no alternative function signature, `args` and `kwargs`
        // can be used without manually stating their type. This differs from
        // the behavior when there are no keywords.
        let pythonSelect = PythonFunction { args, kwargs in
            // NOTE: This may fail on Python versions before 3.6 because they do
            // not preserve order of keyword arguments
            XCTAssertEqual(args[0], true)
            XCTAssertEqual(kwargs[0].key, "y")
            XCTAssertEqual(kwargs[0].value, 2)
            XCTAssertEqual(kwargs[1].key, "x")
            XCTAssertEqual(kwargs[1].value, 3)

            let conditional = Bool(args[0])!
            let xIndex = kwargs.firstIndex(where: { $0.key == "x" })!
            let yIndex = kwargs.firstIndex(where: { $0.key == "y" })!

            return kwargs[conditional ? xIndex : yIndex].value
        }.pythonObject

        let pythonSelectOutput = pythonSelect(true, y: 2, x: 3)
        XCTAssertEqual(pythonSelectOutput, 3)
    }

    // From https://www.geeksforgeeks.org/create-classes-dynamically-in-python
    func testPythonClassConstruction() {
        guard canUsePythonFunction else {
            return
        }

        let constructor = PythonInstanceMethod { args in
            let `self` = args[0]
            `self`.constructor_arg = args[1]
            return Python.None
        }

        // Instead of calling `print`, use this to test what would be output.
        var printOutput: String?

        // Example of function using an alternative syntax for `args`.
        let displayMethod = PythonInstanceMethod { (args: [PythonObject]) in
            // let `self` = args[0]
            printOutput = String(args[1])
            return Python.None
        }

        let classMethodOriginal = PythonInstanceMethod { args in
            // let cls = args[0]
            printOutput = String(args[1])
            return Python.None
        }

        // Did not explicitly convert `constructor` or `displayMethod` to
        // PythonObject. This is intentional, as the `PythonClass` initializer
        // should take any `PythonConvertible` and not just `PythonObject`.
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

    // Previously, there was a build error where passing a simple
    // `PythonClass.Members` literal made the literal's type ambiguous. It was
    // confused with `[String: PythonObject]`. The solution was adding a
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

                "__init__": PythonInstanceMethod { args in
                    let `self` = args[0]
                    let message = "hello \(args[1])"
                    helloOutput = String(message)

                    // Conventional `super` syntax does not work; use this instead.
                    Python.Exception.__init__(`self`, message)
                    return Python.None
                },

                // Example of function using the `self` convention instead of `args`.
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

                "__init__": PythonInstanceMethod { args in
                    let `self` = args[0]
                    let message = "world \(args[1])"
                    helloWorldOutput = String(message)

                    `self`.int_param = args[2]

                    // Conventional `super` syntax does not work; use this instead.
                    HelloException.__init__(`self`, message)
                    return Python.None
                },

                // Example of function using the `self` convention instead of `args`.
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

        // Example of function with no named parameters, which can be stated
        // ergonomically using an underscore. The ignored input is a [PythonObject].
        let testFunction = PythonFunction { _ in
            throw HelloWorldException("EXAMPLE ERROR MESSAGE", 2)
        }.pythonObject

        /*
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
        */
    }

    // Tests the ability to dynamically construct an argument list with keywords
    // and instantiate a `PythonInstanceMethod` with keywords.
    func testPythonClassInheritanceWithKeywords() {
        guard canUsePythonFunction else {
            return
        }

        func getValue(key: String, kwargs: [(String, PythonObject)]) -> PythonObject {
            let index = kwargs.firstIndex(where: { $0.0 == key })!
            return kwargs[index].1
        }

        // Base class has the following arguments:
        // __init__():
        // - 1 unnamed argument
        // - param1
        // - param2
        //
        // test_method():
        // - param1
        // - param2

        let BaseClass = PythonClass(
            "BaseClass",
            superclasses: [],
            members: [
                "__init__": PythonInstanceMethod { args, kwargs in
                    let `self` = args[0]
                    `self`.arg1 = args[1]
                    `self`.param1 = getValue(key: "param1", kwargs: kwargs)
                    `self`.param2 = getValue(key: "param2", kwargs: kwargs)
                    return Python.None
                },

                "test_method": PythonInstanceMethod { args, kwargs in
                    let `self` = args[0]
                    `self`.param1 += getValue(key: "param1", kwargs: kwargs)
                    `self`.param2 += getValue(key: "param2", kwargs: kwargs)
                    return Python.None
                }
            ]
        ).pythonObject

        // Derived class accepts the following arguments:
        // __init__():
        // - param2
        // - param3
        //
        // test_method():
        // - param1
        // - param2
        // - param3

        let DerivedClass = PythonClass(
            "DerivedClass",
            superclasses: [],
            members: [
                "__init__": PythonInstanceMethod { args, kwargs in
                    let `self` = args[0]
                    `self`.param3 = getValue(key: "param3", kwargs: kwargs)

                    // Lists the arguments in an order different than they are
                    // specified (self, param2, param3, param1, arg1). The
                    // correct order is (self, arg1, param1, param2, param3).
                    let newKeywordArguments = args.map {
                        ("", $0)
                    } + kwargs + [
                        ("param1", 1),
                        ("", 0)
                    ]

                    BaseClass.__init__.dynamicallyCall(
                        withKeywordArguments: newKeywordArguments)
                    return Python.None
                },

                "test_method": PythonInstanceMethod { args, kwargs in
                    let `self` = args[0]
                    `self`.param3 += getValue(key: "param3", kwargs: kwargs)

                    BaseClass.test_method.dynamicallyCall(
                        withKeywordArguments: args.map { ("", $0) } + kwargs)
                    return Python.None
                }
            ]
        ).pythonObject

        let derivedInstance = DerivedClass(param2: 2, param3: 3)
        XCTAssertEqual(derivedInstance.arg1, 0)
        XCTAssertEqual(derivedInstance.param1, 1)
        XCTAssertEqual(derivedInstance.param2, 2)
        XCTAssertEqual(derivedInstance.checking.param3, 3)

        derivedInstance.test_method(param1: 1, param2: 2, param3: 3)
        XCTAssertEqual(derivedInstance.arg1, 0)
        XCTAssertEqual(derivedInstance.param1, 2)
        XCTAssertEqual(derivedInstance.param2, 4)
        XCTAssertEqual(derivedInstance.checking.param3, 6)

        // Validate that subclassing and instantiating the derived class does
        // not affect behavior of the parent class.

        let baseInstance = BaseClass(0, param1: 10, param2: 20)
        XCTAssertEqual(baseInstance.arg1, 0)
        XCTAssertEqual(baseInstance.param1, 10)
        XCTAssertEqual(baseInstance.param2, 20)
        XCTAssertEqual(baseInstance.checking.param3, nil)

        baseInstance.test_method(param1: 10, param2: 20)
        XCTAssertEqual(baseInstance.arg1, 0)
        XCTAssertEqual(baseInstance.param1, 20)
        XCTAssertEqual(baseInstance.param2, 40)
        XCTAssertEqual(baseInstance.checking.param3, nil)
    }
}
