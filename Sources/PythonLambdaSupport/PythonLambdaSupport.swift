import libpylamsupport


let METH_VARARGS  = Int32(0x0001)
typealias PyObjectPointer = UnsafeMutableRawPointer
/// Allows Swift functions to be represented as Python lambdas.
///
/// There are a number of limitations, not least that only a limited number of function shapes are supported. These are:
/// - (Int) -> Int
/// - (String) -> String
/// - (String) -> Int
/// - (Int) -> String
/// - (Double) -> Double
/// - (Int) -> Bool
/// - (String) -> Bool
/// - (Double) -> Bool
/// - (Bool) -> Int
/// - (Bool) -> String
/// - (Bool) -> Double
/// - (Bool) -> Bool
/// - (PythonObject) -> String
/// - (PythonObject) -> Int
/// - (PythonObject) -> Double
/// - (PythonObject) -> Bool
/// - (PythonObject) -> PythonObject
/// - (PythonObject,PythonObject) -> PythonObject
/// - (PythonObject,PythonObject,PythonObject) -> PythonObject
///
/// For additional flexibility, see `PythonStringLambda`.
///
///
public class PythonLambdaSupport {
    internal static var lambdaIntIntMap: [String: (Int) -> Int] = [:]
    internal static var lambdaStringStringMap: [String:  (String) -> String] = [:]
    internal static var lambdaStringIntMap: [String: (String) -> Int] = [:]
    internal static var lambdaIntStringMap: [String: (Int) -> String] = [:]
    internal static var lambdaDoubleDoubleMap: [String:  (Double) -> Double] = [:]
    internal static var lambdaDoubleIntMap: [String:  (Double) -> Int] = [:]
    internal static var lambdaStringBoolMap: [String:  (String) -> Bool] = [:]
    internal static var lambdaIntBoolMap: [String:  (Int) -> Bool] = [:]
    internal static var lambdaDoubleBoolMap: [String:  (Double) -> Bool] = [:]
    internal static var lambdaObjectBoolMap: [String:  (PyObjectPointer) -> Bool] = [:]
    internal static var lambdaDoubleStringMap: [String:  (Double) -> String] = [:]
    internal static var lambdaIntDoubleMap: [String:  (Int) -> Double] = [:]
    internal static var lambdaObjectObjectMap: [String:  (PyObjectPointer) -> PyObjectPointer] = [:]
    internal static var lambdaObjectObjectObjectMap: [String:  (PyObjectPointer,PyObjectPointer) -> PyObjectPointer] = [:]
    internal static var lambdaObjectObjectObjectObjectMap: [String:  (PyObjectPointer,PyObjectPointer,PyObjectPointer) -> PyObjectPointer] = [:]
    internal static var lambdaObjectStringMap: [String:  (PyObjectPointer) -> String] = [:]
    internal static var lambdaObjectDoubleMap: [String:  (PyObjectPointer) -> Double] = [:]
    internal static var lambdaStringObjectMap: [String:  (String) -> PyObjectPointer] = [:]
    internal static var lambdaObjectIntMap: [String:  (PyObjectPointer) -> Int] = [:]

    public static func initialise( withLibrary lib: UnsafeMutableRawPointer) {
        initialisePythonLibrary(lib)
    }
    
    
    private let name: String // MUST be unique
    private var methodDef: UnsafeMutablePointer<PyMethodDef>
    private let pythonLambda: PyObjectPointer
    
    public init( _ fn: @escaping (Int) -> Int, name: String) {
        self.name = name
        self.methodDef = Self.methodDefFor(
            name: name,
            method: pyIntIntCaller
        )
        self.pythonLambda = Self.lambdaBuilder(methodDefPtr: self.methodDef, name: name)
        Self.lambdaIntIntMap[name] = fn
    }
    
