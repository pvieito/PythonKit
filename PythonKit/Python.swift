//===-- Python.swift ------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// This file defines an interoperability layer for talking to Python from Swift.
//
//===----------------------------------------------------------------------===//
//
// The model provided by this file is completely dynamic and does not require
// invasive compiler support.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// `PyReference` definition
//===----------------------------------------------------------------------===//

/// Typealias used when passing or returning a `PyObject` pointer with
/// implied ownership.
@usableFromInline
typealias OwnedPyObjectPointer = PyObjectPointer

/// A primitive reference to a Python C API `PyObject`.
///
/// A `PyReference` instance has ownership of its underlying `PyObject`, which
/// must be non-null.
///
// - Note: When Swift has ownership, `PyReference` should be removed.
//   `PythonObject` will define copy constructors, move constructors, etc. to
//   implement move semantics.
@usableFromInline @_fixed_layout
final class PyReference {
    private var pointer: OwnedPyObjectPointer
    
    // This `PyReference`, once deleted, will make no delta change to the
    // python object's reference count. It will however, retain the reference for
    // the lifespan of this object.
    init(_ pointer: OwnedPyObjectPointer) {
        self.pointer = pointer
        Py_IncRef(pointer)
    }
    
    // This `PyReference` adopts the +1 reference and will decrement it in the
    // future.
    init(consuming pointer: PyObjectPointer) {
        self.pointer = pointer
    }
    
    deinit {
        Py_DecRef(pointer)
    }
    
    var borrowedPyObject: PyObjectPointer {
        return pointer
    }
    
    var ownedPyObject: OwnedPyObjectPointer {
        Py_IncRef(pointer)
        return pointer
    }
}

//===----------------------------------------------------------------------===//
// `PythonObject` definition
//===----------------------------------------------------------------------===//

// - Note: When Swift has ownership, `PythonObject` will define copy
//   constructors, move constructors, etc. to implement move semantics.

/// `PythonObject` represents an object in Python and supports dynamic member
/// lookup. Any member access like `object.foo` will dynamically request the
/// Python runtime for a member with the specified name in this object.
///
/// `PythonObject` is passed to and returned from all Python function calls and
/// member references. It supports standard Python arithmetic and comparison
/// operators.
///
/// Internally, `PythonObject` is implemented as a reference-counted pointer to
/// a Python C API `PyObject`.
@dynamicCallable
@dynamicMemberLookup
public struct PythonObject {
    /// The underlying `PyReference`.
    fileprivate var reference: PyReference
    
    @usableFromInline
    init(_ pointer: PyReference) {
        reference = pointer
    }
    
    /// Creates a new instance and a new reference.
    init(_ pointer: OwnedPyObjectPointer) {
        reference = PyReference(pointer)
    }
    
    /// Creates a new instance consuming the specified `PyObject` pointer.
    init(consuming pointer: PyObjectPointer) {
        reference = PyReference(consuming: pointer)
    }
    
    fileprivate var borrowedPyObject: PyObjectPointer {
        return reference.borrowedPyObject
    }
    
    fileprivate var ownedPyObject: OwnedPyObjectPointer {
        return reference.ownedPyObject
    }
}

// Make `print(python)` print a pretty form of the `PythonObject`.
extension PythonObject : CustomStringConvertible {
    /// A textual description of this `PythonObject`, produced by `Python.str`.
    public var description: String {
        // The `str` function is used here because it is designed to return
        // human-readable descriptions of Python objects. The Python REPL also uses
        // it for printing descriptions.
        // `repr` is not used because it is not designed to be readable and takes
        // too long for large objects.
        return String(Python.str(self))!
    }
}

// Make `PythonObject` show up nicely in the Xcode Playground results sidebar.
extension PythonObject : CustomPlaygroundDisplayConvertible {
    public var playgroundDescription: Any {
        return description
    }
}

// Mirror representation, used by debugger/REPL.
extension PythonObject : CustomReflectable {
    public var customMirror: Mirror {
        return Mirror(self, children: [], displayStyle: .struct)
    }
}

//===----------------------------------------------------------------------===//
// `PythonConvertible` protocol
//===----------------------------------------------------------------------===//

/// A type whose values can be converted to a `PythonObject`.
public protocol PythonConvertible {
    /// A `PythonObject` instance representing this value.
    var pythonObject: PythonObject { get }
}

public extension PythonObject {
    /// Creates a new instance from a `PythonConvertible` value.
    init<T : PythonConvertible>(_ object: T) {
        self.init(object.pythonObject)
    }
}

/// Internal helpers to convert `PythonConvertible` values to owned and borrowed
/// `PyObject` instances. These should not be made public.
fileprivate extension PythonConvertible {
    var borrowedPyObject: PyObjectPointer {
        return pythonObject.borrowedPyObject
    }
    
    var ownedPyObject: OwnedPyObjectPointer {
        return pythonObject.ownedPyObject
    }
}

//===----------------------------------------------------------------------===//
// `ConvertibleFromPython` protocol
//===----------------------------------------------------------------------===//

/// A type that can be initialized from a `PythonObject`.
public protocol ConvertibleFromPython {
    /// Creates a new instance from the given `PythonObject`, if possible.
    /// - Note: Conversion may fail if the given `PythonObject` instance is
    ///   incompatible (e.g. a Python `string` object cannot be converted into an
    ///   `Int`).
    init?(_ object: PythonObject)
}

