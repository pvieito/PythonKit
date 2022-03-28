//===-- PythonLibrary+Symbols.swift ---------------------------*- swift -*-===//
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
// This file defines the Python symbols required for the interoperability layer.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Required Python typealias and constants.
//===----------------------------------------------------------------------===//

@usableFromInline
typealias PyObjectPointer = UnsafeMutableRawPointer
typealias PyMethodDefPointer = UnsafeMutableRawPointer
typealias PyCCharPointer = UnsafePointer<Int8>
typealias PyBinaryOperation =
    @convention(c) (PyObjectPointer?, PyObjectPointer?) -> PyObjectPointer?
typealias PyUnaryOperation =
    @convention(c) (PyObjectPointer?) -> PyObjectPointer?

let Py_LT: Int32 = 0
let Py_LE: Int32 = 1
let Py_EQ: Int32 = 2
let Py_NE: Int32 = 3
let Py_GT: Int32 = 4
let Py_GE: Int32 = 5

//===----------------------------------------------------------------------===//
// Python library symbols lazily loaded at runtime.
//===----------------------------------------------------------------------===//

let Py_Initialize: @convention(c) () -> Void =
    PythonLibrary.loadSymbol(name: "Py_Initialize")

let Py_IncRef: @convention(c) (PyObjectPointer?) -> Void =
    PythonLibrary.loadSymbol(name: "Py_IncRef")

let Py_DecRef: @convention(c) (PyObjectPointer?) -> Void =
    PythonLibrary.loadSymbol(name: "Py_DecRef")

let PyImport_ImportModule: @convention(c) (
    PyCCharPointer) -> PyObjectPointer? =
    PythonLibrary.loadSymbol(name: "PyImport_ImportModule")

let PyEval_GetBuiltins: @convention(c) () -> PyObjectPointer =
    PythonLibrary.loadSymbol(name: "PyEval_GetBuiltins")

let PyRun_SimpleString: @convention(c) (PyCCharPointer) -> Void =
    PythonLibrary.loadSymbol(name: "PyRun_SimpleString")

let PyCFunction_NewEx: @convention(c) (PyMethodDefPointer, UnsafeMutableRawPointer, UnsafeMutableRawPointer?) -> PyObjectPointer =
    PythonLibrary.loadSymbol(name: "PyCFunction_NewEx")

let PyInstanceMethod_New: @convention(c) (PyObjectPointer) -> PyObjectPointer =
    PythonLibrary.loadSymbol(name: "PyInstanceMethod_New")

let PyCapsule_New: @convention(c) (
    UnsafeMutableRawPointer, UnsafePointer<CChar>?,
    @convention(c) @escaping (PyObjectPointer?) -> Void) -> PyObjectPointer =
    PythonLibrary.loadSymbol(name: "PyCapsule_New")

let PyCapsule_GetPointer: @convention(c) (PyObjectPointer?, UnsafePointer<CChar>?) -> UnsafeMutableRawPointer =
    PythonLibrary.loadSymbol(name: "PyCapsule_GetPointer")

let PyErr_SetString: @convention(c) (PyObjectPointer, UnsafePointer<CChar>?) -> Void =
    PythonLibrary.loadSymbol(name: "PyErr_SetString")

let PyErr_Occurred: @convention(c) () -> PyObjectPointer? =
    PythonLibrary.loadSymbol(name: "PyErr_Occurred")

let PyErr_Clear: @convention(c) () -> Void =
    PythonLibrary.loadSymbol(name: "PyErr_Clear")

let PyErr_Fetch: @convention(c) (
    UnsafeMutablePointer<PyObjectPointer?>,
    UnsafeMutablePointer<PyObjectPointer?>,
    UnsafeMutablePointer<PyObjectPointer?>) -> Void =
    PythonLibrary.loadSymbol(name: "PyErr_Fetch")

let PyDict_New: @convention(c) () -> PyObjectPointer? =
    PythonLibrary.loadSymbol(name: "PyDict_New")

let PyDict_SetItem: @convention(c) (
    PyObjectPointer?, PyObjectPointer, PyObjectPointer) -> Void =
    PythonLibrary.loadSymbol(name: "PyDict_SetItem")

let PyObject_GetItem: @convention(c) (
    PyObjectPointer, PyObjectPointer) -> PyObjectPointer? =
    PythonLibrary.loadSymbol(name: "PyObject_GetItem")

