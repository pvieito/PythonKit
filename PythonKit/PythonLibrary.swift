//
//  PythonGlue+Functions.swift
//  DynamicPython
//
//  Created by Pedro José Pereira Vieito on 23/08/2018.
//  Copyright © 2018 Pedro José Pereira Vieito. All rights reserved.
//

import Foundation

let Py_LT: Int32 = 0
let Py_LE: Int32 = 1
let Py_EQ: Int32 = 2
let Py_NE: Int32 = 3
let Py_GT: Int32 = 4
let Py_GE: Int32 = 5

typealias OwnedPyObjectPointer = UnsafeMutableRawPointer
typealias PyObjectPointer = UnsafeMutableRawPointer
typealias CCharPointer = UnsafePointer<Int8>

internal let PythonLibrary = PythonLibraryManager()

internal struct PythonLibraryManager {
    
    private static let pythonLibraryEnvironmentKey = "PYTHON_LIBRARY"
    private static let pythonVersionEnvironmentKey = "PYTHON_VERSION"
    private static let pythonLegacySymbolName = "PyString_AsString"
    
    private static let supportedMajorVersions = 2...3
    private static let supportedMinorVersions = 0...9
    
    #if os(macOS)
    private static let libraryPrefixes: [URL] = {
        let prefixes = [
            "/usr/local" // Homebrew
        ]
        return prefixes.map { URL(fileURLWithPath: $0) } + FileManager.default.urls(for: .libraryDirectory, in: [.systemDomainMask, .userDomainMask])
    }()
    
    private static let unprefixedLibraryPaths = [
        "Frameworks/Python.framework/Versions/{version}/Python"
    ]
    #elseif os(Linux)
    private static let libraryPrefixes: [URL] = {
        let prefixes = [
            "/usr",
            "/usr/local"
        ]
        return prefixes.map { URL(fileURLWithPath: $0) }
    }()
    
    private static let unprefixedLibraryPaths = [
        "lib/x86_64-linux-gnu/libpython{version}.so",
        "lib/x86_64-linux-gnu/libpython{version}m.so",
        "lib/libpython{version}.so",
        "lib/libpython{version}m.so"
    ]
    #endif
    