// `PythonObject` is trivially `PythonConvertible`.
extension PythonObject : PythonConvertible, ConvertibleFromPython {
    public init(_ object: PythonObject) {
        self.init(consuming: object.ownedPyObject)
    }
    
    public var pythonObject: PythonObject { return self }
}

//===----------------------------------------------------------------------===//
// `PythonObject` callable implementation
//===----------------------------------------------------------------------===//

public extension PythonObject {
    /// Returns a callable version of this `PythonObject`. When called, the result
    /// throws a Swift error if the underlying Python function throws a Python
    /// exception.
    var throwing: ThrowingPythonObject {
        return ThrowingPythonObject(self)
    }
}

/// An error produced by a failable Python operation.
public enum PythonError : Error, Equatable {
    /// A Python runtime exception, produced by calling a Python function.
    case exception(PythonObject, traceback: PythonObject?)
    
    /// A failed call on a `PythonObject`.
    /// Reasons for failure include:
    /// - A non-callable Python object was called.
    /// - An incorrect number of arguments were provided to the callable Python
    ///   object.
    /// - An invalid keyword argument was specified.
    case invalidCall(PythonObject)
    
    /// A module import error.
    case invalidModule(String)
}

extension PythonError : CustomStringConvertible {
    public var description: String {
        switch self {
        case .exception(let e, let t):
            var exceptionDescription = "Python exception: \(e)"
            if let t = t {
                let traceback = Python.import("traceback")
                exceptionDescription += """
                \nTraceback:
                \(PythonObject("").join(traceback.format_tb(t)))
                """
            }
            return exceptionDescription
        case .invalidCall(let e):
            return "Invalid Python call: \(e)"
        case .invalidModule(let m):
            return "Invalid Python module: \(m)"
        }
    }
}

// Reflect a Python error (which must be active) into a Swift error if one is
// active.
private func throwPythonErrorIfPresent() throws {
    if PyErr_Occurred() == nil { return }
    
    var type: PyObjectPointer?
    var value: PyObjectPointer?
    var traceback: PyObjectPointer?
    
    // Fetch the exception and clear the exception state.
    PyErr_Fetch(&type, &value, &traceback)
    
    // The value for the exception may not be set but the type always should be.
    let resultObject = PythonObject(consuming: value ?? type!)
    let tracebackObject = traceback.flatMap { PythonObject(consuming: $0) }
    throw PythonError.exception(resultObject, traceback: tracebackObject)
}

/// A `PythonObject` wrapper that enables throwing method calls.
/// Exceptions produced by Python functions are reflected as Swift errors and
/// thrown.
/// - Note: It is intentional that `ThrowingPythonObject` does not have the
///   `@dynamicCallable` attribute because the call syntax is unintuitive:
///   `x.throwing(arg1, arg2, ...)`. The methods will still be named
///   `dynamicallyCall` until further discussion/design.
public struct ThrowingPythonObject {
    private var base: PythonObject
    
    fileprivate init(_ base: PythonObject) {
        self.base = base
    }
    
    /// Call `self` with the specified positional arguments.
    /// If the call fails for some reason, `PythonError.invalidCall` is thrown.
    /// - Precondition: `self` must be a Python callable.
    /// - Parameter args: Positional arguments for the Python callable.
    @discardableResult
    public func dynamicallyCall(
        withArguments args: PythonConvertible...) throws -> PythonObject {
        return try dynamicallyCall(withArguments: args)
    }
    
    /// Call `self` with the specified positional arguments.
    /// If the call fails for some reason, `PythonError.invalidCall` is thrown.
    /// - Precondition: `self` must be a Python callable.
    /// - Parameter args: Positional arguments for the Python callable.
    @discardableResult
    public func dynamicallyCall(
        withArguments args: [PythonConvertible] = []) throws -> PythonObject {
        try throwPythonErrorIfPresent()
        
        // Positional arguments are passed as a tuple of objects.
        let argTuple = pyTuple(args.map { $0.pythonObject })
        defer { Py_DecRef(argTuple) }
        
        // Python calls always return a non-null object when successful. If the
        // Python function produces the equivalent of C `void`, it returns the
        // `None` object. A `null` result of `PyObjectCall` happens when there is an
        // error, like `self` not being a Python callable.
        let selfObject = base.ownedPyObject
        defer { Py_DecRef(selfObject) }
        
        guard let result = PyObject_CallObject(selfObject, argTuple) else {
            // If a Python exception was thrown, throw a corresponding Swift error.
            try throwPythonErrorIfPresent()
            throw PythonError.invalidCall(base)
        }
        return PythonObject(consuming: result)
    }
    
