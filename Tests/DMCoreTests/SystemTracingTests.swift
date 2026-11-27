import Dispatch
import DMCore
import DMCoreTesting
import XCTest

/// A signpost cannot be read back in a unit test, so these tests stop at the token.
/// `Scripts/check-signposts.sh` records the signposts with `xctrace` and compares them.
final class SystemTracingTests: XCTestCase {
    func test_beginInterval_categoryThatRecords_returnsATokenWithSomethingToEnd() {
        let sut = makeSUT()

        let interval = sut.beginInterval("work", .none)
        sut.endInterval(interval, .none)

        XCTAssertEqual(interval.name.description, "work", "the token carries the name of the interval")
        XCTAssertNotNil(interval.handle, "an ordinary category records, so there is an interval to end")
    }

    func test_beginInterval_categoryThatRecordsNothing_returnsATokenWithNothingToEnd() {
        // The system keeps this category off while no performance tool asks for it.
        let sut = makeSUT(category: "DynamicTracing")

        let interval = sut.beginInterval("work", .number(1))
        sut.emitEvent("step", .none)
        sut.endInterval(interval, .none)

        XCTAssertNil(interval.handle, "nothing is built while the category is off")
    }

    func test_everyDetail_categoryThatRecords_returnsATokenWithSomethingToEnd() {
        let sut = makeSUT()

        for detail in [TraceDetail.none, .number(.min), .label("done")] {
            let interval = sut.beginInterval("work", detail)
            sut.emitEvent("step", detail)
            sut.endInterval(interval, detail)

            XCTAssertNotNil(interval.handle, "an interval begins with the detail \(detail)")
        }
    }

    // The system stops a Debug build that ends one interval twice, so a failure of the two tests
    // below is a crash of the test process.
    func test_endInterval_sameTokenTwice_doesNotStopTheProcess() {
        let sut = makeSUT()
        let interval = sut.beginInterval("work", .none)

        sut.endInterval(interval, .none)
        sut.endInterval(interval, .label("again"))

        XCTAssertNotNil(interval.handle)
    }

    func test_endInterval_sameTokenFromManyThreadsAtOnce_doesNotStopTheProcess() {
        let sut = makeSUT()

        let intervals = (0..<20_000).map { _ in sut.beginInterval("work", .none) }

        // Every thread walks the same tokens. The ones behind find nothing to end and catch up, so
        // the threads keep meeting inside one end.
        DispatchQueue.concurrentPerform(iterations: 8) { _ in
            for interval in intervals {
                sut.endInterval(interval, .none)
            }
        }
    }

    func test_endInterval_tokenFromAnotherType_doesNotStopTheProcess() {
        let sut = makeSUT()

        sut.endInterval(TracingSpy().beginInterval("work", .none), .none)
        sut.endInterval(NoTracing().beginInterval("work", .none), .number(1))
    }

    // MARK: - Helpers

    private func makeSUT(category: String = "tests") -> SystemTracing {
        SystemTracing(subsystem: "DMCoreTests", category: category)
    }
}
