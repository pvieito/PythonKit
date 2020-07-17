//
//  PythonLambda.swift
//  
//
//  Created by strictlyswift on 7/6/20.
//

import PythonLambdaSupport

let METH_VARARGS  = Int32(0x0001)

/// Allows Swift functions to be represented as Python lambdas. Note that you can use the typealias 𝝺 for `PythonLambda`, as per this documentation, because it looks nice. PythonLambda is only available on Python versions > 3.
///
/// Example:
///
/// The Python code `map(lambda(x:x*2), [10,12,14] )`  could be written as:
///
///         Python.map( 𝝺{x in x*2} , [10,12,14] ) // [20,24,28]
///
///
/// or alternatively, without the special character:
///
///         Python.map( PythonLambda {x in x*2} , [10,12,14] ) // [20,24,28]
///
/// There are a number of limitations, not least that only a select number of function shapes are supported. These are:
/// - (Int) -> Int
/// - (String) -> String
/// - (String) -> Int
/// - (Int) -> String
/// - (Double) -> Double
/// - (Double) -> Int
/// - (Double) -> String
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
/// - (PythonObject, PythonObject) -> PythonObject
/// - (PythonObject, PythonObject, PythonObject) -> PythonObject
///
/// For additional flexibility, see `PythonStringLambda`.
///
/// Secondly, note that creating a lambda will cause a (small) memory leak. In the *vast* majority of cases, the memory used by a lambda is so small (a few bytes) it's not worth being concerned about.  Where you are concerned about memory leaks, however, eg for large numbers of lambda calls in a loop, there are two solutions:
/// 1. Create the lambda as a named variable before the loop; and then call `dealloc` on the variable afterwards. Eg:
///
///
///        let tripler = 𝝺{x in x*3}  // nb: creating 𝝺 causes a leak
///        for _ in 1...1000 {   df.apply( tripler )  }
///        tripler.dealloc() // stop the leak 🚰
///
/// 2. Use the auto-deallocating function `withDeallocating`, or the equivalent custom operator `>>>`. This allows you to create and apply a lambda to a closure, and automatically deallocates it the lambda once the closure has executed. For example:
///
///
///        for _ in 1...1000 {
///            𝝺{ Int($0) } >>> { m in Python.map(m , [3.4, 2.4, 1.2] )  }
///        }
///
///
///  or exactly equivalently, but without the custom operator and the 𝝺 character:
///
///
///        for _ in 1...1000 {
///            withDeallocating( PythonLambda{ Int($0) }, in: { m in Python.map(m , [3.4, 2.4, 1.2] )  } )
///        }
///
/// Lastly, note that creation of lambdas is *not* thread-safe. Lambdas are created directly into the
/// Python runtime and given a unique identifier. Multi-threading may interrupt the creation of this
/// unique identifier. If you create lambdas on multiple threads you need to synchronize them to ensure
/// the identifier remains unique.
///
public typealias 𝝺 = PythonLambda