    /// Call `self` with the specified arguments.
    /// If the call fails for some reason, `PythonError.invalidCall` is thrown.
    /// - Precondition: `self` must be a Python callable.
    /// - Parameter args: Positional or keyword arguments for the Python callable.
    @discardableResult
    public func dynamicallyCall(
        withKeywordArguments args:
        KeyValuePairs<String, PythonConvertible> = [:]) throws -> PythonObject {
        try throwPythonErrorIfPresent()
        
        // An array containing positional arguments.
        var positionalArgs: [PythonObject] = []
        // A dictionary object for storing keyword arguments, if any exist.
        var kwdictObject: OwnedPyObjectPointer? = nil
        
        for (key, value) in args {
            if key.isEmpty {
                positionalArgs.append(value.pythonObject)
                continue
            }
            // Initialize dictionary object if necessary.
            if kwdictObject == nil { kwdictObject = PyDict_New()! }
            // Add key-value pair to the dictionary object.
            // TODO: Handle duplicate keys.
            // In Python, `SyntaxError: keyword argument repeated` is thrown.
            let k = PythonObject(key).ownedPyObject
            let v = value.ownedPyObject
            PyDict_SetItem(kwdictObject, k, v)
            Py_DecRef(k)
            Py_DecRef(v)
        }
        
        defer { Py_DecRef(kwdictObject) } // Py_DecRef is `nil` safe.
        
        // Positional arguments are passed as a tuple of objects.
        let argTuple = pyTuple(positionalArgs)
        defer { Py_DecRef(argTuple) }
        
        // Python calls always return a non-null object when successful. If the
        // Python function produces the equivalent of C `void`, it returns the
        // `None` object. A `null` result of `PyObjectCall` happens when there is an
        // error, like `self` not being a Python callable.
        let selfObject = base.ownedPyObject
        defer { Py_DecRef(selfObject) }
        
        guard let result = PyObject_Call(selfObject, argTuple, kwdictObject) else {
            // If a Python exception was thrown, throw a corresponding Swift error.
            try throwPythonErrorIfPresent()
            throw PythonError.invalidCall(base)
        }
        return PythonObject(consuming: result)
    }
    
    /// Converts to a 2-tuple, if possible.
    public var tuple2: (PythonObject, PythonObject)? {
        let ct = base.checking
        guard let elt0 = ct[0], let elt1 = ct[1] else {
            return nil
        }
        return (elt0, elt1)
    }
    
    /// Converts to a 3-tuple, if possible.
    public var tuple3: (PythonObject, PythonObject, PythonObject)? {
        let ct = base.checking
        guard let elt0 = ct[0], let elt1 = ct[1], let elt2 = ct[2] else {
            return nil
        }
        return (elt0, elt1, elt2)
    }
    
    /// Converts to a 4-tuple, if possible.
    public var tuple4: (PythonObject, PythonObject, PythonObject, PythonObject)? {
        let ct = base.checking
        guard let elt0 = ct[0], let elt1 = ct[1],
            let elt2 = ct[2], let elt3 = ct[3] else {
                return nil
        }
        return (elt0, elt1, elt2, elt3)
    }
}


//===----------------------------------------------------------------------===//
// `PythonObject` member access implementation
//===----------------------------------------------------------------------===//

public extension PythonObject {
    /// Returns a `PythonObject` wrapper capable of member accesses.
    var checking: CheckingPythonObject {
        return CheckingPythonObject(self)
    }
}

/// A `PythonObject` wrapper that enables member accesses.
/// Member access operations return an `Optional` result. When member access
/// fails, `nil` is returned.
@dynamicMemberLookup
public struct CheckingPythonObject {
    /// The underlying `PythonObject`.
    private var base: PythonObject
    
    fileprivate init(_ base: PythonObject) {
        self.base = base
    }
    
    public subscript(dynamicMember name: String) -> PythonObject? {
        get {
            let selfObject = base.ownedPyObject
            defer { Py_DecRef(selfObject) }
            guard let result = PyObject_GetAttrString(selfObject, name) else {
                PyErr_Clear()
                return nil
            }
            // `PyObject_GetAttrString` returns +1 result.
            return PythonObject(consuming: result)
        }
    }
    
    /// Access the element corresponding to the specified `PythonConvertible`
    /// values representing a key.
    /// - Note: This is equivalent to `object[key]` in Python.
    public subscript(key: [PythonConvertible]) -> PythonObject? {
        get {
            let keyObject = flattenedSubscriptIndices(key)
            let selfObject = base.ownedPyObject
            defer {
                Py_DecRef(keyObject)
                Py_DecRef(selfObject)
            }
            
            // `PyObject_GetItem` returns +1 reference.
            if let result = PyObject_GetItem(selfObject, keyObject) {
                return PythonObject(consuming: result)
            }
            PyErr_Clear()
            return nil
        }
        nonmutating set {
            let keyObject = flattenedSubscriptIndices(key)
            let selfObject = base.ownedPyObject
            defer {
                Py_DecRef(keyObject)
                Py_DecRef(selfObject)
            }
            
            if let newValue = newValue {
                let newValueObject = newValue.ownedPyObject
                PyObject_SetItem(selfObject, keyObject, newValueObject)
                Py_DecRef(newValueObject)
            } else {
                // Assigning `nil` deletes the key, just like Swift dictionaries.
                PyObject_DelItem(selfObject, keyObject)
            }
        }
    }
    
    /// Access the element corresponding to the specified `PythonConvertible`
    /// values representing a key.
    /// - Note: This is equivalent to `object[key]` in Python.
    public subscript(key: PythonConvertible...) -> PythonObject? {
        get {
            return self[key]
        }
        nonmutating set {
            self[key] = newValue
        }
    }
    
    /// Converts to a 2-tuple, if possible.
    public var tuple2: (PythonObject, PythonObject)? {
        guard let elt0 = self[0], let elt1 = self[1] else {
            return nil
        }
        return (elt0, elt1)
    }
    
    /// Converts to a 3-tuple, if possible.
    public var tuple3: (PythonObject, PythonObject, PythonObject)? {
        guard let elt0 = self[0], let elt1 = self[1], let elt2 = self[2] else {
            return nil
        }
        return (elt0, elt1, elt2)
    }
    
