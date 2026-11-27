import os

/// Records the intervals and events of a library as signposts of the system.
///
/// A performance tool such as Instruments shows them under the subsystem and the category given
/// here. While the system has the category off, nothing is built for a call. Ending a token that
/// has nothing to end does nothing: it was begun while the category was off, it came from another
/// tracing type, or it has ended already.
public struct SystemTracing: Tracing {
    private let signposter: OSSignposter

    /// Creates a tracing value for one subsystem and category, both chosen by the library.
    public init(subsystem: String, category: String) {
        signposter = OSSignposter(subsystem: subsystem, category: category)
    }

    /// Begins a signpost interval with an ID of its own, so that overlapping intervals of one name
    /// stay apart.
    public func beginInterval(_ name: StaticString, _ detail: TraceDetail) -> TraceInterval {
        guard signposter.isEnabled else { return TraceInterval(name: name, handle: nil) }
        let id = signposter.makeSignpostID()
        let state = switch detail {
        case .none: signposter.beginInterval(name, id: id)
        case let .number(value): signposter.beginInterval(name, id: id, "\(value)")
        case let .label(label):
            signposter.beginInterval(name, id: id, "\(label.description, privacy: .public)")
        }
        return TraceInterval(name: name, handle: OpenInterval(state))
    }

    /// Ends the signpost interval of the token, the first time the token is ended.
    public func endInterval(_ interval: TraceInterval, _ detail: TraceDetail) {
        guard let state = (interval.handle as? OpenInterval)?.take() else { return }
        switch detail {
        case .none: signposter.endInterval(interval.name, state)
        case let .number(value): signposter.endInterval(interval.name, state, "\(value)")
        case let .label(label):
            signposter.endInterval(interval.name, state, "\(label.description, privacy: .public)")
        }
    }

    /// Emits a signpost event.
    public func emitEvent(_ name: StaticString, _ detail: TraceDetail) {
        guard signposter.isEnabled else { return }
        switch detail {
        case .none: signposter.emitEvent(name)
        case let .number(value): signposter.emitEvent(name, "\(value)")
        case let .label(label): signposter.emitEvent(name, "\(label.description, privacy: .public)")
        }
    }

    /// The state of an interval that began, handed out once. The system stops a Debug build that
    /// ends one state twice, and a token can be copied and ended from two places.
    private final class OpenInterval: Sendable {
        private let state: OSAllocatedUnfairLock<OSSignpostIntervalState?>

        init(_ state: OSSignpostIntervalState) {
            self.state = OSAllocatedUnfairLock(initialState: state)
        }

        func take() -> OSSignpostIntervalState? {
            state.withLock { state in
                let taken = state
                state = nil
                return taken
            }
        }
    }
}
