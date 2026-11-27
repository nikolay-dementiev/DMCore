# ``DMCore``

The tracing interface that the libraries of the DM family share.

## Overview

A library tells a performance tool about its own work through ``Tracing``: it begins and ends
intervals and emits events. ``SystemTracing`` records them as signposts of the system, and
``NoTracing`` records nothing. A test passes `TracingSpy`, of the product `DMCoreTesting`, and
reads back what the library did.

A library takes `any Tracing` in a `package` initializer and creates ``SystemTracing`` in its public
one, so its own public interface never names a type of DMCore:

```swift
package import DMCore

public struct Widget {
    private let tracing: any Tracing

    public init() {
        self.init(tracing: SystemTracing(subsystem: "Widget", category: "widget"))
    }

    package init(tracing: any Tracing) {
        self.tracing = tracing
    }

    public func load() -> Int {
        tracing.measure("load") { 42 }
    }
}
```

An interval may end on another thread, or after an `await`: keep the ``TraceInterval`` that
``Tracing/beginInterval(_:_:)`` returned and pass it to ``Tracing/endInterval(_:_:)``.

## The naming rule

- A name is a `StaticString` written in the library: a short word for what happens, such as `load`.
- The library passes ``SystemTracing`` a subsystem that names the library, usually its module name,
  and one category for its signposts. A library documents both, because a host filters by them.
- In a recording, a name is the first part of the message of its signpost, and the signpost names
  are the same for every library: see <doc:SeeingSignposts>.
- The names of intervals and events are diagnostics. A library may change them in a minor release.

## The privacy rule

A signpost is public: anyone who records the device can read it. A ``TraceDetail`` is a number or a
constant label of the library, and never a value of the host: no text it shows, no description of its
error, no address and no name of its types. A name and a label are `StaticString`, so a text that is
built while the program runs does not fit them. Keep a number to what the library counts or
measures, never to a value of the host.

## Topics

### Recording

- ``Tracing``
- ``TraceDetail``
- ``TraceInterval``

### Adapters

- ``SystemTracing``
- ``NoTracing``

### Seeing the signposts

- <doc:SeeingSignposts>