    /// Converts to a 4-tuple, if possible.
    public var tuple4: (PythonObject, PythonObject, PythonObject, PythonObject)? {
        guard let elt0 = self[0], let elt1 = self[1],
            let elt2 = self[2], let elt3 = self[3] else {
                return nil
        }
        return (elt0, elt1, elt2, elt3)
    }
}

//===----------------------------------------------------------------------===//
// Core `PythonObject` API
//===----------------------------------------------------------------------===//

/// Converts an array of indices into a `PythonObject` representing a flattened
/// index.
private func flattenedSubscriptIndices(
    _ indices: [PythonConvertible]) -> OwnedPyObjectPointer {
    if indices.count == 1 {
        return indices[0].ownedPyObject
    }
    return pyTuple(indices.map { $0.pythonObject })
}

public extension PythonObject {
    subscript(dynamicMember memberName: String) -> PythonObject {
        get {
            guard let member = checking[dynamicMember: memberName] else {
                fatalError("Could not access PythonObject member '\(memberName)'")
            }
            return member
        }
        nonmutating set {
            let selfObject = ownedPyObject
            defer { Py_DecRef(selfObject) }
            let valueObject = newValue.ownedPyObject
            defer { Py_DecRef(valueObject) }
            
            if PyObject_SetAttrString(selfObject, memberName, valueObject) == -1 {
                try! throwPythonErrorIfPresent()
                fatalError("""
                    Could not set PythonObject member '\(memberName)' to the specified \
                    value
                    """)
            }
        }
    }
    
    /// Access the element corresponding to the specified `PythonConvertible`
    /// values representing a key.
    /// - Note: This is equivalent to `object[key]` in Python.
    subscript(key: PythonConvertible...) -> PythonObject {
        get {
            guard let item = checking[key] else {
                fatalError("""
                    Could not access PythonObject element corresponding to the specified \
                    key values: \(key)
                    """)
            }
            return item
        }
        nonmutating set {
            checking[key] = newValue
        }
    }
    
    /// Converts to a 2-tuple.
    var tuple2: (PythonObject, PythonObject) {
        guard let result = checking.tuple2 else {
            fatalError("Could not convert PythonObject to a 2-element tuple")
        }
        return result
    }
    
    /// Converts to a 3-tuple.
    var tuple3: (PythonObject, PythonObject, PythonObject) {
        guard let result = checking.tuple3 else {
            fatalError("Could not convert PythonObject to a 3-element tuple")
        }
        return result
    }
    
    /// Converts to a 4-tuple.
    var tuple4: (PythonObject, PythonObject, PythonObject, PythonObject) {
        guard let result = checking.tuple4 else {
            fatalError("Could not convert PythonObject to a 4-element tuple")
        }
        return result
    }
    
    /// Call `self` with the specified positional arguments.
    /// - Precondition: `self` must be a Python callable.
    /// - Parameter args: Positional arguments for the Python callable.
    @discardableResult
    func dynamicallyCall(
        withArguments args: [PythonConvertible] = []) -> PythonObject {
        return try! throwing.dynamicallyCall(withArguments: args)
    }
    
    /// Call `self` with the specified arguments.
    /// - Precondition: `self` must be a Python callable.
    /// - Parameter args: Positional or keyword arguments for the Python callable.
    @discardableResult
    func dynamicallyCall(
        withKeywordArguments args:
        KeyValuePairs<String, PythonConvertible> = [:]) -> PythonObject {
        return try! throwing.dynamicallyCall(withKeywordArguments: args)
    }
}

//===----------------------------------------------------------------------===//
// Python interface implementation
//===----------------------------------------------------------------------===//

/// The global Python interface.
///
/// You can import Python modules and access Python builtin types and functions
/// via the `Python` global variable.
///
///     import Python
///     // Import modules.
///     let os = Python.import("os")
///     let np = Python.import("numpy")
///
///     // Use builtin types and functions.
///     let list: PythonObject = [1, 2, 3]
///     print(Python.len(list)) // Prints 3.
///     print(Python.type(list) == Python.list) // Prints true.
@_fixed_layout
public let Python = PythonInterface()

/// An interface for Python.
///
/// `PythonInterface` allows interaction with Python. It can be used to import
/// modules and dynamically access Python builtin types and functions.
/// - Note: It is not intended for `PythonInterface` to be initialized
///   directly. Instead, please use the global instance of `PythonInterface`
///   called `Python`.
@dynamicMemberLookup
public struct PythonInterface {
    /// A dictionary of the Python builtins.
    public let builtins: PythonObject
    
    init() {
        Py_Initialize()   // Initialize Python
        builtins = PythonObject(PyEval_GetBuiltins())
        
        // Runtime Fixes:
        PyRun_SimpleString("""
            import sys
            import os
            
            # Some Python modules expect to have at least one argument in `sys.argv`.
            sys.argv = [""]

            # Some Python modules require `sys.executable` to return the path
            # to the Python interpreter executable. In Darwin, Python 3 returns the
            # main process executable path instead.
            if sys.version_info.major == 3 and sys.platform == "darwin":
                sys.executable = os.path.join(sys.exec_prefix, "bin", "python3")
            """)
    }
    
    public func attemptImport(_ name: String) throws -> PythonObject {
        guard let module = PyImport_ImportModule(name) else {
            try throwPythonErrorIfPresent()
            throw PythonError.invalidModule(name)
        }
        return PythonObject(consuming: module)
    }
    
    public func `import`(_ name: String) -> PythonObject {
        return try! attemptImport(name)
    }
    
    public subscript(dynamicMember name: String) -> PythonObject {
        return builtins[name]
    }
    