/// Allows Swift functions to be represented as Python lambdas. Note that you can use the typealias 𝝺 for `PythonLambda`, as per this documentation, because it looks nice. PythonLambda is only available on Python versions > 3.
///
/// Example:
///
/// The Python code `map(lambda(x:x*2), [10,12,14] )`  would be written as:
///
///         Python.map( 𝝺{x in x*2} , [10,12,14] ) // [20,24,28]
///
///
/// or alternatively, without the special character:
///
///         Python.map( PythonLambda {x in x*2} , [10,12,14] ) // [20,24,28]
///
///
/// There are a number of limitations, not least that only a select number of one-parameter function shapes are supported. These are:
/// - (Int) -> Int
/// - (String) -> String
/// - (String) -> Int
/// - (Int) -> String
/// - (Double) -> Double
/// - (Double) -> Int
/// - (Double) -> String
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
/// - (PythonObject, PythonObject) -> PythonObject
/// - (PythonObject, PythonObject, PythonObject) -> PythonObject
///
///
/// For additional flexibility, see `PythonStringLambda`.
///
/// Secondly, note that creating a lambda will cause a (small) memory leak. In the *vast* majority of cases, the memory used by a lambda is so small (a few bytes) it's not worth being concerned about. However, where you are concerned about memory leaks, eg for large numbers of lambda calls in a loop, there are two solutions:
/// 1. Create the lambda as a named variable before the loop; and then call `dealloc` on the variable afterwards. Eg:
///
///
///        let tripler = 𝝺{x in x*3}  // nb: creating 𝝺 causes a leak
///        for _ in 1...1000 {   df.apply( tripler )  }
///        tripler.dealloc() // stop the leak 🚰
///
/// 2. Use the auto-deallocating function `withDeallocating`, or the equivalent custom operator `>>>`. This allows you to create and apply a lambda to a closure, and automatically deallocates it the lambda once the closure has executed. For example:
///
///
///        𝝺{ Int($0) } >>> { m in Python.map(m , [3.4, 2.4, 1.2] )  }
///
///
///  or exactly equivalently, but without the custom operator and the 𝝺 character:
///
///
///       withDeallocating( PythonLambda{ Int($0) }, in: { m in Python.map(m , [3.4, 2.4, 1.2] )  } )
///
///
///
/// Lastly, note that creation of lambdas is *not* thread-safe. Lambdas are created directly into the
/// Python runtime and given a unique identifier. Multi-threading may interrupt the creation of this
/// unique identifier. If you create lambdas on multiple threads you need to synchronize them to ensure
/// the identifier remains unique.
///
public class PythonLambda {
    let backend: PythonLambdaSupport
    public let py: PythonObject
    private static var lambdaCounter = 0
    
    public init( _ fn: @escaping (Int) -> Int) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        self.backend = PythonLambdaSupport(fn, name: name)
        self.py = PythonObject(self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (String) -> String) {
        let name = "lmb\(Self.lambdaUniqueName())"
        self.backend = PythonLambdaSupport(fn, name: name)
        
        self.py = PythonObject(self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (String) -> Int) {
        let name = "lmb\(Self.lambdaUniqueName())"
        self.backend = PythonLambdaSupport(fn, name: name)
        
        self.py = PythonObject(self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (Int) -> String) {
        let name = "lmb\(Self.lambdaUniqueName())"
        self.backend = PythonLambdaSupport(fn, name: name)
        
        self.py = PythonObject(self.backend.lambdaPointer )
    }
    
    
    public init( _ fn: @escaping (Double) -> Double) {
        let name = "lmb\(Self.lambdaUniqueName())"
        self.backend = PythonLambdaSupport(fn, name: name)
        
        self.py = PythonObject(self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (Double) -> Int) {
        let name = "lmb\(Self.lambdaUniqueName())"
        self.backend = PythonLambdaSupport(fn, name: name)
        
        self.py = PythonObject(self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (Double) -> String) {
        let name = "lmb\(Self.lambdaUniqueName())"
        self.backend = PythonLambdaSupport(fn, name: name)
        
        self.py = PythonObject(self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (Int) -> Bool) {
        let name = "lmb\(Self.lambdaUniqueName())"
            
        self.backend = PythonLambdaSupport(fn, name: name)
        self.py = PythonObject(self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (String) -> Bool) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        self.backend = PythonLambdaSupport(fn, name: name)
        self.py = PythonObject(self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (Double) -> Bool) {
        let name = "lmb\(Self.lambdaUniqueName())"

        self.backend = PythonLambdaSupport(fn, name: name)
        self.py = PythonObject(self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (Bool) -> Int) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { i in
            fn( i == 0 ? false : true)
        }
            
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (Bool) -> Bool) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { i in
            fn( i == 0 ? false : true)
        }
            
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (Bool) -> String) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { i in
            fn( i == 0 ? false : true)
        }
            
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (Bool) -> Double) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { i in
            fn( i == 0 ? false : true)
        }
            
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (PythonObject) -> Int) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { pop in
            fn(PythonObject(PyReference(pop)))
        }
        
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (PythonObject) -> String) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { pop in
            fn(PythonObject(PyReference(pop)))
        }
        
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (PythonObject) -> Double) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { pop in
            fn(PythonObject(PyReference(pop)))
        }
        
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (PythonObject) -> Bool) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { pop in
            fn(PythonObject(PyReference(pop)))
        }
        
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(self.backend.lambdaPointer )
    }

    public init( _ fn: @escaping (PythonObject) -> PythonObject) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { pop in
            fn(PythonObject(PyReference(pop))).checking.ownedPyObject
        }
        
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(self.backend.lambdaPointer )
    }
    
    public init( _ fn: @escaping (PythonObject, PythonObject) -> PythonObject) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { popA, popB in
            fn(PythonObject(PyReference(popA)),PythonObject( PyReference(popB) )).checking.ownedPyObject
        }
        
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(self.backend.lambdaPointer )
    }

    public init( _ fn: @escaping (PythonObject, PythonObject, PythonObject) -> PythonObject) {
        let name = "lmb\(Self.lambdaUniqueName())"
        
        let pfn = { popA, popB, popC in
            fn(PythonObject(PyReference(popA)),PythonObject( PyReference(popB) ),PythonObject( PyReference(popC) )).checking.ownedPyObject
        }
        
        self.backend = PythonLambdaSupport(pfn, name: name)
        self.py = PythonObject(self.backend.lambdaPointer )
    }
    
     private static func lambdaUniqueName() -> String {
        lambdaCounter += 1
         return "\(lambdaCounter)"
     }
    
    /// PythonLambda can't clean up memory properly thanks to the Swift/Python interface
    /// By default it leaks a small amount... 'dealloc' allows you to clean up "named" lambdas.
    /// For "unnamed" lambdas, you may wish to use With𝝺 { } { }   instead.
    public func dealloc() {
        self.backend.dealloc()
    }
}


