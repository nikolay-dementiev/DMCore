import DMCore
import DMCoreTesting
import XCTest

final class TracingHelpersTests: XCTestCase {
    func test_helpersWithoutADetail_recordNoDetail() {
        let sut = makeSUT()

        let interval = sut.beginInterval("run")
        sut.emitEvent("retry")
        sut.endInterval(interval)

        XCTAssertEqual(sut.calls, [
            .begin("run", .none, interval: 0),
            .event("retry", .none),
            .end("run", .none, interval: 0)
        ])
    }

    func test_measure_workThatReturns_runsInsideOneIntervalAndReturnsTheValue() {
        let sut = makeSUT()

        let value = sut.measure("work") { () -> Int in
            sut.emitEvent("inside")
            return 42
        }

        XCTAssertEqual(value, 42, "the result of the work is returned")
        XCTAssertEqual(sut.calls, expectedCalls("work"), "the work runs between the begin and the end")
    }

    func test_measure_workThatThrows_endsTheIntervalAndRethrows() {
        let sut = makeSUT()

        XCTAssertThrowsError(try sut.measure("work") { () throws -> Int in
            sut.emitEvent("inside")
            throw WorkFailure()
        }, "the error of the work reaches the caller") { error in
            XCTAssertTrue(error is WorkFailure, "the same error is rethrown")
        }

        XCTAssertEqual(sut.calls, expectedCalls("work"), "the interval ends when the work throws")
    }

    func test_measureAsync_workThatReturns_runsInsideOneIntervalAndReturnsTheValue() async {
        let sut = makeSUT()

        let value = await sut.measure("load") { () async -> Int in
            await Task.yield()
            sut.emitEvent("inside")
            return 42
        }

        XCTAssertEqual(value, 42, "the result of the work is returned")
        XCTAssertEqual(sut.calls, expectedCalls("load"), "the interval spans the suspension of the work")
    }

    func test_measureAsync_workThatThrows_endsTheIntervalAndRethrows() async {
        let sut = makeSUT()

        do {
            _ = try await sut.measure("load") { () async throws -> Int in
                await Task.yield()
                sut.emitEvent("inside")
                throw WorkFailure()
            }
            XCTFail("the error of the work reaches the caller")
        } catch {
            XCTAssertTrue(error is WorkFailure, "the same error is rethrown")
        }

        XCTAssertEqual(sut.calls, expectedCalls("load"), "the interval ends when the work throws")
    }

    // The test is a compile-time check too: the work reads state of the actor that is not
    // Sendable, which compiles only while the work runs on the actor of the caller.
    func test_measureAsync_calledOnAnActor_runsTheWorkOnThatActor() async {
        let sut = makeSUT()

        let count = await Owner().countOnce(sut)

        XCTAssertEqual(count, 1, "the work changed the state of the actor")
        XCTAssertEqual(sut.calls, [.begin("owned", .none, interval: 0), .end("owned", .none, interval: 0)],
                       "one interval around the work")
    }

    // MARK: - Helpers

    private func makeSUT() -> TracingSpy {
        TracingSpy()
    }

    private func expectedCalls(_ name: String) -> [TracingSpy.Call] {
        [.begin(name, .none, interval: 0), .event("inside", .none), .end(name, .none, interval: 0)]
    }
}

private struct WorkFailure: Error {}

private final class Counter {
    var value = 0
}

private actor Owner {
    private let counter = Counter()

    func countOnce(_ tracing: any Tracing) async -> Int {
        await tracing.measure("owned") {
            await Task.yield()
            counter.value += 1
        }
        return counter.value
    }
}
