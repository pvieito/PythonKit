//===-- PythonLibrary.swift -----------------------------------*- swift -*-===//
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
// This file implements the logic for dynamically loading Python at runtime.
//
//===----------------------------------------------------------------------===//

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif os(Windows)
import CRT
import WinSDK
#endif

//===----------------------------------------------------------------------===//
// The `PythonLibrary` struct that loads Python symbols at runtime.
//===----------------------------------------------------------------------===//

public struct PythonLibrary {
    private static let pythonInitializeSymbolName = "Py_Initialize"
    private static let pythonLegacySymbolName = "PyString_AsString"
    private static var isPythonLibraryLoaded = false
    
    #if canImport(Darwin)
    private static let defaultLibraryHandle = UnsafeMutableRawPointer(bitPattern: -2)  // RTLD_DEFAULT
    #elseif canImport(Glibc)
    private static let defaultLibraryHandle: UnsafeMutableRawPointer? = nil  // RTLD_DEFAULT
    #elseif os(Windows)
    private static let defaultLibraryHandle: UnsafeMutableRawPointer? = nil  // Unsupported
    #endif
    
    private static let pythonLibraryHandle: UnsafeMutableRawPointer? = {
        let pythonLibraryHandle = Self.loadPythonLibrary()
        guard Self.isPythonLibraryLoaded(at: pythonLibraryHandle) else {
            fatalError("""
                Python library not found. Set the \(Environment.library.key) \
                environment variable with the path to a Python library.
                """)
        }
        Self.isPythonLibraryLoaded = true
        return pythonLibraryHandle
    }()
    private static let isLegacyPython: Bool = {
        let isLegacyPython = Self.loadSymbol(Self.pythonLibraryHandle, Self.pythonLegacySymbolName) != nil
        if isLegacyPython {
            Self.log("Loaded legacy Python library, using legacy symbols...")
        }
        return isLegacyPython
    }()
    
    internal static func loadSymbol<T>(
        name: String, legacyName: String? = nil, type: T.Type = T.self) -> T {
        var name = name
        if let legacyName = legacyName, self.isLegacyPython {
            name = legacyName
        }
        
        log("Loading symbol '\(name)' from the Python library...")
        return unsafeBitCast(self.loadSymbol(self.pythonLibraryHandle, name), to: type)
    }
}

// Methods of `PythonLibrary` required to set a given Python version.
extension PythonLibrary {
    private static func enforceNonLoadedPythonLibrary(function: String = #function) {
        precondition(!self.isPythonLibraryLoaded, """
            Error: \(function) should not be called after any Python library \
            has already been loaded.
            """)
    }
    
    public static func useVersion(_ major: Int, _ minor: Int? = nil) {
        self.enforceNonLoadedPythonLibrary()
        let version = PythonVersion(major: major, minor: minor)
        PythonLibrary.Environment.version.set(version.versionString)
    }
    
    public static func useLibrary(at path: String) {
        self.enforceNonLoadedPythonLibrary()
        PythonLibrary.Environment.library.set(path)
    }
}

// `PythonVersion` struct that defines a given Python version.
extension PythonLibrary {
    private struct PythonVersion {
        let major: Int
        let minor: Int?
        
        static let versionSeparator: Character = "."
        
        init(major: Int, minor: Int?) {
            self.major = major
            self.minor = minor
        }
        
        var versionString: String {
            var versionString = String(major)
            if let minor = minor {
                versionString += "\(PythonVersion.versionSeparator)\(minor)"
            }
            return versionString
        }
    }
}

// `PythonLibrary.Environment` enum used to read and set environment variables.
extension PythonLibrary {
    private enum Environment: String {
        private static let keyPrefix = "PYTHON"
        private static let keySeparator = "_"
        
        case library = "LIBRARY"
        case version = "VERSION"
        case loaderLogging = "LOADER_LOGGING"
        
        var key: String {
            return Environment.keyPrefix + Environment.keySeparator + rawValue
        }
        
        var value: String? {
            guard let value = getenv(key) else { return nil }
            return String(cString: value)
        }
        
        func set(_ value: String) {
            #if canImport(Darwin) || canImport(Glibc)
            setenv(key, value, 1)
            #elseif os(Windows)
            _putenv_s(key, value)
            #endif
        }
    }
}

// Methods of `PythonLibrary` required to load the Python library.
extension PythonLibrary {
    private static let supportedMajorVersions: [Int] = [3, 2]
    private static let supportedMinorVersions: [Int] = Array(0...30).reversed()
    
    private static let libraryPathVersionCharacter: Character = ":"
    
