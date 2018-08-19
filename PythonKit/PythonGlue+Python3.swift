//
//  PythonGlue+Python3.swift
//  PythonKit
//
//  Created by Pedro José Pereira Vieito on 13/08/2018.
//  Copyright © 2018 Pedro José Pereira Vieito. All rights reserved.
//

#if canImport(Python3) && !PYTHON2
import Python3

internal let PyInt_AsLong = PyLong_AsLong
internal let PyInt_AsUnsignedLongMask = PyLong_AsUnsignedLongMask
internal let PyString_AsString = PyUnicode_AsUTF8

internal func PyInt_FromLong(_ int: Int) -> UnsafeMutablePointer<PyObject> {
    return PyLong_FromLong(int)
}

internal let PyInt_FromSize_t = PyInt_FromLong

internal var _Py_ZeroStruct = _Py_FalseStruct

internal func PyString_FromStringAndSize(_ string: UnsafePointer<Int8>!, _ size: Py_ssize_t) -> UnsafeMutablePointer<PyObject>? {
    return PyUnicode_DecodeUTF8(string, size, nil)
}

internal func PySys_SetPath(_ path: UnsafePointer<CChar>!) {
    PySys_SetPath(
        UnsafePointer<wchar_t>(Py_DecodeLocale(path, UnsafeMutablePointer(bitPattern: 0)))
    )
}
#endif
