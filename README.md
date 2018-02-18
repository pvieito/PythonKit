#  PythonKit

Swift framework to interact with Python.

## Usage

Some Python code like this:

```python
import sys

print("Python Path: {}".format(sys.path[0]))

print("Python Version: {}".format(sys.version))
```

Can be implemented in Swift through PythonKit with the following code:

```swift
import PythonKit

// import sys
let sysModule = Python.import("sys")

// print("Python Path: {}".format(sys.path[0]))
print("Python Path: \(sysModule.get(member: "path")[0])")

// print("Python Version: {}".format(sys.version))
print("Python Version: \(sysModule.get(member: "version"))")
```

## Note

`PythonGlue.swift` is code from Chris Lattner [Python Interoperation](https://lists.swift.org/pipermail/swift-evolution/Week-of-Mon-20171204/042029.html) playground.

Hopefully PythonKit could be superseeded by [Dynamic Member Lookup](https://github.com/apple/swift-evolution/blob/master/proposals/0195-dynamic-member-lookup.md), Dynamic Callable and a common Python wrapper in Swift 5.

