//
//  LambdaBuilder.c
//  DataFrame
//
//  Created by RedPanda on 2-Jul-20.
//  Copyright © 2020 strictlyswift. All rights reserved.
//

#include "include/LambdaBuilder.h"
#include <dlfcn.h>

static void* _pythonLibraryHandle;
int (*pyarg_parsetuple)(PyObject *args, const char *format, ...);
PyObject* (*py_buildvalue)(const char *format, ...);
const char* (*pyunicode_asutf8)(PyObject*);
PyObject* (*pyunicode_fromstring)(const char*);
PyObject* (*py_createPyCFunction)(PyMethodDef*, PyObject*, PyObject*);
PyObject* (*py_boolfromlong)(long v);

int initialisePythonLibrary(void* libraryHandle) {
    _pythonLibraryHandle = libraryHandle;
#ifdef _WIN32
    pyarg_parsetuple = GetProcAddress((HINSTANCE__)libraryHandle,"PyArg_ParseTuple");
    py_buildvalue = GetProcAddress((HINSTANCE__)libraryHandle, "Py_BuildValue");
    pyunicode_asutf8 = GetProcAddress((HINSTANCE__)libraryHandle, "PyUnicode_AsUTF8");
    pyunicode_fromstring = GetProcAddress((HINSTANCE__)libraryHandle, "PyUnicode_FromString");
    py_boolfromlong = GetProcAddress((HINSTANCE__)libraryHandle, "PyBool_FromLong");
    py_createPyCFunction = GetProcAddress((HINSTANCE__)libraryHandle, "PyCFunction_NewEx");
#else
    pyarg_parsetuple = dlsym(_pythonLibraryHandle, "PyArg_ParseTuple");
    py_buildvalue = dlsym(_pythonLibraryHandle, "Py_BuildValue");
    pyunicode_asutf8 = dlsym(_pythonLibraryHandle, "PyUnicode_AsUTF8");
    pyunicode_fromstring = dlsym(_pythonLibraryHandle, "PyUnicode_FromString");
    py_boolfromlong = dlsym(_pythonLibraryHandle, "PyBool_FromLong");
    py_createPyCFunction = dlsym(_pythonLibraryHandle, "PyCFunction_NewEx");
#endif
}

char* parseArgsToString(PyObject *args, long int *error) {
    char* value;
    int result = (*pyarg_parsetuple)(args, "s", &value);
    
    *error = result;
    return value;
}

double parseArgsToDouble(PyObject *args, long int *error) {
    double value;
    int result = (*pyarg_parsetuple)(args, "d", &value);
    
    *error = result;
    return value;
}


long int parseArgsToLongInt(PyObject *args, long int *error) {
    long int value;
    int result = (*pyarg_parsetuple)(args, "l", &value);
    
    *error = result;
    return value;
}

PyObject* parseArgsToObject(PyObject *args, long int *error) {
   PyObject* value;
    int result = (*pyarg_parsetuple)(args, "O", &value);
    
    *error = result;
    return value;
}

PyObject* parseArgsToObjectPair(PyObject *args, PyObject **objectB, long int *error) {
    PyObject* valueA;
    PyObject* valueB;
    int result = (*pyarg_parsetuple)(args, "OO", &valueA, &valueB);
    
    *error = result;
    *objectB = valueB;
    return valueA;
}

PyObject* parseArgsToObjectTriple(PyObject *args, PyObject **objectB, PyObject **objectC,  long int *error) {
    PyObject* valueA;
    PyObject* valueB;
    PyObject* valueC;
    int result = (*pyarg_parsetuple)(args, "OOO", &valueA, &valueB, &valueC);
    
    *error = result;
    *objectB = valueB;
    *objectC = valueC;
    return valueA;
}

PyObject* wrapLongInt(long int value) {
    PyObject* pyValue = (*py_buildvalue)("l",value);
    return pyValue;
}

PyObject* wrapString(const char* value) {
    PyObject* pyValue = (*py_buildvalue)("s",value);
    return pyValue;
}

PyObject* wrapDouble(double value) {
    PyObject* pyValue = (*py_buildvalue)("d",value);
    return pyValue;
}

PyObject* wrapObject(PyObject* value) {
    PyObject* pyValue = (*py_buildvalue)("O",value);
    return pyValue;
}

PyObject* wrapBool(long int value) {
    PyObject* pyValue = (*py_boolfromlong)(value);
    return pyValue;
}
/*
PyObject* createModuleFunc(PyMethodDef* methodDef, const char* name) {
    const char *mymodule = "__builtin__";
  //  void *pyLib = dlopen("/Library/Frameworks/Python.framework/Versions/3.7/lib/libpython3.7.dylib", RTLD_LAZY | RTLD_GLOBAL);
    
    PyObject* (*pyCFunctionNewEx)(PyMethodDef*, PyObject*, PyObject*) = dlsym(pythonLibraryHandle, "PyCFunction_NewEx");
    
    PyObject* (*pyStringFromString)(const char *)  = dlsym(pythonLibraryHandle, "PyUnicode_FromString");
    
    PyObject* (*importModule)(const char*)  = dlsym(pythonLibraryHandle, "PyImport_ImportModule");
    
    PyObject* (*moduleGetDict)(PyObject*)  = dlsym(pythonLibraryHandle, "PyModule_GetDict");
    
    int (*dictSetItemString)(PyObject*, const char *, PyObject*) = dlsym(pythonLibraryHandle, "PyDict_SetItemString");
    
  //  PyObject* usrPtr = (*pyStringFromString)(name);
    PyObject* modname = (*pyStringFromString)("builtins");
    
    PyObject* methodName = (*pyStringFromString)(name);

    PyObject* mod = (*importModule)("builtins");
    PyObject* dict = (*moduleGetDict)(mod);

    
    PyObject* fnc = (*pyCFunctionNewEx)(methodDef, methodName, modname);
    
    (*dictSetItemString)(dict, name, fnc);
    
    return fnc;

}
*/
const char* stringFromPythonObject(PyObject* p) {
    return (*pyunicode_asutf8)(p);
}
/*
PyCFunction copyPyCFnPtr(PyCFunction p) {
    PyCFunction newPtr = (PyCFunction) malloc(sizeof(PyCFunction));
    memcpy(newPtr, p, sizeof(PyCFunction));
    return newPtr;
}
*/
PyObject * getPyUnicode_FromString (const char *u) {
    if (pyunicode_fromstring == NULL) {
        printf("Lambda functions not available on Python 2!\n");
        exit(1);
    }
    return (*pyunicode_fromstring)(u);
}

PyObject* createPyCFunction(PyMethodDef* ml, PyObject* data) {
    return (*py_createPyCFunction)(ml, data, NULL);
}

void debug_showAddress(const char* varName, void* value) {
    printf("variable %s has value %#llx\n", varName, (unsigned long long)value);
}

//PyObject* addFunction(PyMethodDef *method, PyObject* callback) {
//    return (void*)PyCFunction_New(method, NULL);
//    //return PyCFunction_New(&donothing_ml, NULL);
//}

// see here
// https://docs.python.org/2.7//extending/extending.html#calling-pythong-functions-from-c
