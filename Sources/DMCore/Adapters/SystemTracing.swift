import os

/// Records the intervals and events of a library as signposts of the system.
///
/// A performance tool such as Instruments shows them under the subsystem and the category given
/// here. Every interval has the signpost name `interval` and every event the name `event`. The
/// message holds the name that the caller gave, followed by the detail if there is one: `load`, or
/// `load: 3`. While the system has the category off, nothing is built for a call.
///
/// A token is ended by a value with the subsystem and category that began it. Ending a token that
/// has nothing to end does nothing: it was begun while the category was off, another subsystem,
/// category or tracing type began it, or it has ended already.
public struct SystemTracing: Tracing {
    private let channel: Channel
    private let signposter: OSSignposter

    /// Creates a tracing value for one subsystem and category, both chosen by the library.
    public init(subsystem: String, category: String) {
        channel = Channel(subsystem: subsystem, category: category)
        signposter = OSSignposter(subsystem: subsystem, category: category)
    }

    /// Begins a signpost interval with an ID of its own, so that overlapping intervals of one name
    /// stay apart.
    public func beginInterval(_ name: StaticString, _ detail: TraceDetail) -> TraceInterval {
        guard signposter.isEnabled else { return TraceInterval(name: name, handle: nil) }
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval(
            "interval", id: id, "\(Self.message(name, detail), privacy: .public)")
        return TraceInterval(name: name, handle: OpenInterval(state, on: channel))
    }

    /// Ends the signpost interval of the token, the first time that its subsystem and category end
    /// it.
    public func endInterval(_ interval: TraceInterval, _ detail: TraceDetail) {
        guard let open = interval.handle as? OpenInterval, let state = open.take(on: channel) else { return }
        signposter.endInterval("interval", state, "\(Self.message(interval.name, detail), privacy: .public)")
    }

    /// Emits a signpost event.
    public func emitEvent(_ name: StaticString, _ detail: TraceDetail) {
        guard signposter.isEnabled else { return }
        signposter.emitEvent("event", "\(Self.message(name, detail), privacy: .public)")
    }

    // The signpost names are the literals above, and the caller's name travels in the message. The
    // system loses a signpost name that lives in another binary image than the code emitting it,
    // and a caller's name does when DMCore is a dynamic library of its own.
    private static func message(_ name: StaticString, _ detail: TraceDetail) -> String {
        switch detail {
        case .none: "\(name)"
        case let .number(value): "\(name): \(value)"
        case let .label(label): "\(name): \(label)"
        }
    }

    /// The subsystem and category of a tracing value.
    private struct Channel: Equatable {
        let subsystem: String
        let category: String
    }

    /// The state of an interval that began, handed out once, and only to the channel that began it.
    /// The system stops a Debug build that ends one state twice, and a token can be copied and ended
    /// from two places.
    private final class OpenInterval: Sendable {
        private let channel: Channel
        private let state: OSAllocatedUnfairLock<OSSignpostIntervalState?>

        init(_ state: OSSignpostIntervalState, on channel: Channel) {
            self.channel = channel
            self.state = OSAllocatedUnfairLock(initialState: state)
        }

        func take(on caller: Channel) -> OSSignpostIntervalState? {
            guard caller == channel else { return nil }
            return state.withLock { state in
                let taken = state
                state = nil
                return taken
            }
        }
    }
}
