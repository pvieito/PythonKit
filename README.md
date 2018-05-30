#  PythonKit

Swift framework to interact with Python.

## Requirements

`PythonKit` requires Swift 4.2 and has been tested both on macOS and Linux.  

## Usage

Some Python code like this:

```python
import sys

print("Python {}.{}".format(sys.version_info.major, sys.version_info.minor))
print("Python Path: {}".format(sys.path[0]))
print("Python Version: {}".format(sys.version))
```

Can be implemented in Swift through PythonKit with the following code:

```swift
import PythonKit

let sys = try Python.import("sys")

print("Python \(sys.version_info.major).\(sys.version_info.minor)")
print("Python Path: \(sys.path[0])")
print("Python Version: \(sys.version)")
```

## Notes

- `PythonGlue.swift` is code from the [Swift for TensorFlow project](https://github.com/tensorflow/swift).
