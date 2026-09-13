import XCTest
import PythonKit

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class PythonAsyncTests: XCTestCase {
    private var canUseAsyncPython: Bool {
        let versionMajor = Python.versionInfo.major
        let versionMinor = Python.versionInfo.minor
        return (versionMajor == 3 && versionMinor >= 13) || versionMajor > 3
    }

    func testAsyncSleep() async throws {
        guard canUseAsyncPython else { return }
        let sleep = Python.import("asyncio").sleep
        let result = try await sleep.throwing.dynamicallyCall(withArguments: 0)
        XCTAssertEqual(result, Python.None)
    }

    func testAsyncFunctionWithReturn() async throws {
        guard canUseAsyncPython else { return }
        let builtins = Python.import("builtins")
        let globals: PythonObject = [:]
        builtins.exec("""
        import asyncio

        async def add_numbers(a, b):
            await asyncio.sleep(0.001)
            return a + b
        """, globals)

        let addNumbers = globals["add_numbers"]
        let sumResult = try await addNumbers.throwing.dynamicallyCall(withArguments: 21, 21)
        XCTAssertEqual(Int(sumResult), 42)
    }

    func testAsyncFunctionWithKeywords() async throws {
        guard canUseAsyncPython else { return }
        let builtins = Python.import("builtins")
        let globals: PythonObject = [:]
        builtins.exec("""
        import asyncio

        async def format_greeting(greeting, name="World"):
            await asyncio.sleep(0.001)
            return f"{greeting}, {name}!"
        """, globals)

        let formatGreeting = globals["format_greeting"]
        let result = try await formatGreeting.throwing.dynamicallyCall(
            withKeywordArguments: ["greeting": "Hello", "name": "Swift"]
        )
        XCTAssertEqual(String(result), "Hello, Swift!")
    }

    func testAsyncFunctionWithCallback() async throws {
        guard canUseAsyncPython else { return }
        let builtins = Python.import("builtins")
        let globals: PythonObject = [:]
        builtins.exec("""
        import asyncio

        async def process_data(data, callback):
            await asyncio.sleep(0.001)
            result = f"processed: {data}"
            if callback is not None:
                callback(result)
            return result
        """, globals)

        var callbackCalled = false
        var callbackValue: String? = nil

        let swiftCallback = PythonFunction { args in
            callbackCalled = true
            callbackValue = String(args[0])
            return Python.None
        }

        let processData = globals["process_data"]
        let result = try await processData.throwing.dynamicallyCall(
            withArguments: "sample_input", swiftCallback
        )

        XCTAssertEqual(String(result), "processed: sample_input")
        XCTAssertTrue(callbackCalled)
        XCTAssertEqual(callbackValue, "processed: sample_input")
    }

    func testAsyncFunctionWithMultipleCallbacks() async throws {
        guard canUseAsyncPython else { return }
        let builtins = Python.import("builtins")
        let globals: PythonObject = [:]
        builtins.exec("""
        import asyncio

        async def stream_items(items, on_item, on_complete):
            for item in items:
                await asyncio.sleep(0.001)
                on_item(item)
            on_complete(len(items))
            return len(items)
        """, globals)

        var receivedItems: [Int] = []
        var totalCount: Int? = nil

        let onItem = PythonFunction { args in
            if let val = Int(args[0]) {
                receivedItems.append(val)
            }
            return Python.None
        }

        let onComplete = PythonFunction { args in
            totalCount = Int(args[0])
            return Python.None
        }

        let streamItems = globals["stream_items"]
        let count = try await streamItems.throwing.dynamicallyCall(
            withArguments: [10, 20, 30], onItem, onComplete
        )

        XCTAssertEqual(Int(count), 3)
        XCTAssertEqual(receivedItems, [10, 20, 30])
        XCTAssertEqual(totalCount, 3)
    }

    func testAsyncFunctionException() async throws {
        guard canUseAsyncPython else { return }
        let builtins = Python.import("builtins")
        let globals: PythonObject = [:]
        builtins.exec("""
        import asyncio

        async def fail_task():
            await asyncio.sleep(0.001)
            raise ValueError("Something went wrong in async execution")
        """, globals)

        let failTask = globals["fail_task"]
        do {
            _ = try await failTask.throwing.dynamicallyCall()
            XCTFail("Expected async call to throw PythonError.exception")
        } catch PythonError.exception(let error, _) {
            XCTAssertEqual(String(error.__class__.__name__), "ValueError")
            XCTAssertTrue(String(describing: error).contains("Something went wrong in async execution"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testAwaitResultDirectlyOnCoroutine() async throws {
        guard canUseAsyncPython else { return }
        let builtins = Python.import("builtins")
        let globals: PythonObject = [:]
        builtins.exec("""
        import asyncio

        async def get_value():
            await asyncio.sleep(0.001)
            return 99
        """, globals)

        let getValue = globals["get_value"]
        let coroutine = getValue()
        let result = try await coroutine.awaitResult()
        XCTAssertEqual(Int(result), 99)
    }

    func testAwaitResultOnNonAwaitable() async throws {
        guard canUseAsyncPython else { return }
        let number: PythonObject = 42
        let result = try await number.awaitResult()
        XCTAssertEqual(Int(result), 42)
    }
}
