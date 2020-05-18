#  PythonKit

Swift framework to interact with Python.

## Requirements

`PythonKit` requires [**Swift 5**](https://swift.org/download/) or higher and has been tested on macOS, Linux and Windows.

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

## Build & Run

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

If `PythonKit` cannot find and load the Python library you can set the `PYTHON_LOADER_LOGGING` environment variable to know from which locations `PythonKit` is trying to load the library:

```
$ PYTHON_LOADER_LOGGING=TRUE PYTHON_VERSION=3.8 PythonTool
Loading symbol 'Py_Initialize' from the Python library...
Trying to load library at 'Python.framework/Versions/3.8/Python'...
Trying to load library at '/usr/local/Frameworks/Python.framework/Versions/3.8/Python'...
Fatal error: Python library not found. Set the PYTHON_LIBRARY environment variable with the path to a Python library.
```

## Notes

- Originally `PythonKit` was based of the `Python` module from the [**Swift for TensorFlow**](https://github.com/tensorflow/swift) project. The mantainers of both projects have been developing them jointly and currently `PythonKit` is distributed as part of the **Swift for TensorFlow** toolchains.
- If you have questions about `PythonKit` you can ask on the [**Swift for TensorFlow Google Group**](https://groups.google.com/a/tensorflow.org/forum/#!forum/swift) or on the [**Swift Forums**](https://forums.swift.org).
