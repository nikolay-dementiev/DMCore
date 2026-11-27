// The public interface of DMCoreTesting, held by compilation: the interface check compares the one
// of DMCore only.
import Consumer
import DMCore
import DMCoreTesting

func widgetUnderTest() -> (Widget, TracingSpy) {
    let spy = TracingSpy()
    return (Widget(tracing: spy), spy)
}

func exactTypes() {
    let _: () -> TracingSpy = TracingSpy.init
    let _: KeyPath<TracingSpy, [TracingSpy.Call]> = \.calls
    requireTracing(TracingSpy.self)
    requireValue(TracingSpy.Call.self)
}

private func requireTracing<Value: Tracing & Sendable>(_: Value.Type) {}

private func requireValue<Value: Equatable & Sendable>(_: Value.Type) {}

// The switch has no default: a new case, a removed one or another associated type stops the build.
func number(of call: TracingSpy.Call) -> Int? {
    switch call {
    case let .begin(name, detail, interval: number):
        requireParts(name, detail)
        // An Int that became optional would stop here.
        let begun: Int = number
        return begun
    case let .end(name, detail, interval: number):
        requireParts(name, detail)
        let ended: Int? = number
        return ended
    case let .event(name, detail):
        requireParts(name, detail)
        return nil
    }
}

private func requireParts(_: String, _: TraceDetail) {}

func expectedCalls() -> [TracingSpy.Call] {
    [.begin("load", .none, interval: 0), .end("load", .none, interval: nil), .event("start", .none)]
}
