//
//  PythonStringLambda.swift
//  PythonKit
//
//  Created by strictlyswift on 2-Jul-20.
//

/// Represents an executable python lambda as a string.
///
/// The string is Python code which is executed as a lambda.
/// The lambda is converted into a `PythonObject` via `.pythonObject`
///
/// Use this as a 'break glass' when you can't create a suitable function using the `PythonLambda` capability.
///
///  - Example:
///
///        let doubler = PythonStringLambda(lambda: "x:x*2")
///        df.apply( doubler.py )
///
///  - Note: This is not thread safe and operates by creating the lambda in the `__main__` module, with a unique name.
public class PythonStringLambda : PythonConvertible {
    static let main: PythonObject = Python.import("__main__")
    static var lambdaCounter = 0
    private var id: String? = nil
    private let lambda: String
    
    public init(lambda: String) {
        if lambda.starts(with: "lambda") {
            fatalError("Lambda expression must not start 'lambda'. Eg, just 'x:x*3')")
        }
        if !lambda.contains(":") {
            fatalError("Lambda expression must contain ':' to indicate bound variables (eg 'x:x*3'")
        }
        self.lambda = lambda
    }
    
    /// returns an executable object (not the result of the execution)
    public var pythonObject: PythonObject { get {
        if let id = id {
            return Self.main[dynamicMember: id]
        } else {
            id = "lmbstr\(Self.lambdaCounter)"
            PyRun_SimpleString(
            """
            \(id!) = lambda \(lambda)
            """)
            
            Self.lambdaCounter += 1
            return Self.main[dynamicMember: id!]
        }
    }}
}


extension PythonInterface {
    /// Executes Python code directly in the Python interpreter. Useful to (for example) define a function to
    /// call as a lambda later.
    ///
    /// Use at your own risk! Errors must be handled in Python, otherwise they are likely to simply crash your Swift code.
    ///
    /// - Example:
    ///
    ///       Python.execute("""
    ///           def add5(i):
    ///               return (i+5)
    ///       """)
    ///       let fiveAdder = PythonStringLambda(lambda: "i:add5(i)")
    ///       Python.map( fiveAdder , [10,12,14] )   // [15,17,19]
    public func execute(_ code: String) {
        PyRun_SimpleString(
        """
        \(code)
        """)
    }
}