    public init( _ fn: @escaping (String) -> String, name: String) {
         self.name = name
         self.methodDef = Self.methodDefFor(
             name: name,
             method: pyStringStringCaller
         )
         self.pythonLambda = Self.lambdaBuilder(methodDefPtr: self.methodDef, name: name)

         Self.lambdaStringStringMap[name] = fn
     }
    
    public init( _ fn: @escaping (String) -> Int, name: String) {
         self.name = name
         self.methodDef = Self.methodDefFor(
             name: name,
             method: pyStringIntCaller
         )
         self.pythonLambda = Self.lambdaBuilder(methodDefPtr: self.methodDef, name: name)

         Self.lambdaStringIntMap[name] = fn
     }
    
    public init( _ fn: @escaping (Int) -> String, name: String) {
         self.name = name
         self.methodDef = Self.methodDefFor(
             name: name,
             method: pyIntStringCaller
         )
         self.pythonLambda = Self.lambdaBuilder(methodDefPtr: self.methodDef, name: name)

         Self.lambdaIntStringMap[name] = fn
     }
    
    public init( _ fn: @escaping (Double) -> Double, name: String) {
         self.name = name
         self.methodDef = Self.methodDefFor(
             name: name,
             method: pyDoubleDoubleCaller
         )
         self.pythonLambda = Self.lambdaBuilder(methodDefPtr: self.methodDef, name: name)

         Self.lambdaDoubleDoubleMap[name] = fn
     }
    
    public init( _ fn: @escaping (Double) -> Int, name: String) {
         self.name = name
         self.methodDef = Self.methodDefFor(
             name: name,
             method: pyDoubleIntCaller
         )
         self.pythonLambda = Self.lambdaBuilder(methodDefPtr: self.methodDef, name: name)

         Self.lambdaDoubleIntMap[name] = fn
     }
    
    public init( _ fn: @escaping (Int) -> Bool, name: String) {
         self.name = name
         self.methodDef = Self.methodDefFor(
             name: name,
             method: pyIntBoolCaller
         )
         self.pythonLambda = Self.lambdaBuilder(methodDefPtr: self.methodDef, name: name)

         Self.lambdaIntBoolMap[name] = fn
     }
    
    public init( _ fn: @escaping (String) -> Bool, name: String) {
         self.name = name
         self.methodDef = Self.methodDefFor(
             name: name,
             method: pyStringBoolCaller
         )
         self.pythonLambda = Self.lambdaBuilder(methodDefPtr: self.methodDef, name: name)

         Self.lambdaStringBoolMap[name] = fn
     }
    
    public init( _ fn: @escaping (Double) -> Bool, name: String) {
         self.name = name
         self.methodDef = Self.methodDefFor(
             name: name,
             method: pyDoubleBoolCaller
         )
         self.pythonLambda = Self.lambdaBuilder(methodDefPtr: self.methodDef, name: name)

         Self.lambdaDoubleBoolMap[name] = fn
     }
    
    public init( _ fn: @escaping (UnsafeMutableRawPointer) -> Bool, name: String) {
         self.name = name
         self.methodDef = Self.methodDefFor(
             name: name,
             method: pyObjectBoolCaller
         )
         self.pythonLambda = Self.lambdaBuilder(methodDefPtr: self.methodDef, name: name)

         Self.lambdaObjectBoolMap[name] = fn
     }
    
    public init( _ fn: @escaping (Double) -> String, name: String) {
         self.name = name
         self.methodDef = Self.methodDefFor(
             name: name,
             method: pyDoubleStringCaller
         )
         self.pythonLambda = Self.lambdaBuilder(methodDefPtr: self.methodDef, name: name)

         Self.lambdaDoubleStringMap[name] = fn
     }
    
    public init( _ fn: @escaping (Int) -> Double, name: String) {
         self.name = name
         self.methodDef = Self.methodDefFor(
             name: name,
             method: pyIntDoubleCaller
         )
         self.pythonLambda = Self.lambdaBuilder(methodDefPtr: self.methodDef, name: name)

         Self.lambdaIntDoubleMap[name] = fn
     }
    
