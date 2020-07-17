//
//  LambdaBuilder.h
//  DataFrame
//
//  Created by RedPanda on 2-Jul-20.
//  Copyright © 2020 strictlyswift. All rights reserved.
//

#ifndef LambdaBuilder_h
#define LambdaBuilder_h

#include <stdio.h>
#include <Python/Python.h>
int initialisePythonLibrary(void* libraryHandle);

long int parseArgsToLongInt(PyObject *args, long int *error);
char* parseArgsToString(PyObject *args, long int *error);
PyObject* parseArgsToObject(PyObject *args, long int *error);
double parseArgsToDouble(PyObject *args, long int *error);
PyObject* parseArgsToObjectPair(PyObject *args, PyObject **objectB, long int *error);
PyObject* parseArgsToObjectTriple(PyObject *args, PyObject **objectB, PyObject **objectC,  long int *error);

PyObject* wrapLongInt(long int value);
PyObject* wrapString(const char* value);
PyObject* wrapObject(PyObject* value);
PyObject* wrapDouble(double value);
PyObject* wrapBool(long int value);

// Shims for useful Python library functions
//PyCFunction copyPyCFnPtr(PyCFunction p);
//PyObject* createModuleFunc(PyMethodDef* methodDef, const char* name);
const char* stringFromPythonObject(PyObject* p);
PyObject * getPyUnicode_FromString (const char *u);
PyObject* createPyCFunction(PyMethodDef* ml, PyObject* data);

void debug_showAddress(const char* varName, void* value);

#endif /* LambdaBuilder_h */
