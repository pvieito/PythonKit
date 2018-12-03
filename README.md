#  PythonKit

Swift framework to interact with Python.

## Requirements

`PythonKit` requires **Swift 5** or higher and has been tested both on macOS and Linux.

## Usage

Some Python code like this:

```python
import sys

print(f"Python {sys.version_info.major}.{sys.version_info.minor}")
print(f"Python Version: {sys.version}")
print(f"Python Encoding: {sys.getdefaultencoding().upper()}")
```

Can be implemented in Swift through PythonKit with the following code:

```swift
import PythonKit

let sys = try Python.import("sys")

print("Python \(sys.version_info.major).\(sys.version_info.minor)")
print("Python Version: \(sys.version)")
print("Python Encoding: \(sys.getdefaultencoding().upper())")
```

### Swift Package Manager

Add the following dependency to your `Package.swift` manifest:

```swift
.package(url: "https://github.com/pvieito/PythonKit.git", .branch("master")),
```

## Build

`PythonKit` can be built with Swift PM:

```
$ cd PythonKit
$ swift run
[*] Python 3.7
[ ] Version: 3.7.0
```

The Python library will be loaded at runtime, `PythonKit` will try to find the most modern Python version available in the system. You can force a given version with the `PYTHON_VERSION` environment variable or an specific Python library path or name with `PYTHON_LIBRARY`.

```
$ PYTHON_VERSION=3 swift run
[*] Python 3.5
[ ] Version: 3.5.2
$ PYTHON_VERSION=2.7 swift run
[*] Python 2.7
[ ] Version: 2.7.10
$ PYTHON_LIBRARY=libpython3.5.so swift run
[*] Python 3.5
[ ] Version: 3.5.2
$ PYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython2.7.so swift run
[*] Python 2.7
[ ] Version: 2.7.10
```

## Notes

- `Python.swift` is code from the [Swift for TensorFlow project](https://github.com/tensorflow/swift).