extension PythonLambda : PythonConvertible {
    public var pythonObject: PythonObject {
        _ = Python // Ensure Python is initialized.
        return self.py
    }
}

/// Helper struct to encapsulate the deallocation of a lambda
private struct PythonLambdaApplication {
    let lambda: 𝝺
    let receiving: (𝝺) -> PythonObject
    
    public init(_ lambda:𝝺, to receiving: @escaping (𝝺) -> PythonObject) {
        self.lambda = lambda
        self.receiving = receiving
    }
    
    public func exec() -> PythonObject {
        let result = receiving(lambda)
        lambda.dealloc()
        return result
    }
}

infix operator >>>

/// Operator which scopes a lambda function to the closure which uses it, ensuring that the lambda is deallocated automatically.
///
/// - Example:
///
///       𝝺{ Int($0) } >>> { m in Python.map(m , [3.4, 2.4, 1.2] )  }
/// Will create a lambda function `{ Int($0) } `  and then apply it to the code in the the closure `{ m in Python.map(m , [3.4, 2.4, 1.2] )  }`.  Once the closure executes, the lambda will be deallocated.
/// - See Also: `withDeallocating` which is the same functionality but without the custom operator.
public func >>>(lambda:𝝺, receiving: @escaping (𝝺) -> PythonObject) -> PythonObject {
    return PythonLambdaApplication(lambda, to: receiving).exec()
}

/// Scopes a lambda function to the closure which uses it, ensuring that the lambda is deallocated automatically.
///
/// - Example
///
///          withDeallocating( PythonLambda{ Int($0) }, in: { m in Python.map(m , [3.4, 2.4, 1.2] )  } )
/// Will create a lambda function `{ Int($0) } `  and then apply it to the code in the the closure `{ m in Python.map(m , [3.4, 2.4, 1.2] )  }`.  Once the closure executes, the lambda will be deallocated.
/// - See Also: `>>>` which is the same functionality but with a  custom operator.
public func withDeallocating(_ lambda:PythonLambda, in receiving: @escaping (PythonLambda) -> PythonObject) -> PythonObject {
    return PythonLambdaApplication(lambda, to: receiving).exec()
}