    static func getPythonLibraryPath() -> String? {
        let pythonLibraryPath = ProcessInfo.processInfo.environment[PythonLibraryManager.pythonLibraryEnvironmentKey]
        
        if let pythonLibraryPath = pythonLibraryPath {
            return pythonLibraryPath
        }
        
        let pythonVersion = ProcessInfo.processInfo.environment[PythonLibraryManager.pythonVersionEnvironmentKey]
        
        for majorVersion in supportedMajorVersions.reversed() {
            for minorVersion in supportedMinorVersions.reversed() {
                for prefix in libraryPrefixes {
                    for unprefixedPath in unprefixedLibraryPaths {
                        
                        let versionString = "\(majorVersion).\(minorVersion)"
                        
                        if let pythonVersion = pythonVersion, !versionString.hasPrefix(pythonVersion) {
                            continue
                        }
                        
                        let unprefixedPath = unprefixedPath.replacingOccurrences(of: "{version}", with: versionString)
                        let pythonLibrary = prefix.appendingPathComponent(unprefixedPath)
                                                
                        if FileManager.default.fileExists(atPath: pythonLibrary.path) {
                            return pythonLibrary.path
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    private let pythonLibraryPath: String
    private let pythonLibrary: UnsafeMutableRawPointer
    private let isLegacyPython: Bool
    
    fileprivate init() {
        guard let pythonLibraryPath = PythonLibraryManager.getPythonLibraryPath() else {
            fatalError("Python library path not found. Set the \(PythonLibraryManager.pythonLibraryEnvironmentKey) environment variable with the path to the Python Library.")
        }
        
        self.pythonLibraryPath = pythonLibraryPath
        
        guard let pythonLibrary = dlopen(pythonLibraryPath, RTLD_NOW) else {
            fatalError("Python library not available at “\(pythonLibraryPath)”")
        }
        
        self.pythonLibrary = pythonLibrary
        
        // Check if Python is legacy (before Python 3)
        let legacySymbol = dlsym(pythonLibrary, PythonLibraryManager.pythonLegacySymbolName)
        self.isLegacyPython = legacySymbol != nil
    }
    
    internal func getSymbol<T>(name: String, legacyName: String? = nil, signature: T.Type) -> T {
        var name = name
        
        if let legacyName = legacyName, self.isLegacyPython {
            name = legacyName
        }
        
        let symbol = unsafeBitCast(
            dlsym(pythonLibrary, name),
            to: signature
        )
        
        return symbol
    }
}

let Py_Initialize: (@convention(c) () -> ()) = PythonLibrary.getSymbol(
    name: "Py_Initialize",
    signature: (@convention(c) () -> ()).self
)

let Py_IncRef = PythonLibrary.getSymbol(
    name: "Py_IncRef",
    signature: (@convention(c) (PyObjectPointer?) -> ()).self
)

let Py_DecRef = PythonLibrary.getSymbol(
    name: "Py_DecRef",
    signature: (@convention(c) (PyObjectPointer?) -> ()).self
)

let PyImport_ImportModule = PythonLibrary.getSymbol(
    name: "PyImport_ImportModule",
    signature: (@convention(c) (CCharPointer) -> PyObjectPointer?).self
)

let PyEval_GetBuiltins = PythonLibrary.getSymbol(
    name: "PyEval_GetBuiltins",
    signature: (@convention(c) () -> PyObjectPointer).self
)

let PyErr_Occurred = PythonLibrary.getSymbol(
    name: "PyErr_Occurred",
    signature: (@convention(c) () -> PyObjectPointer?).self
)

let PyErr_Clear = PythonLibrary.getSymbol(
    name: "PyErr_Clear",
    signature: (@convention(c) () -> ()).self
)

let PyErr_Fetch = PythonLibrary.getSymbol(
    name: "PyErr_Fetch",
    signature: (@convention(c) (
        UnsafeMutablePointer<PyObjectPointer?>,
        UnsafeMutablePointer<PyObjectPointer?>,
        UnsafeMutablePointer<PyObjectPointer?>
        ) -> ()).self
)

let PyDict_New = PythonLibrary.getSymbol(
    name: "PyDict_New",
    signature: (@convention(c) () -> PyObjectPointer?).self
)

let PyDict_SetItem = PythonLibrary.getSymbol(
    name: "PyDict_SetItem",
    signature: (@convention(c) (PyObjectPointer?, PyObjectPointer, PyObjectPointer) -> ()).self
)

let PyObject_GetItem = PythonLibrary.getSymbol(
    name: "PyObject_GetItem",
    signature: (@convention(c) (PyObjectPointer, PyObjectPointer) -> PyObjectPointer?).self
)

let PyObject_SetItem = PythonLibrary.getSymbol(
    name: "PyObject_SetItem",
    signature: (@convention(c) (PyObjectPointer, PyObjectPointer, PyObjectPointer) -> ()).self
)

let PyObject_DelItem = PythonLibrary.getSymbol(
    name: "PyObject_DelItem",
    signature: (@convention(c) (PyObjectPointer, PyObjectPointer) -> ()).self
)

let PyObject_Call = PythonLibrary.getSymbol(
    name: "PyObject_Call",
    signature: (@convention(c) (PyObjectPointer, PyObjectPointer, PyObjectPointer?) -> (PyObjectPointer?)).self
)

let PyObject_GetAttrString = PythonLibrary.getSymbol(
    name: "PyObject_GetAttrString",
    signature: (@convention(c) (PyObjectPointer, CCharPointer) -> (PyObjectPointer?)).self
)

let PyObject_SetAttrString = PythonLibrary.getSymbol(
    name: "PyObject_SetAttrString",
    signature: (@convention(c) (PyObjectPointer, CCharPointer, PyObjectPointer) -> (Int)).self
)

let PySlice_New = PythonLibrary.getSymbol(
    name: "PySlice_New",
    signature: (@convention(c) (PyObjectPointer?, PyObjectPointer?, PyObjectPointer?) -> (PyObjectPointer?)).self
)

let PyTuple_New = PythonLibrary.getSymbol(
    name: "PyTuple_New",
    signature: (@convention(c) (Int) -> (PyObjectPointer?)).self
)

let PyTuple_SetItem = PythonLibrary.getSymbol(
    name: "PyTuple_SetItem",
    signature: (@convention(c) (PyObjectPointer, Int, PyObjectPointer) -> ()).self
)

let PyObject_RichCompareBool = PythonLibrary.getSymbol(
    name: "PyObject_RichCompareBool",
    signature: (@convention(c) (PyObjectPointer, PyObjectPointer, Int32) -> (Int32)).self
)

let PyDict_Next = PythonLibrary.getSymbol(
    name: "PyDict_Next",
    signature: (@convention(c) (
        PyObjectPointer,
        UnsafeMutablePointer<Int>,
        UnsafeMutablePointer<PyObjectPointer?>,
        UnsafeMutablePointer<PyObjectPointer?>
        ) -> (Int32)).self
)

let PyList_New = PythonLibrary.getSymbol(
    name: "PyList_New",
    signature: (@convention(c) (Int) -> (PyObjectPointer?)).self
)

let PyList_SetItem = PythonLibrary.getSymbol(
    name: "PyList_SetItem",
    signature: (@convention(c) (PyObjectPointer, Int, PyObjectPointer) -> (Int32)).self
)

let PyBool_FromLong = PythonLibrary.getSymbol(
    name: "PyBool_FromLong",
    signature: (@convention(c) (Int) -> (PyObjectPointer)).self
)


let PyFloat_AsDouble = PythonLibrary.getSymbol(
    name: "PyFloat_AsDouble",
    signature: (@convention(c) (PyObjectPointer) -> (Double)).self
)

let PyFloat_FromDouble = PythonLibrary.getSymbol(
    name: "PyFloat_FromDouble",
    signature: (@convention(c) (Double) -> (PyObjectPointer)).self
)

let PyInt_AsLong = PythonLibrary.getSymbol(
    name: "PyLong_AsLong",
    legacyName: "PyInt_AsLong",
    signature: (@convention(c) (PyObjectPointer) -> (Int)).self
)

let PyInt_FromLong = PythonLibrary.getSymbol(
    name: "PyLong_FromLong",
    legacyName: "PyInt_FromLong",
    signature: (@convention(c) (Int) -> (PyObjectPointer)).self
)

let PyInt_AsUnsignedLongMask = PythonLibrary.getSymbol(
    name: "PyLong_AsUnsignedLongMask",
    legacyName: "PyInt_AsUnsignedLongMask",
    signature: (@convention(c) (PyObjectPointer) -> (UInt)).self
)

let PyInt_FromSize_t = PythonLibrary.getSymbol(
    name: "PyInt_FromLong",
    legacyName: "PyInt_FromSize_t",
    signature: (@convention(c) (Int) -> (PyObjectPointer)).self
)

let PyString_AsString = PythonLibrary.getSymbol(
    name: "PyUnicode_AsUTF8",
    legacyName: "PyString_AsString",
    signature: (@convention(c) (PyObjectPointer) -> (CCharPointer?)).self
)

let PyString_FromStringAndSize = PythonLibrary.getSymbol(
    name: "PyUnicode_DecodeUTF8",
    legacyName: "PyString_FromStringAndSize",
    signature: (@convention(c) (CCharPointer?, Int) -> (PyObjectPointer?)).self
)
