# Changelog

All notable changes to DMCore are recorded in this file. The format follows Keep a Changelog
1.1.0, and versions follow Semantic Versioning 2.0.0.

## [1.0.0] - 2026-11-27

The first release: the tracing kit of the family.

### Added

- The products `DMCore` and `DMCoreTesting`, for iOS 17, watchOS 10 and macOS 13, built with
  Swift 6.2 or later (Xcode 26 or later), with no dependency.
- `Tracing`, an interface for performance intervals and events, with `TraceDetail`, a detail that is
  nothing, a number or a constant label, and `TraceInterval`, the token of an open interval, which
  crosses threads and suspension points.
- Calls of `Tracing` without a detail, and `measure`, which runs synchronous or asynchronous work
  inside an interval.
- `SystemTracing`, which records signposts of the system under a subsystem and a category, with the
  name and the detail in the message of each. It ends an interval once, and only for the subsystem
  and category that began it.
- `NoTracing`, which records nothing.
- `TracingSpy`, in `DMCoreTesting`, which records every call in order, from any thread, for tests.
- Documentation of the naming rule, of the privacy rule and of how to see the signposts.