    #if canImport(Darwin)
    private static var libraryNames = ["Python.framework/Versions/:/Python"]
    private static var libraryPathExtensions = [""]
    private static var librarySearchPaths = ["", "/usr/local/Frameworks/"]
    private static var libraryVersionSeparator = "."
    #elseif os(Linux)
    private static var libraryNames = ["libpython:", "libpython:m"]
    private static var libraryPathExtensions = [".so"]
    private static var librarySearchPaths = [""]
    private static var libraryVersionSeparator = "."
    #elseif os(Windows)
    private static var libraryNames = ["python:"]
    private static var libraryPathExtensions = [".dll"]
    private static var librarySearchPaths = [""]
    private static var libraryVersionSeparator = ""
    #endif
    
    private static let libraryPaths: [String] = {
        var libraryPaths: [String] = []
        for librarySearchPath in librarySearchPaths {
            for libraryName in libraryNames {
                for libraryPathExtension in libraryPathExtensions {
                    let libraryPath =
                        librarySearchPath + libraryName + libraryPathExtension
                    libraryPaths.append(libraryPath)
                }
            }
        }
        return libraryPaths
    }()
    
    private static func loadSymbol(
        _ libraryHandle: UnsafeMutableRawPointer?, _ name: String) -> UnsafeMutableRawPointer? {
        #if canImport(Darwin) || canImport(Glibc)
        return dlsym(libraryHandle, name)
        #elseif os(Windows)
        guard let libraryHandle = libraryHandle else { return nil }
        let moduleHandle = libraryHandle
            .assumingMemoryBound(to: HINSTANCE__.self)
        let moduleSymbol = GetProcAddress(moduleHandle, name)
        return unsafeBitCast(moduleSymbol, to: UnsafeMutableRawPointer?.self)
        #endif
    }
    
    private static func isPythonLibraryLoaded(at pythonLibraryHandle: UnsafeMutableRawPointer? = nil) -> Bool {
        let pythonLibraryHandle = pythonLibraryHandle ?? self.defaultLibraryHandle
        return self.loadSymbol(pythonLibraryHandle, self.pythonInitializeSymbolName) != nil
    }

    private static func loadPythonLibrary() -> UnsafeMutableRawPointer? {
        let pythonLibraryHandle: UnsafeMutableRawPointer?
        if self.isPythonLibraryLoaded() {
            pythonLibraryHandle = self.defaultLibraryHandle
        }
        else if let pythonLibraryPath = Environment.library.value {
            pythonLibraryHandle = self.loadPythonLibrary(at: pythonLibraryPath)
        }
        else {
            pythonLibraryHandle = self.findAndLoadExternalPythonLibrary()
        }
        return pythonLibraryHandle
    }
    
    private static func findAndLoadExternalPythonLibrary() -> UnsafeMutableRawPointer? {
        for majorVersion in supportedMajorVersions {
            for minorVersion in supportedMinorVersions {
                for libraryPath in libraryPaths {
                    let version = PythonVersion(major: majorVersion, minor: minorVersion)
                    guard let pythonLibraryHandle = loadPythonLibrary(
                        at: libraryPath, version: version) else {
                            continue
                    }
                    return pythonLibraryHandle
                }
            }
        }
        return nil
    }
    
    private static func loadPythonLibrary(
        at path: String, version: PythonVersion) -> UnsafeMutableRawPointer? {
        let versionString = version.versionString
        
        if let requiredPythonVersion = Environment.version.value {
            let requiredMajorVersion = Int(requiredPythonVersion)
            if requiredPythonVersion != versionString,
                requiredMajorVersion != version.major {
                return nil
            }
        }
        
        let libraryVersionString = versionString
            .split(separator: PythonVersion.versionSeparator)
            .joined(separator: libraryVersionSeparator)
        let path = path.split(separator: libraryPathVersionCharacter)
            .joined(separator: libraryVersionString)
        return self.loadPythonLibrary(at: path)
    }
    
    private static func loadPythonLibrary(at path: String) -> UnsafeMutableRawPointer? {
        self.log("Trying to load library at '\(path)'...")
        #if canImport(Darwin) || canImport(Glibc)
        // Must be RTLD_GLOBAL because subsequent .so files from the imported python
        // modules may depend on this .so file.
        let pythonLibraryHandle = dlopen(path, RTLD_LAZY | RTLD_GLOBAL)
        #elseif os(Windows)
        let pythonLibraryHandle = UnsafeMutableRawPointer(LoadLibraryA(path))
        #endif
        
        if pythonLibraryHandle != nil {
            self.log("Library at '\(path)' was sucessfully loaded.")
        }
        return pythonLibraryHandle
    }
}

// Methods of `PythonLibrary` used for logging messages.
extension PythonLibrary {
    private static func log(_ message: String) {
        guard Environment.loaderLogging.value != nil else { return }
        fputs(message + "\n", stderr)
    }
}
