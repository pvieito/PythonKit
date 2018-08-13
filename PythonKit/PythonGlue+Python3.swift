//
//  PythonGlue+Python3.swift
//  PythonKit
//
//  Created by Pedro José Pereira Vieito on 13/08/2018.
//  Copyright © 2018 Pedro José Pereira Vieito. All rights reserved.
//

#if canImport(Python3) && !PYTHON2
import Python3

private let PyInt_AsLong = PyLong_AsLong
private let PyInt_AsUnsignedLongMask = PyLong_AsUnsignedLongMask
private let PyString_AsString = PyUnicode_AsUTF8

private func PyInt_FromLong(_ int: Int) -> UnsafeMutablePointer<PyObject> {
    return PyLong_FromLong(int)
}

private let PyInt_FromSize_t = PyInt_FromLong

private var _Py_ZeroStruct = _Py_FalseStruct

private func PyString_FromStringAndSize(_ string: UnsafePointer<Int8>!, _ size: Py_ssize_t) -> UnsafeMutablePointer<PyObject>? {
    return PyUnicode_DecodeUTF8(string, size, nil)
}

private func PySys_SetPath(_ path: UnsafePointer<CChar>!) {
    let capacity = 4096
    let widecharPath = UnsafeMutableBufferPointer<wchar_t>.allocate(capacity: capacity)
    mbstowcs(widecharPath.baseAddress, path, capacity)
    PySys_SetPath(widecharPath.baseAddress)
    widecharPath.deallocate()
}
#endif