let PyObject_SetItem: @convention(c) (
    PyObjectPointer, PyObjectPointer, PyObjectPointer) -> Void =
    PythonLibrary.loadSymbol(name: "PyObject_SetItem")

let PyObject_DelItem: @convention(c) (
    PyObjectPointer, PyObjectPointer) -> Void =
    PythonLibrary.loadSymbol(name: "PyObject_DelItem")

let PyObject_Call: @convention(c) (
    PyObjectPointer, PyObjectPointer,
    PyObjectPointer?) -> PyObjectPointer? =
    PythonLibrary.loadSymbol(name: "PyObject_Call")

let PyObject_CallObject: @convention(c) (
    PyObjectPointer, PyObjectPointer) -> PyObjectPointer? =
    PythonLibrary.loadSymbol(name: "PyObject_CallObject")

let PyObject_GetAttrString: @convention(c) (
    PyObjectPointer, PyCCharPointer) -> PyObjectPointer? =
    PythonLibrary.loadSymbol(name: "PyObject_GetAttrString")

let PyObject_SetAttrString: @convention(c) (
    PyObjectPointer, PyCCharPointer, PyObjectPointer) -> Int32 =
    PythonLibrary.loadSymbol(name: "PyObject_SetAttrString")

let PyObject_Not: PyUnaryOperation =
    PythonLibrary.loadSymbol(name: "PyObject_Not")

let PySlice_New: @convention(c) (
    PyObjectPointer?, PyObjectPointer?,
    PyObjectPointer?) -> PyObjectPointer? =
    PythonLibrary.loadSymbol(name: "PySlice_New")

let PyTuple_New: @convention(c) (Int) -> PyObjectPointer? =
    PythonLibrary.loadSymbol(name: "PyTuple_New")

let PyTuple_SetItem: @convention(c) (
    PyObjectPointer, Int, PyObjectPointer) -> Void =
    PythonLibrary.loadSymbol(name: "PyTuple_SetItem")

let PyObject_RichCompare: @convention(c) (
    PyObjectPointer, PyObjectPointer, Int32) -> PyObjectPointer? =
    PythonLibrary.loadSymbol(name: "PyObject_RichCompare")

let PyObject_RichCompareBool: @convention(c) (
    PyObjectPointer, PyObjectPointer, Int32) -> Int32 =
    PythonLibrary.loadSymbol(name: "PyObject_RichCompareBool")

let PyDict_Next: @convention(c) (
    PyObjectPointer, UnsafeMutablePointer<Int>,
    UnsafeMutablePointer<PyObjectPointer?>,
    UnsafeMutablePointer<PyObjectPointer?>) -> Int32 =
    PythonLibrary.loadSymbol(name: "PyDict_Next")

let PyIter_Next: @convention(c) (
    PyObjectPointer) -> PyObjectPointer? =
    PythonLibrary.loadSymbol(name: "PyIter_Next")

let PyObject_GetIter: @convention(c) (
    PyObjectPointer) -> PyObjectPointer? =
    PythonLibrary.loadSymbol(name: "PyObject_GetIter")

let PyList_New: @convention(c) (Int) -> PyObjectPointer? =
    PythonLibrary.loadSymbol(name: "PyList_New")

let PyList_SetItem: @convention(c) (
    PyObjectPointer, Int, PyObjectPointer) -> Int32 =
    PythonLibrary.loadSymbol(name: "PyList_SetItem")

let PyBool_FromLong: @convention(c) (Int) -> PyObjectPointer =
    PythonLibrary.loadSymbol(name: "PyBool_FromLong")

let PyFloat_AsDouble: @convention(c) (PyObjectPointer) -> Double =
    PythonLibrary.loadSymbol(name: "PyFloat_AsDouble")

let PyFloat_FromDouble: @convention(c) (Double) -> PyObjectPointer =
    PythonLibrary.loadSymbol(name: "PyFloat_FromDouble")

let PyInt_AsLong: @convention(c) (PyObjectPointer) -> Int =
    PythonLibrary.loadSymbol(
        name: "PyLong_AsLong",
        legacyName: "PyInt_AsLong")

let PyInt_FromLong: @convention(c) (Int) -> PyObjectPointer =
    PythonLibrary.loadSymbol(
        name: "PyLong_FromLong",
        legacyName: "PyInt_FromLong")

