package import DMCore

/// A library type that traces its work without naming DMCore in its public interface. The first
/// part is the example of the DMCore documentation.
public struct Widget {
    private let tracing: any Tracing

    /// Creates a widget that records signposts.
    public init() {
        self.init(tracing: SystemTracing(subsystem: "Widget", category: "widget"))
    }

    package init(tracing: any Tracing) {
        self.tracing = tracing
    }

    /// Loads inside an interval.
    public func load() -> Int {
        tracing.measure("load") { 42 }
    }

    /// Reloads with an interval that spans a suspension.
    public func reload() async -> Int {
        let interval = tracing.beginInterval("reload", .number(1))
        defer { tracing.endInterval(interval, .label("done")) }
        tracing.emitEvent("start")
        return await tracing.measure("fetch") {
            await Task.yield()
            return 42
        }
    }

    /// A widget that records nothing.
    public static var silent: Widget {
        Widget(tracing: NoTracing())
    }
}
