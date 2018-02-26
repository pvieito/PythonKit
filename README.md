#  PythonKit

Swift framework to interact with Python.

## Requirements

`PythonKit` requires Swift 4.1 and/or Xcode 9.3 and has been tested both on macOS and Linux.  

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

let sys = try! Python.import("sys")

print("Python Path: \(sys.get(member: "path")[0])")
print("Python Version: \(sys.get(member: "version"))")
```

## Notes

- `PythonGlue.swift` is code from Chris Lattner [Python Interoperation](https://forums.swift.org/t/swift-python-interop-library-xcode-9-3b3-edition/10242) playground.
- Hopefully PythonKit could be superseeded by [Dynamic Member Lookup](https://github.com/apple/swift-evolution/blob/master/proposals/0195-dynamic-member-lookup.md), Dynamic Callable and a common Python wrapper in Swift 5.

