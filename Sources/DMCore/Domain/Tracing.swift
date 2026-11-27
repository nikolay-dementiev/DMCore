/// What a library tells a performance tool about its own work.
///
/// A name is a compile-time constant written in the library. A detail is a number or a constant
/// label of the library, never a value of the host. Every method may be called from any thread, and
/// an interval may be ended on another thread than the one that began it.
public protocol Tracing: Sendable {
    /// Begins an interval and returns the token that ends it. End each token once, on the tracing
    /// value that began it.
    func beginInterval(_ name: StaticString, _ detail: TraceDetail) -> TraceInterval

    /// Ends the interval of the token.
    func endInterval(_ interval: TraceInterval, _ detail: TraceDetail)

    /// Records a single point in time.
    func emitEvent(_ name: StaticString, _ detail: TraceDetail)
}

/// What a name alone does not say: nothing, a number or a constant label.
public enum TraceDetail: Sendable, Equatable {
    /// No detail.
    case none
    /// A number, such as the number of an attempt.
    case number(Int64)
    /// A constant label written in the library.
    case label(StaticString)

    /// Two details are equal when they are the same case with the same number or the same label
    /// text.
    public static func == (lhs: TraceDetail, rhs: TraceDetail) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none): true
        case let (.number(left), .number(right)): left == right
        case let (.label(left), .label(right)): left.description == right.description
        default: false
        }
    }
}

/// The token of an open interval. It crosses threads and suspension points.
///
/// Only DMCore creates one. A conformer of ``Tracing`` outside this package returns the token
/// that a value of DMCore made for it.
public struct TraceInterval: Sendable {
    package let name: StaticString
    /// What the tracing value that began the interval needs to end it. Nil when nothing listened.
    package let handle: (any Sendable)?

    package init(name: StaticString, handle: (any Sendable)?) {
        self.name = name
        self.handle = handle
    }
}

extension Tracing {
    /// Begins an interval without a detail.
    public func beginInterval(_ name: StaticString) -> TraceInterval {
        beginInterval(name, .none)
    }

    /// Ends an interval without a detail.
    public func endInterval(_ interval: TraceInterval) {
        endInterval(interval, .none)
    }

    /// Records a single point in time without a detail.
    public func emitEvent(_ name: StaticString) {
        emitEvent(name, .none)
    }

    /// Runs the work inside an interval and returns its result. The interval ends when the work
    /// returns or throws.
    public func measure<T>(_ name: StaticString, _ work: () throws -> T) rethrows -> T {
        let interval = beginInterval(name)
        defer { endInterval(interval) }
        return try work()
    }

    /// Runs asynchronous work inside an interval and returns its result. The interval ends when
    /// the work returns or throws. This method adds no isolation of its own: a closure that is
    /// isolated to the actor of the caller runs there.
    public func measure<T>(
        _ name: StaticString,
        isolation: isolated (any Actor)? = #isolation,
        _ work: () async throws -> T
    ) async rethrows -> T {
        let interval = beginInterval(name)
        defer { endInterval(interval) }
        return try await work()
    }
}

/// A tracing value that records nothing.
public struct NoTracing: Tracing {
    /// Creates a tracing value that records nothing.
    public init() {}

    /// Returns a token with nothing to end.
    public func beginInterval(_ name: StaticString, _ detail: TraceDetail) -> TraceInterval {
        TraceInterval(name: name, handle: nil)
    }

    /// Does nothing.
    public func endInterval(_ interval: TraceInterval, _ detail: TraceDetail) {}

    /// Does nothing.
    public func emitEvent(_ name: StaticString, _ detail: TraceDetail) {}
}
