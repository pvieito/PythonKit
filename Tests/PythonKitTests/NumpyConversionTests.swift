import XCTest
import PythonKit


class NumpyConversionTests: XCTestCase {

  static var numpyModule: PythonObject?

  override class func setUp() {
    super.setUp()
    PythonLibrary.useVersion(3)

    numpyModule = try? Python.attemptImport("numpy")
  }

  func testArrayConversion() {
    guard let np = NumpyConversionTests.numpyModule else { return }

    let numpyArrayEmpty = np.array([] as [Float], dtype: np.float32)
    XCTAssertEqual([], Array<Float>(numpy: numpyArrayEmpty))

    let numpyArrayBool = np.array([true, false, false, true])
    XCTAssertEqual([true, false, false, true], Array<Bool>(numpy: numpyArrayBool))

    let numpyArrayFloat = np.ones([6], dtype: np.float32)
    XCTAssertEqual(Array(repeating: 1, count: 6), Array<Float>(numpy: numpyArrayFloat))

    let numpyArrayInt32 = np.array([-1, 4, 25, 2018], dtype: np.int32)
    XCTAssertEqual([-1, 4, 25, 2018], Array<Int32>(numpy: numpyArrayInt32))

    let numpyArray2D = np.ones([2, 3])
    XCTAssertNil(Array<Float>(numpy: numpyArray2D))

    let numpyArrayStrided = np.array([[1, 2], [1, 2]], dtype: np.int32)[
        Python.slice(Python.None), 1]
    // Assert that the array has a stride, so that we're certainly testing a
    // strided array.
    XCTAssertNotEqual(numpyArrayStrided.__array_interface__["strides"], Python.None)
    XCTAssertEqual([2, 2], Array<Int32>(numpy: numpyArrayStrided))
  }
}
