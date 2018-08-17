#  PythonKit

Swift framework to interact with Python.

## Requirements

`PythonKit` requires recent [Swift 4.2 toolchains](https://swift.org/download/#swift-42-development) and has been tested both on macOS and Linux.

## Build

You can build `PythonKit` with Swift PM. You can configure the Python version to use in the build process with the `PYTHON` environment variable (for example, `PYTHON=2`). The default build will use Python 3.

Swift PM uses `pkg-config` to find the Python library and headers so it is required.

```bash
$ cd PythonKit
$ swift run
[*] PYTHON=2 Python 2.7
[ ] Executable: /usr/bin/python
[ ] Version: 2.7.12
$ swift package clean
$ swift run
[*] Python 3.6
[ ] Executable: /usr/bin/python3
[ ] Version: 3.6.3
```

## Usage

Add the following dependency to your Swift PM `Package.swift` manifest:

```swift
.package(url: "https://github.com/pvieito/PythonKit.git", .branch("master")),
```

## Example

Some Python code like this:

```python
import sys

print(f"Python {sys.version_info.major}.{sys.version_info.minor}")
print(f"Python Executable: {sys.executable}")
print(f"Python Version: {sys.version}")
```

Can be implemented in Swift through PythonKit with the following code:

```swift
import PythonKit

let sys = try Python.import("sys")

print("Python \(sys.version_info.major).\(sys.version_info.minor)")
print("Python Executable: \(sys.executable)")
print("Python Version: \(sys.version)")
```

## Notes

- `PythonGlue.swift` is code from the [Swift for TensorFlow project](https://github.com/tensorflow/swift).