    // The Python runtime version.
    // Equivalent to `sys.version` in Python.
    public var version: PythonObject {
        return self.import("sys").version
    }
    
    // The Python runtime version information.
    // Equivalent to `sys.version_info` in Python.
    public var versionInfo: PythonObject {
        return self.import("sys").version_info
    }
}

//===----------------------------------------------------------------------===//
// Helpers for Python tuple types
//===----------------------------------------------------------------------===//

// Create a Python tuple object with the specified elements.
private func pyTuple<T : Collection>(_ vals: T) -> OwnedPyObjectPointer
    where T.Element : PythonConvertible {
        
        let tuple = PyTuple_New(vals.count)!
        for (index, element) in vals.enumerated() {
            // `PyTuple_SetItem` steals the reference of the object stored.
            PyTuple_SetItem(tuple, index, element.ownedPyObject)
        }
        return tuple
}

public extension PythonObject {
    // Tuples require explicit support because tuple types cannot conform to
    // protocols.
    init(tupleOf elements: PythonConvertible...) {
        self.init(tupleContentsOf: elements)
    }
    
    init<T : Collection>(tupleContentsOf elements: T)
        where T.Element == PythonConvertible {
            self.init(consuming: pyTuple(elements.map { $0.pythonObject }))
    }
    
    init<T : Collection>(tupleContentsOf elements: T)
        where T.Element : PythonConvertible {
            self.init(consuming: pyTuple(elements))
    }
}

//===----------------------------------------------------------------------===//
// `PythonConvertible` conformance for basic Swift types
//===----------------------------------------------------------------------===//

/// Return true if the specified objects an instance of the low-level Python
/// type descriptor passed in as 'type'.
private func isType(_ object: PythonObject,
                    type: PyObjectPointer) -> Bool {
    let typePyRef = PythonObject(type)
    
    let result = Python.isinstance(object, typePyRef)
    
    // We cannot use the normal failable Bool initializer from `PythonObject`
    // here because would cause an infinite loop.
    let pyObject = result.ownedPyObject
    defer { Py_DecRef(pyObject) }
    
    // Anything not equal to `Py_ZeroStruct` is truthy.
    return pyObject != _Py_ZeroStruct
}

extension Bool : PythonConvertible, ConvertibleFromPython {
    public init?(_ pythonObject: PythonObject) {
        guard isType(pythonObject, type: PyBool_Type) else { return nil }
        
        let pyObject = pythonObject.ownedPyObject
        defer { Py_DecRef(pyObject) }
        
        self = pyObject == _Py_TrueStruct
    }
    
    public var pythonObject: PythonObject {
        _ = Python // Ensure Python is initialized.
        return PythonObject(consuming: PyBool_FromLong(self ? 1 : 0))
    }
}

extension String : PythonConvertible, ConvertibleFromPython {
    public init?(_ pythonObject: PythonObject) {
        let pyObject = pythonObject.ownedPyObject
        defer { Py_DecRef(pyObject) }
        
        guard let cString = PyString_AsString(pyObject) else {
            PyErr_Clear()
            return nil
        }
        self.init(cString: cString)
    }
    
    public var pythonObject: PythonObject {
        _ = Python // Ensure Python is initialized.
        let v = utf8CString.withUnsafeBufferPointer {
            // 1 is subtracted from the C string length to trim the trailing null
            // character (`\0`).
            PyString_FromStringAndSize($0.baseAddress, $0.count - 1)!
        }
        return PythonObject(consuming: v)
    }
}

fileprivate extension PythonObject {
    // Converts a `PythonObject` to the given type by applying the appropriate
    // converter function and checking the error value.
    func converted<T : Equatable>(
        withError errorValue: T, by converter: (OwnedPyObjectPointer) -> T
    ) -> T? {
        let pyObject = ownedPyObject
        defer { Py_DecRef(pyObject) }
        
        assert(PyErr_Occurred() == nil,
               "Python error occurred somewhere but wasn't handled")
        
        let value = converter(pyObject)
        guard value != errorValue || PyErr_Occurred() == nil else {
            PyErr_Clear()
            return nil
        }
        return value
        
    }
}

extension Int : PythonConvertible, ConvertibleFromPython {
    public init?(_ pythonObject: PythonObject) {
        // `PyInt_AsLong` return -1 and sets an error if the Python object is not
        // integer compatible.
        guard let value = pythonObject.converted(
            withError: -1, by: PyInt_AsLong) else {
                return nil
        }
        self = value
    }
    
    public var pythonObject: PythonObject {
        _ = Python // Ensure Python is initialized.
        return PythonObject(consuming: PyInt_FromLong(self))
    }
}

extension UInt : PythonConvertible, ConvertibleFromPython {
    public init?(_ pythonObject: PythonObject) {
        // `PyInt_AsUnsignedLongMask` isn't documented as such, but in fact it does
        // return -1 and set an error if the Python object is not integer
        // compatible.
        guard let value = pythonObject.converted(
            withError: ~0, by: PyInt_AsUnsignedLongMask) else {
                return nil
        }
        self = value
    }
    
    public var pythonObject: PythonObject {
        _ = Python // Ensure Python is initialized.
        return PythonObject(consuming: PyInt_FromSize_t(self))
    }
}

extension Double : PythonConvertible, ConvertibleFromPython {
    public init?(_ pythonObject: PythonObject) {
        // `PyFloat_AsDouble` return -1 and sets an error if the Python object is
        // not float compatible.
        guard let value = pythonObject.converted(
            withError: -1, by: PyFloat_AsDouble) else {
                return nil
        }
        self = value
    }
    