let PyInt_AsUnsignedLongMask: @convention(c) (PyObjectPointer) -> UInt =
    PythonLibrary.loadSymbol(
        name: "PyLong_AsUnsignedLongMask",
        legacyName: "PyInt_AsUnsignedLongMask")

let PyInt_FromSize_t: @convention(c) (UInt) -> PyObjectPointer =
    PythonLibrary.loadSymbol(
        name: "PyLong_FromUnsignedLong",
        legacyName: "PyInt_FromSize_t")

let PyString_AsString: @convention(c) (PyObjectPointer) -> PyCCharPointer? =
    PythonLibrary.loadSymbol(
        name: "PyUnicode_AsUTF8",
        legacyName: "PyString_AsString")

let PyString_FromStringAndSize: @convention(c) (
    PyCCharPointer?, Int) -> (PyObjectPointer?) =
    PythonLibrary.loadSymbol(
        name: "PyUnicode_DecodeUTF8",
        legacyName: "PyString_FromStringAndSize")

let PyBytes_FromStringAndSize: @convention(c) (
    PyCCharPointer?, Int) -> (PyObjectPointer?) =
    PythonLibrary.loadSymbol(
        name: "PyBytes_FromStringAndSize",
        legacyName: "PyString_FromStringAndSize")

let PyBytes_AsStringAndSize: @convention(c) (
    PyObjectPointer,
    UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
    UnsafeMutablePointer<Int>?) -> CInt =
    PythonLibrary.loadSymbol(
        name: "PyBytes_AsStringAndSize",
        legacyName: "PyString_AsStringAndSize")

let _Py_ZeroStruct: PyObjectPointer =
    PythonLibrary.loadSymbol(name: "_Py_ZeroStruct")

let _Py_TrueStruct: PyObjectPointer =
    PythonLibrary.loadSymbol(name: "_Py_TrueStruct")

let PyBool_Type: PyObjectPointer =
    PythonLibrary.loadSymbol(name: "PyBool_Type")

let PySlice_Type: PyObjectPointer =
    PythonLibrary.loadSymbol(name: "PySlice_Type")

let PyNumber_Add: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_Add")

let PyNumber_Subtract: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_Subtract")

let PyNumber_Multiply: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_Multiply")

let PyNumber_MatrixMultiply: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_MatrixMultiply")

let PyNumber_FloorDivide: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_FloorDivide")

let PyNumber_TrueDivide: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_TrueDivide")

let PyNumber_Remainder: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_Remainder")

let PyNumber_Power: @convention(c) (PyObjectPointer?, PyObjectPointer?, PyObjectPointer?) -> PyObjectPointer? =
    PythonLibrary.loadSymbol(name: "PyNumber_Power")

let PyNumber_Negative: PyUnaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_Negative")

let PyNumber_Positive: PyUnaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_Positive")

let PyNumber_Invert: PyUnaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_Invert")

let PyNumber_Lshift: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_Lshift")

let PyNumber_Rshift: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_Rshift")

let PyNumber_And: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_And")

let PyNumber_Xor: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_Xor")

let PyNumber_Or: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_Or")

let PyNumber_InPlaceAdd: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_InPlaceAdd")

let PyNumber_InPlaceSubtract: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_InPlaceSubtract")

let PyNumber_InPlaceMultiply: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_InPlaceMultiply")

let PyNumber_InPlaceMatrixMultiply: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_InPlaceMatrixMultiply")

let PyNumber_InPlaceFloorDivide: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_InPlaceFloorDivide")

let PyNumber_InPlaceTrueDivide: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_InPlaceTrueDivide")

let PyNumber_InPlaceRemainder: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_InPlaceRemainder")

let PyNumber_InPlacePower: @convention(c) (PyObjectPointer?, PyObjectPointer?, PyObjectPointer?) -> PyObjectPointer? =
    PythonLibrary.loadSymbol(name: "PyNumber_InPlacePower")

let PyNumber_InPlaceLshift: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_InPlaceLshift")

let PyNumber_InPlaceRshift: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_InPlaceRshift")

let PyNumber_InPlaceAnd: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_InPlaceAnd")

let PyNumber_InPlaceOr: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_InPlaceOr")

let PyNumber_InPlaceXor: PyBinaryOperation =
    PythonLibrary.loadSymbol(name: "PyNumber_InPlaceXor")

let PySequence_Contains: @convention(c) (PyObjectPointer?, PyObjectPointer?) -> Int32 =
    PythonLibrary.loadSymbol(name: "PySequence_Contains")