    public init( _ fn: @escaping (UnsafeMutableRawPointer) -> Int, name: String) {
         self.name = name
         self.methodDef = Self.methodDefFor(
             name: name,
             method: pyObjectIntCaller
         )
         self.pythonLambda = Self.lambdaBuilder(methodDefPtr: self.methodDef, name: name)

         Self.lambdaObjectIntMap[name] = fn
     }
    
    public init( _ fn: @escaping (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer, name: String) {
         self.name = name
         self.methodDef = Self.methodDefFor(
             name: name,
             method: pyObjectObjectCaller
         )
         self.pythonLambda = Self.lambdaBuilder(methodDefPtr: self.methodDef, name: name)

         Self.lambdaObjectObjectMap[name] = fn
     }
    
    public init( _ fn: @escaping (UnsafeMutableRawPointer,UnsafeMutableRawPointer) -> UnsafeMutableRawPointer, name: String) {
         self.name = name
         self.methodDef = Self.methodDefFor(
             name: name,
             method: pyObjectObjectObjectCaller
         )
         self.pythonLambda = Self.lambdaBuilder(methodDefPtr: self.methodDef, name: name)

         Self.lambdaObjectObjectObjectMap[name] = fn
     }
    
    public init( _ fn: @escaping (UnsafeMutableRawPointer,UnsafeMutableRawPointer,UnsafeMutableRawPointer) -> UnsafeMutableRawPointer, name: String) {
         self.name = name
         self.methodDef = Self.methodDefFor(
             name: name,
             method: pyObjectObjectObjectObjectCaller
         )
         self.pythonLambda = Self.lambdaBuilder(methodDefPtr: self.methodDef, name: name)

         Self.lambdaObjectObjectObjectObjectMap[name] = fn
     }
    
    
    public init( _ fn: @escaping (UnsafeMutableRawPointer) -> String, name: String) {
         self.name = name
         self.methodDef = Self.methodDefFor(
             name: name,
             method: pyObjectStringCaller
         )
         self.pythonLambda = Self.lambdaBuilder(methodDefPtr: self.methodDef, name: name)

         Self.lambdaObjectStringMap[name] = fn
     }
    
    public init( _ fn: @escaping (UnsafeMutableRawPointer) -> Double, name: String) {
         self.name = name
         self.methodDef = Self.methodDefFor(
             name: name,
             method: pyObjectDoubleCaller
         )
         self.pythonLambda = Self.lambdaBuilder(methodDefPtr: self.methodDef, name: name)

         Self.lambdaObjectDoubleMap[name] = fn
     }
    
    public init( _ fn: @escaping (String) -> UnsafeMutableRawPointer, name: String) {
         self.name = name
         self.methodDef = Self.methodDefFor(
             name: name,
             method: pyStringObjectCaller
         )
         self.pythonLambda = Self.lambdaBuilder(methodDefPtr: self.methodDef, name: name)

         Self.lambdaStringObjectMap[name] = fn
     }
    
    private static func methodDefFor( name: String,
                              method: PyCFunction?) -> UnsafeMutablePointer<PyMethodDef> {
        name.utf8CString.withUnsafeBufferPointer { namePtr in
            let methodDef = PyMethodDef(
                ml_name:  namePtr.baseAddress,
                ml_meth: method,
                ml_flags: METH_VARARGS,
                ml_doc: namePtr.baseAddress
            )
            
            return withUnsafePointer(to: methodDef) { methodDefPtr in
            // we take a copy of the method definition, because otherwise Swift will
            // deallocate it for us when the PythonLambda goes out of scope
            // this is a memory leak
                let fnDef = UnsafeMutablePointer<PyMethodDef>.allocate(capacity: 1)
                fnDef.assign(from: methodDefPtr, count: 1)
                
                return fnDef
            }
        }
        

    }
    
    private static func lambdaBuilder( methodDefPtr: UnsafeMutablePointer<PyMethodDef>, name: String) -> PyObjectPointer {
        name.utf8CString.withUnsafeBufferPointer { namePtr in
            let pop = createPyCFunction(methodDefPtr, getPyUnicode_FromString(namePtr.baseAddress))
            return UnsafeMutableRawPointer(pop!)
        }
    }

    public var lambdaPointer: UnsafeMutableRawPointer {
        get { return pythonLambda }
    }
    
    /// Deallocate a lambda function. This has to be done manually.
    public func dealloc() {
        self.methodDef.deallocate()
        
        // Remove dictionary entries. NB only one of these should  actually have an entry as the name should
        // be unique!
        Self.lambdaIntIntMap[self.name] = nil
        Self.lambdaStringStringMap[self.name] = nil
        Self.lambdaStringIntMap[self.name] = nil
        Self.lambdaIntStringMap[self.name] = nil
        Self.lambdaDoubleDoubleMap[self.name] = nil
        Self.lambdaDoubleIntMap[self.name] = nil
        Self.lambdaStringBoolMap[self.name] = nil
        Self.lambdaIntBoolMap[self.name] = nil
        Self.lambdaDoubleBoolMap[self.name] = nil
        Self.lambdaObjectBoolMap[self.name] = nil
        Self.lambdaDoubleStringMap[self.name] = nil
        Self.lambdaIntDoubleMap[self.name] = nil
        Self.lambdaObjectObjectMap[self.name] = nil
        Self.lambdaObjectObjectObjectMap[self.name] = nil
        Self.lambdaObjectObjectObjectObjectMap[self.name] = nil
        Self.lambdaObjectStringMap[self.name] = nil
        Self.lambdaObjectDoubleMap[self.name] = nil
        Self.lambdaStringObjectMap[self.name] = nil
        Self.lambdaObjectIntMap[self.name] = nil
    }
    
    deinit {
    }
}


// has to be at top level so we can get C function pointer to it
func pyIntIntCaller(sself:UnsafeMutablePointer<PyObject>?,
              args: UnsafeMutablePointer<PyObject>?)
    -> UnsafeMutablePointer<PyObject>? {
        guard let lambdaNamePtr = sself else { return nil }
        let lambdaName = String(cString: stringFromPythonObject(lambdaNamePtr))
        
        if let fn = PythonLambdaSupport.lambdaIntIntMap[lambdaName] {
            var error = 0
            let v = parseArgsToLongInt(args, &error)
            if error != 0 {
                let newV = fn(v)
                let iPointer = wrapLongInt(newV)
                return iPointer
            } else {
                return nil
            }
        } else {
            return nil
        }
}

func pyIntStringCaller(sself:UnsafeMutablePointer<PyObject>?,
              args: UnsafeMutablePointer<PyObject>?)
    -> UnsafeMutablePointer<PyObject>? {
        guard let lambdaNamePtr = sself else { return nil }
        let lambdaName = String(cString: stringFromPythonObject(lambdaNamePtr))
        
        if let fn = PythonLambdaSupport.lambdaIntStringMap[lambdaName] {
            var error = 0
            let v = parseArgsToLongInt(args, &error)
            if error != 0 {
                let newV = fn(v)
                return wrapString(newV)
            } else {
                return nil
            }
        } else {
            return nil
        }
}

func pyIntBoolCaller(sself:UnsafeMutablePointer<PyObject>?,
              args: UnsafeMutablePointer<PyObject>?)
    -> UnsafeMutablePointer<PyObject>? {
        guard let lambdaNamePtr = sself else { return nil }
        let lambdaName = String(cString: stringFromPythonObject(lambdaNamePtr))
        
        if let fn = PythonLambdaSupport.lambdaIntBoolMap[lambdaName] {
            var error = 0
            let v = parseArgsToLongInt(args, &error)
            if error != 0 {
                let newV = fn(v)
                let iPointer = wrapBool(newV ? 1 : 0)
                return iPointer
            } else {
                return nil
            }
        } else {
            return nil
        }
}

func pyDoubleDoubleCaller(sself:UnsafeMutablePointer<PyObject>?,
              args: UnsafeMutablePointer<PyObject>?)
    -> UnsafeMutablePointer<PyObject>? {
        guard let lambdaNamePtr = sself else { return nil }
        let lambdaName = String(cString: stringFromPythonObject(lambdaNamePtr))
        
        if let fn = PythonLambdaSupport.lambdaDoubleDoubleMap[lambdaName] {
            var error = 0
            let v = parseArgsToDouble(args, &error)
            if error != 0 {
                let newV = fn(v)
                return wrapDouble(newV)
            } else {
                return nil
            }
        } else {
            return nil
        }
}

func pyIntDoubleCaller(sself:UnsafeMutablePointer<PyObject>?,
              args: UnsafeMutablePointer<PyObject>?)
    -> UnsafeMutablePointer<PyObject>? {
        guard let lambdaNamePtr = sself else { return nil }
        let lambdaName = String(cString: stringFromPythonObject(lambdaNamePtr))
        
        if let fn = PythonLambdaSupport.lambdaIntDoubleMap[lambdaName] {
            var error = 0
            let v = parseArgsToLongInt(args, &error)
            if error != 0 {
                let newV = fn(v)
                return wrapDouble(newV)
            } else {
                return nil
            }
        } else {
            return nil
        }
}

func pyDoubleIntCaller(sself:UnsafeMutablePointer<PyObject>?,
              args: UnsafeMutablePointer<PyObject>?)
    -> UnsafeMutablePointer<PyObject>? {
        guard let lambdaNamePtr = sself else { return nil }
        let lambdaName = String(cString: stringFromPythonObject(lambdaNamePtr))
        
        if let fn = PythonLambdaSupport.lambdaDoubleIntMap[lambdaName] {
            var error = 0
            let v = parseArgsToDouble(args, &error)
            if error != 0 {
                let newV = fn(v)
                return wrapLongInt(newV)
            } else {
                return nil
            }
        } else {
            return nil
        }
}

func pyDoubleBoolCaller(sself:UnsafeMutablePointer<PyObject>?,
              args: UnsafeMutablePointer<PyObject>?)
    -> UnsafeMutablePointer<PyObject>? {
        guard let lambdaNamePtr = sself else { return nil }
        let lambdaName = String(cString: stringFromPythonObject(lambdaNamePtr))
        
        if let fn = PythonLambdaSupport.lambdaDoubleBoolMap[lambdaName] {
            var error = 0
            let v = parseArgsToDouble(args, &error)
            if error != 0 {
                let newV = fn(v)
                return wrapBool(newV ? 1 : 0)
            } else {
                return nil
            }
        } else {
            return nil
        }
}

func pyDoubleStringCaller(sself:UnsafeMutablePointer<PyObject>?,
              args: UnsafeMutablePointer<PyObject>?)
    -> UnsafeMutablePointer<PyObject>? {
        guard let lambdaNamePtr = sself else { return nil }
        let lambdaName = String(cString: stringFromPythonObject(lambdaNamePtr))
        
        if let fn = PythonLambdaSupport.lambdaDoubleStringMap[lambdaName] {
            var error = 0
            let v = parseArgsToDouble(args, &error)
            if error != 0 {
                let newV = fn(v)
                return wrapString(newV)
            } else {
                return nil
            }
        } else {
            return nil
        }
}

func pyStringIntCaller(sself:UnsafeMutablePointer<PyObject>?,
              args: UnsafeMutablePointer<PyObject>?)
    -> UnsafeMutablePointer<PyObject>? {
        guard let lambdaNamePtr = sself else { return nil }
        let lambdaName = String(cString: stringFromPythonObject(lambdaNamePtr))
        
        if let fn = PythonLambdaSupport.lambdaStringIntMap[lambdaName] {
            var error = 0
            if let v = parseArgsToString(args, &error),
                error != 0 {
                let newV = fn(String(cString: v))
                let iPointer = wrapLongInt(newV)
                return iPointer
            } else {
                return nil
            }
        } else {
            return nil
        }
}

func pyStringBoolCaller(sself:UnsafeMutablePointer<PyObject>?,
              args: UnsafeMutablePointer<PyObject>?)
    -> UnsafeMutablePointer<PyObject>? {
        guard let lambdaNamePtr = sself else { return nil }
        let lambdaName = String(cString: stringFromPythonObject(lambdaNamePtr))
        
        if let fn = PythonLambdaSupport.lambdaStringBoolMap[lambdaName] {
            var error = 0
            if let v = parseArgsToString(args, &error),
                error != 0 {
                let newV = fn(String(cString: v))
                let iPointer = wrapBool(newV ? 1 : 0)
                return iPointer
            } else {
                return nil
            }
        } else {
            return nil
        }
}


func pyStringStringCaller(sself:UnsafeMutablePointer<PyObject>?,
              args: UnsafeMutablePointer<PyObject>?)
    -> UnsafeMutablePointer<PyObject>? {
        guard let lambdaNamePtr = sself else { return nil }
        let lambdaName = String(cString: stringFromPythonObject(lambdaNamePtr))
        
        if let fn = PythonLambdaSupport.lambdaStringStringMap[lambdaName] {
            var error = 0
            if let v = parseArgsToString(args, &error),
                error != 0 {
                let newV = fn(String(cString: v))
                let iPointer = wrapString(newV)
                return iPointer
            } else {
                return nil
            }
        } else {
            return nil
        }
}

func pyObjectIntCaller(sself:UnsafeMutablePointer<PyObject>?,
              args: UnsafeMutablePointer<PyObject>?)
    -> UnsafeMutablePointer<PyObject>? {
        guard let lambdaNamePtr = sself else { return nil }
        let lambdaName = String(cString: stringFromPythonObject(lambdaNamePtr))
        
        if let fn = PythonLambdaSupport.lambdaObjectIntMap[lambdaName] {
            var error = 0
            if let v = parseArgsToObject(args, &error),
                error != 0 {
                let newV = fn(v)
                let iPointer = wrapLongInt(newV)
                return iPointer
            } else {
                return nil
            }
        } else {
            return nil
        }
}

func pyObjectBoolCaller(sself:UnsafeMutablePointer<PyObject>?,
              args: UnsafeMutablePointer<PyObject>?)
    -> UnsafeMutablePointer<PyObject>? {
        guard let lambdaNamePtr = sself else { return nil }
        let lambdaName = String(cString: stringFromPythonObject(lambdaNamePtr))
        
        if let fn = PythonLambdaSupport.lambdaObjectBoolMap[lambdaName] {
            var error = 0
            if let v = parseArgsToObject(args, &error),
                error != 0 {
                let newV = fn(v)
                let iPointer = wrapBool(newV ? 1 : 0)
                return iPointer
            } else {
                return nil
            }
        } else {
            return nil
        }
}

func pyObjectStringCaller(sself:UnsafeMutablePointer<PyObject>?,
              args: UnsafeMutablePointer<PyObject>?)
    -> UnsafeMutablePointer<PyObject>? {
        guard let lambdaNamePtr = sself else { return nil }
        let lambdaName = String(cString: stringFromPythonObject(lambdaNamePtr))
        
        if let fn = PythonLambdaSupport.lambdaObjectStringMap[lambdaName] {
            var error = 0
            if let v = parseArgsToObject(args, &error),
                error != 0 {
                let newV = fn(v)
                let iPointer = wrapString(newV)
                return iPointer
            } else {
                return nil
            }
        } else {
            return nil
        }
}

func pyObjectDoubleCaller(sself:UnsafeMutablePointer<PyObject>?,
              args: UnsafeMutablePointer<PyObject>?)
    -> UnsafeMutablePointer<PyObject>? {
        guard let lambdaNamePtr = sself else { return nil }
        let lambdaName = String(cString: stringFromPythonObject(lambdaNamePtr))
        
        if let fn = PythonLambdaSupport.lambdaObjectDoubleMap[lambdaName] {
            var error = 0
            if let v = parseArgsToObject(args, &error),
                error != 0 {
                let newV = fn(v)
                let iPointer = wrapDouble(newV)
                return iPointer
            } else {
                return nil
            }
        } else {
            return nil
        }
}

func pyObjectObjectCaller(sself:UnsafeMutablePointer<PyObject>?,
              args: UnsafeMutablePointer<PyObject>?)
    -> UnsafeMutablePointer<PyObject>? {
        guard let lambdaNamePtr = sself else { return nil }
        let lambdaName = String(cString: stringFromPythonObject(lambdaNamePtr))
        
        if let fn = PythonLambdaSupport.lambdaObjectObjectMap[lambdaName] {
            var error = 0
            if let v = parseArgsToObject(args, &error),
                error != 0 {
                let newV = fn(v)
                let iPointer = wrapObject(newV.assumingMemoryBound(to: PyObject.self))
                return iPointer
            } else {
                return nil
            }
        } else {
            return nil
        }
}

func pyObjectObjectObjectCaller(sself:UnsafeMutablePointer<PyObject>?,
              args: UnsafeMutablePointer<PyObject>?)
    -> UnsafeMutablePointer<PyObject>? {
        guard let lambdaNamePtr = sself else { return nil }
        let lambdaName = String(cString: stringFromPythonObject(lambdaNamePtr))
        
        if let fn = PythonLambdaSupport.lambdaObjectObjectObjectMap[lambdaName] {
            var error = 0
            var objectB: UnsafeMutablePointer<PyObject>?
            if let v = parseArgsToObjectPair(args, &objectB, &error),
                let objectB = objectB,
                error != 0 {
                let newV = fn(v,objectB)
                let iPointer = wrapObject(newV.assumingMemoryBound(to: PyObject.self))
                return iPointer
            } else {
                return nil
            }
        } else {
            return nil
        }
}

func pyObjectObjectObjectObjectCaller(sself:UnsafeMutablePointer<PyObject>?,
              args: UnsafeMutablePointer<PyObject>?)
    -> UnsafeMutablePointer<PyObject>? {
        guard let lambdaNamePtr = sself else { return nil }
        let lambdaName = String(cString: stringFromPythonObject(lambdaNamePtr))
        
        if let fn = PythonLambdaSupport.lambdaObjectObjectObjectObjectMap[lambdaName] {
            var error = 0
            var objectB: UnsafeMutablePointer<PyObject>?
            var objectC: UnsafeMutablePointer<PyObject>?
            if let v = parseArgsToObjectTriple(args, &objectB, &objectC, &error),
                let objectB = objectB,
                let objectC = objectC,
                error != 0 {
                let newV = fn(v,objectB,objectC)
                let iPointer = wrapObject(newV.assumingMemoryBound(to: PyObject.self))
                return iPointer
            } else {
                return nil
            }
        } else {
            return nil
        }
}

func pyStringObjectCaller(sself:UnsafeMutablePointer<PyObject>?,
              args: UnsafeMutablePointer<PyObject>?)
    -> UnsafeMutablePointer<PyObject>? {
        guard let lambdaNamePtr = sself else { return nil }
        let lambdaName = String(cString: stringFromPythonObject(lambdaNamePtr))
        
        if let fn = PythonLambdaSupport.lambdaStringObjectMap[lambdaName] {
            var error = 0
            if let v = parseArgsToString(args, &error),
                error != 0 {
                let newV = fn(String(cString: v))
                let iPointer = wrapObject(newV.assumingMemoryBound(to: PyObject.self))
                return iPointer
            } else {
                return nil
            }
        } else {
            return nil
        }
}