    public var pythonObject: PythonObject {
        _ = Python // Ensure Python is initialized.
        return PythonObject(consuming: PyFloat_FromDouble(self))
    }
}

//===----------------------------------------------------------------------===//
// `PythonConvertible` conformances for `FixedWidthInteger` and `Float`
//===----------------------------------------------------------------------===//

// Any `FixedWidthInteger` type is `PythonConvertible` via the `Int`/`UInt`
// implementation.

extension Int8 : PythonConvertible, ConvertibleFromPython {
    public init?(_ pythonObject: PythonObject) {
        guard let i = Int(pythonObject) else { return nil }
        self.init(i)
    }
    
    public var pythonObject: PythonObject {
        return Int(self).pythonObject
    }
}

extension Int16 : PythonConvertible, ConvertibleFromPython {
    public init?(_ pythonObject: PythonObject) {
        guard let i = Int(pythonObject) else { return nil }
        self.init(i)
    }
    
    public var pythonObject: PythonObject {
        return Int(self).pythonObject
    }
}

extension Int32 : PythonConvertible, ConvertibleFromPython {
    public init?(_ pythonObject: PythonObject) {
        guard let i = Int(pythonObject) else { return nil }
        self.init(i)
    }
    
    public var pythonObject: PythonObject {
        return Int(self).pythonObject
    }
}

extension Int64 : PythonConvertible, ConvertibleFromPython {
    public init?(_ pythonObject: PythonObject) {
        guard let i = Int(pythonObject) else { return nil }
        self.init(i)
    }
    
    public var pythonObject: PythonObject {
        return Int(self).pythonObject
    }
}

extension UInt8 : PythonConvertible, ConvertibleFromPython {
    public init?(_ pythonObject: PythonObject) {
        guard let i = UInt(pythonObject) else { return nil }
        self.init(i)
    }
    
    public var pythonObject: PythonObject {
        return UInt(self).pythonObject
    }
}

extension UInt16 : PythonConvertible, ConvertibleFromPython {
    public init?(_ pythonObject: PythonObject) {
        guard let i = UInt(pythonObject) else { return nil }
        self.init(i)
    }
    
    public var pythonObject: PythonObject {
        return UInt(self).pythonObject
    }
}

extension UInt32 : PythonConvertible, ConvertibleFromPython {
    public init?(_ pythonObject: PythonObject) {
        guard let i = UInt(pythonObject) else { return nil }
        self.init(i)
    }
    
    public var pythonObject: PythonObject {
        return UInt(self).pythonObject
    }
}

extension UInt64 : PythonConvertible, ConvertibleFromPython {
    public init?(_ pythonObject: PythonObject) {
        guard let i = UInt(pythonObject) else { return nil }
        self.init(i)
    }
    
    public var pythonObject: PythonObject {
        return UInt(self).pythonObject
    }
}

// `Float` is `PythonConvertible` via the `Double` implementation.

extension Float : PythonConvertible, ConvertibleFromPython {
    public init?(_ pythonObject: PythonObject) {
        guard let v = Double(pythonObject) else { return nil }
        self.init(v)
    }
    
    public var pythonObject: PythonObject {
        return Double(self).pythonObject
    }
}

//===----------------------------------------------------------------------===//
// `PythonConvertible` conformance for `Optional`
//===----------------------------------------------------------------------===//

extension Optional : PythonConvertible where Wrapped : PythonConvertible {
    public var pythonObject: PythonObject {
        return self?.pythonObject ?? Python.None
    }
}

//===----------------------------------------------------------------------===//
// `ConvertibleFromPython` conformance for `Optional`
//===----------------------------------------------------------------------===//

extension Optional : ConvertibleFromPython
where Wrapped : ConvertibleFromPython {
    public init?(_ object: PythonObject) {
        if object == Python.None {
            self = .none
        } else {
            guard let converted = Wrapped(object) else {
                return nil
            }
            self = .some(converted)
        }
    }
}

//===----------------------------------------------------------------------===//
// `PythonConvertible` and `ConvertibleFromPython conformance for
// `Array` and `Dictionary`
//===----------------------------------------------------------------------===//

// `Array` conditionally conforms to `PythonConvertible` if the `Element`
// associated type does.
extension Array : PythonConvertible where Element : PythonConvertible {
    public var pythonObject: PythonObject {
        _ = Python // Ensure Python is initialized.
        let list = PyList_New(count)!
        for (index, element) in enumerated() {
            // `PyList_SetItem` steals the reference of the object stored.
            _ = PyList_SetItem(list, index, element.ownedPyObject)
        }
        return PythonObject(consuming: list)
    }
}

extension Array : ConvertibleFromPython where Element : ConvertibleFromPython {
    public init?(_ pythonObject: PythonObject) {
        self = []
        for elementObject in pythonObject {
            guard let element = Element(elementObject) else { return nil }
            append(element)
        }
    }
}

// `Dictionary` conditionally conforms to `PythonConvertible` if the `Key` and
// `Value` associated types do.
extension Dictionary : PythonConvertible
where Key : PythonConvertible, Value : PythonConvertible {
    public var pythonObject: PythonObject {
        _ = Python // Ensure Python is initialized.
        let dict = PyDict_New()!
        for (key, value) in self {
            let k = key.ownedPyObject
            let v = value.ownedPyObject
            PyDict_SetItem(dict, k, v)
            Py_DecRef(k)
            Py_DecRef(v)
        }
        return PythonObject(consuming: dict)
    }
}

