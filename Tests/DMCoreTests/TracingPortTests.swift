import DMCore
import XCTest

final class TracingPortTests: XCTestCase {
    func test_detail_sameCaseAndValue_isEqual() {
        XCTAssertEqual(TraceDetail.none, TraceDetail.none, "no detail equals no detail")
        XCTAssertEqual(TraceDetail.number(7), TraceDetail.number(7), "the same number is equal")
        XCTAssertEqual(TraceDetail.label("success"), TraceDetail.label("success"), "the same label text is equal")
    }

    func test_detail_otherCaseOrValue_isNotEqual() {
        XCTAssertNotEqual(TraceDetail.number(7), TraceDetail.number(8), "another number differs")
        XCTAssertNotEqual(TraceDetail.label("success"), TraceDetail.label("failure"), "another label differs")
        XCTAssertNotEqual(TraceDetail.none, TraceDetail.number(0), "no detail is not the number zero")
        XCTAssertNotEqual(TraceDetail.number(1), TraceDetail.label("1"), "a number is not the label of its digits")
        XCTAssertNotEqual(TraceDetail.none, TraceDetail.label(""), "no detail is not an empty label")
    }

    func test_noTracing_beginInterval_returnsATokenWithNothingToEnd() {
        let sut = makeSUT()

        let interval = sut.beginInterval("work", .number(1))
        sut.emitEvent("step", .label("done"))
        sut.endInterval(interval, .none)

        XCTAssertEqual(interval.name.description, "work", "the token carries the name of the interval")
        XCTAssertNil(interval.handle, "nothing listens, so the token holds no handle")
    }

    // MARK: - Helpers

    private func makeSUT() -> NoTracing {
        NoTracing()
    }
}
