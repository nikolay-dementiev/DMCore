public import DMCore
import os

/// Records every call of the port, in order, from any thread. For tests only.
public final class TracingSpy: Tracing {
    /// One recorded call. A name is recorded as its text.
    public enum Call: Sendable, Equatable {
        /// An interval began. The spy numbers its intervals from zero.
        case begin(String, TraceDetail, interval: Int)
        /// An interval ended. The number is nil when the token did not come from this spy.
        case end(String, TraceDetail, interval: Int?)
        /// A single point in time.
        case event(String, TraceDetail)
    }

    /// Tells the tokens of this spy from the tokens of another one. A token holds it, so no later
    /// spy can take its place while the token lives.
    private final class Identity: Sendable {}

    private struct Handle: Sendable {
        let spy: Identity
        let interval: Int
    }

    private struct Record: Sendable {
        var calls: [Call] = []
        var nextInterval = 0
    }

    private let identity = Identity()
    private let record = OSAllocatedUnfairLock(initialState: Record())

    /// Creates a spy with nothing recorded.
    public init() {}

    /// The calls so far, in the order they arrived.
    public var calls: [Call] {
        record.withLock { $0.calls }
    }

    /// Records the begin and returns a token with the number of the interval.
    public func beginInterval(_ name: StaticString, _ detail: TraceDetail) -> TraceInterval {
        let text = name.description
        let interval = record.withLock { record in
            let interval = record.nextInterval
            record.nextInterval += 1
            record.calls.append(.begin(text, detail, interval: interval))
            return interval
        }
        return TraceInterval(name: name, handle: Handle(spy: identity, interval: interval))
    }

    /// Records the end with the number of the interval that the token closes.
    public func endInterval(_ interval: TraceInterval, _ detail: TraceDetail) {
        let handle = interval.handle as? Handle
        let number = handle?.spy === identity ? handle?.interval : nil
        let call = Call.end(interval.name.description, detail, interval: number)
        record.withLock { $0.calls.append(call) }
    }

    /// Records the event.
    public func emitEvent(_ name: StaticString, _ detail: TraceDetail) {
        let call = Call.event(name.description, detail)
        record.withLock { $0.calls.append(call) }
    }
}