extension Dictionary : ConvertibleFromPython
where Key : ConvertibleFromPython, Value : ConvertibleFromPython {
    public init?(_ pythonDict: PythonObject) {
        self = [:]
        
        // Iterate over the Python dictionary, converting its keys and values to
        // Swift `Key` and `Value` pairs.
        var key, value: PyObjectPointer?
        var position: Int = 0
        
        while PyDict_Next(
            pythonDict.borrowedPyObject,
            &position, &key, &value) != 0 {
                // If any key or value is not convertible to the corresponding Swift
                // type, then the entire dictionary is not convertible.
                if let swiftKey = Key(PythonObject(key!)),
                    let swiftValue = Value(PythonObject(value!)) {
                    // It is possible that there are duplicate keys after conversion. We
                    // silently allow duplicate keys and pick a nondeterministic result if
                    // there is a collision.
                    self[swiftKey] = swiftValue
                } else {
                    return nil
                }
        }
    }
}

//===----------------------------------------------------------------------===//
// `PythonConvertible` and `ConvertibleFromPython` conformances
// for `Range` types
//===----------------------------------------------------------------------===//

extension Range : PythonConvertible where Bound : PythonConvertible {
    public var pythonObject: PythonObject {
        _ = Python // Ensure Python is initialized.
        return Python.slice(lowerBound, upperBound, Python.None)
    }
}

extension Range : ConvertibleFromPython where Bound : ConvertibleFromPython {
    public init?(_ pythonObject: PythonObject) {
        guard isType(pythonObject, type: PySlice_Type) else { return nil }
        guard let lowerBound = Bound(pythonObject.start),
            let upperBound = Bound(pythonObject.stop) else {
                return nil
        }
        guard pythonObject.step == Python.None else { return nil }
        self.init(uncheckedBounds: (lowerBound, upperBound))
    }
}

extension PartialRangeFrom : PythonConvertible where Bound : PythonConvertible {
    public var pythonObject: PythonObject {
        _ = Python // Ensure Python is initialized.
        return Python.slice(lowerBound, Python.None, Python.None)
    }
}

extension PartialRangeFrom : ConvertibleFromPython
where Bound : ConvertibleFromPython {
    public init?(_ pythonObject: PythonObject) {
        guard isType(pythonObject, type: PySlice_Type) else { return nil }
        guard let lowerBound = Bound(pythonObject.start) else { return nil }
        guard pythonObject.stop == Python.None,
            pythonObject.step == Python.None else {
                return nil
        }
        self.init(lowerBound)
    }
}

extension PartialRangeUpTo : PythonConvertible where Bound : PythonConvertible {
    public var pythonObject: PythonObject {
        _ = Python // Ensure Python is initialized.
        return Python.slice(Python.None, upperBound, Python.None)
    }
}

extension PartialRangeUpTo : ConvertibleFromPython
where Bound : ConvertibleFromPython {
    public init?(_ pythonObject: PythonObject) {
        guard isType(pythonObject, type: PySlice_Type) else { return nil }
        guard let upperBound = Bound(pythonObject.stop) else { return nil }
        guard pythonObject.start == Python.None,
            pythonObject.step == Python.None else {
                return nil
        }
        self.init(upperBound)
    }
}

//===----------------------------------------------------------------------===//
// Standard operators and conformances
//===----------------------------------------------------------------------===//

private typealias PythonBinaryOp =
    (OwnedPyObjectPointer?, OwnedPyObjectPointer?) -> OwnedPyObjectPointer?
private typealias PythonUnaryOp =
    (OwnedPyObjectPointer?) -> OwnedPyObjectPointer?    

private func performBinaryOp(
    _ op: PythonBinaryOp, lhs: PythonObject, rhs: PythonObject) -> PythonObject {
    let result = op(lhs.borrowedPyObject, rhs.borrowedPyObject)
    // If binary operation fails (e.g. due to `TypeError`), throw an exception.
    try! throwPythonErrorIfPresent()
    return PythonObject(consuming: result!)
}

private func performUnaryOp(
    _ op: PythonUnaryOp, operand: PythonObject) -> PythonObject {
    let result = op(operand.borrowedPyObject)
    // If unary operation fails (e.g. due to `TypeError`), throw an exception.
    try! throwPythonErrorIfPresent()
    return PythonObject(consuming: result!)
}

public extension PythonObject {
    static func + (lhs: PythonObject, rhs: PythonObject) -> PythonObject {
        return performBinaryOp(PyNumber_Add, lhs: lhs, rhs: rhs)
    }
    
    static func - (lhs: PythonObject, rhs: PythonObject) -> PythonObject {
        return performBinaryOp(PyNumber_Subtract, lhs: lhs, rhs: rhs)
    }

    static func * (lhs: PythonObject, rhs: PythonObject) -> PythonObject {
        return performBinaryOp(PyNumber_Multiply, lhs: lhs, rhs: rhs)
    }
    
    static func / (lhs: PythonObject, rhs: PythonObject) -> PythonObject {
        return performBinaryOp(PyNumber_TrueDivide, lhs: lhs, rhs: rhs)
    }
    
    static func += (lhs: inout PythonObject, rhs: PythonObject) {
        lhs = performBinaryOp(PyNumber_InPlaceAdd, lhs: lhs, rhs: rhs)
    }
    
