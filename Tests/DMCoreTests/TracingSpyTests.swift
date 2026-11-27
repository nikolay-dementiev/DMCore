import DMCore
import DMCoreTesting
import XCTest

final class TracingSpyTests: XCTestCase {
    func test_calls_beforeAnyCall_isEmpty() {
        XCTAssertEqual(makeSUT().calls, [])
    }

    func test_calls_severalCalls_recordsThemInOrderAndNumbersTheIntervals() {
        let sut = makeSUT()

        let first = sut.beginInterval("run", .number(1))
        sut.emitEvent("retry", .number(2))
        let second = sut.beginInterval("attempt", .none)
        sut.endInterval(first, .label("success"))
        sut.endInterval(second, .none)

        XCTAssertEqual(sut.calls, [
            .begin("run", .number(1), interval: 0),
            .event("retry", .number(2)),
            .begin("attempt", .none, interval: 1),
            .end("run", .label("success"), interval: 0),
            .end("attempt", .none, interval: 1)
        ], "every call is recorded in order, and each end names the interval it closed")
    }

    func test_endInterval_tokenFromNoTracing_recordsNoInterval() {
        let sut = makeSUT()

        sut.endInterval(NoTracing().beginInterval("run", .none), .none)

        XCTAssertEqual(sut.calls, [.end("run", .none, interval: nil)])
    }

    func test_endInterval_tokenFromAnotherSpy_recordsNoInterval() {
        let sut = makeSUT()
        let other = makeSUT()
        _ = sut.beginInterval("mine", .none)

        sut.endInterval(other.beginInterval("theirs", .none), .none)

        XCTAssertEqual(sut.calls.last, .end("theirs", .none, interval: nil),
                       "the token of another spy closes no interval of this one")
        XCTAssertEqual(other.calls, [.begin("theirs", .none, interval: 0)],
                       "the spy that began the interval records no end")
    }

    func test_calls_intervalsEndedOnOtherTasks_keepsEveryCallAndMatchesEachEnd() async {
        let sut = makeSUT()
        let count = 200

        await withTaskGroup(of: Void.self) { group in
            for number in 0..<count {
                group.addTask {
                    let interval = sut.beginInterval("run", .number(Int64(number)))
                    await Task.detached {
                        sut.endInterval(interval, .number(Int64(number)))
                    }.value
                }
            }
        }

        var begun: [Int: TraceDetail] = [:]
        var ended: [Int: TraceDetail] = [:]
        for call in sut.calls {
            switch call {
            case let .begin(_, detail, interval): begun[interval] = detail
            case let .end(_, detail, interval?): ended[interval] = detail
            case .end, .event: XCTFail("only begins and matched ends are expected, got \(call)")
            }
        }
        XCTAssertEqual(sut.calls.count, count * 2, "no call is lost")
        XCTAssertEqual(begun.keys.sorted(), Array(0..<count), "each interval has a number of its own")
        XCTAssertEqual(ended, begun, "each end closes the interval that began with the same detail")
    }

    // MARK: - Helpers

    private func makeSUT() -> TracingSpy {
        TracingSpy()
    }
}