    static func -= (lhs: inout PythonObject, rhs: PythonObject) {
        lhs = performBinaryOp(PyNumber_InPlaceSubtract, lhs: lhs, rhs: rhs)
    }
    
    static func *= (lhs: inout PythonObject, rhs: PythonObject) {
        lhs = performBinaryOp(PyNumber_InPlaceMultiply, lhs: lhs, rhs: rhs)
    }
    
    static func /= (lhs: inout PythonObject, rhs: PythonObject) {
        lhs = performBinaryOp(PyNumber_InPlaceTrueDivide, lhs: lhs, rhs: rhs)
    }
}

extension PythonObject : SignedNumeric {
    public init<T : BinaryInteger>(exactly value: T) {
        self.init(Int(value))
    }
    
    public typealias Magnitude = PythonObject
    
    public var magnitude: PythonObject {
        return self < 0 ? -self : self
    }

    //override the default implementation of - prefix function
    //from SignedNumeric  (https://bugs.swift.org/browse/SR-13293)
    public static prefix func - (_ operand: Self) -> Self {
        return performUnaryOp(PyNumber_Negative, operand: operand)
    }
}

extension PythonObject : Strideable {
    public typealias Stride = PythonObject
    
    public func distance(to other: PythonObject) -> Stride {
        return other - self
    }
    
    public func advanced(by stride: Stride) -> PythonObject {
        return self + stride
    }
}

extension PythonObject : Equatable, Comparable {
    // `Equatable` and `Comparable` are implemented using rich comparison.
    // This is consistent with how Python handles comparisons.
    private func compared(to other: PythonObject, byOp: Int32) -> Bool {
        let lhsObject = ownedPyObject
        let rhsObject = other.ownedPyObject
        defer {
            Py_DecRef(lhsObject)
            Py_DecRef(rhsObject)
        }
        assert(PyErr_Occurred() == nil,
               "Python error occurred somewhere but wasn't handled")
        switch PyObject_RichCompareBool(lhsObject, rhsObject, byOp) {
        case 0: return false
        case 1: return true
        default:
            try! throwPythonErrorIfPresent()
            fatalError("No result or error returned when comparing \(self) to \(other)")
        }
    }
    
    public static func == (lhs: PythonObject, rhs: PythonObject) -> Bool {
        return lhs.compared(to: rhs, byOp: Py_EQ)
    }
    
    public static func != (lhs: PythonObject, rhs: PythonObject) -> Bool {
        return lhs.compared(to: rhs, byOp: Py_NE)
    }
    
    public static func < (lhs: PythonObject, rhs: PythonObject) -> Bool {
        return lhs.compared(to: rhs, byOp: Py_LT)
    }
    
    public static func <= (lhs: PythonObject, rhs: PythonObject) -> Bool {
        return lhs.compared(to: rhs, byOp: Py_LE)
    }
    
    public static func > (lhs: PythonObject, rhs: PythonObject) -> Bool {
        return lhs.compared(to: rhs, byOp: Py_GT)
    }
    
    public static func >= (lhs: PythonObject, rhs: PythonObject) -> Bool {
        return lhs.compared(to: rhs, byOp: Py_GE)
    }
}

extension PythonObject : Hashable {
    public func hash(into hasher: inout Hasher) {
        guard let hash = Int(self.__hash__()) else {
            fatalError("Cannot use '__hash__' on \(self)")
        }
        hasher.combine(hash)
    }
}

extension PythonObject : MutableCollection {
    public typealias Index = PythonObject
    public typealias Element = PythonObject
    
    public var startIndex: Index {
        return 0
    }
    
    public var endIndex: Index {
        return Python.len(self)
    }
    
    public func index(after i: Index) -> Index {
        return i + PythonObject(1)
    }
    
    public subscript(index: PythonObject) -> PythonObject {
        get {
            return self[index as PythonConvertible]
        }
        set {
            self[index as PythonConvertible] = newValue
        }
    }
}

extension PythonObject : Sequence {
    public struct Iterator : IteratorProtocol {
        fileprivate let pythonIterator: PythonObject
        
        public func next() -> PythonObject? {
            guard let result = PyIter_Next(self.pythonIterator.borrowedPyObject) else {
                try! throwPythonErrorIfPresent()
                return nil
            }
            return PythonObject(consuming: result)
        }
    }
    
    public func makeIterator() -> Iterator {
        guard let result = PyObject_GetIter(borrowedPyObject) else {
            try! throwPythonErrorIfPresent()
            // Unreachable. A Python `TypeError` must have been thrown.
            preconditionFailure()
        }
        return Iterator(pythonIterator: PythonObject(consuming: result))
    }
}

//===----------------------------------------------------------------------===//
// `ExpressibleByLiteral` conformances
//===----------------------------------------------------------------------===//

extension PythonObject : ExpressibleByBooleanLiteral, ExpressibleByIntegerLiteral,
ExpressibleByFloatLiteral, ExpressibleByStringLiteral {
    public init(booleanLiteral value: Bool) {
        self.init(value)
    }
    public init(integerLiteral value: Int) {
        self.init(value)
    }
    public init(floatLiteral value: Double) {
        self.init(value)
    }
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension PythonObject : ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral {
    public init(arrayLiteral elements: PythonObject...) {
        self.init(elements)
    }
    public typealias Key = PythonObject
    public typealias Value = PythonObject
    public init(dictionaryLiteral elements: (PythonObject, PythonObject)...) {
        self.init(Dictionary(elements, uniquingKeysWith: { lhs, _ in lhs }))
    }
}
