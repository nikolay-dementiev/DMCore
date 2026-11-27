// The program that Scripts/check-signposts.sh records. The script builds it twice: with the
// sources of DMCore in the same binary image, and against DMCore as a library of its own, where
// the names written here live in another image than the code that emits the signposts.
#if canImport(DMCore)
import DMCore
#endif

let subsystem = "DMCoreSignpostCheck"
let first = SystemTracing(subsystem: subsystem, category: "first")
let second = SystemTracing(subsystem: subsystem, category: "second")

// Every kind of detail, on a begin, an event and an end.
let loading = first.beginInterval("load", .label("start"))
first.emitEvent("step", .number(.min))
first.emitEvent("tick")
first.endInterval(loading, .label("done"))

// Intervals that overlap and end out of order stay apart.
let outer = first.beginInterval("outer")
let inner = first.beginInterval("inner", .number(2))
first.endInterval(outer, .number(1))
first.endInterval(inner)

// A second end of one token records nothing.
first.endInterval(inner, .label("again"))

// Only the subsystem and category that began an interval end it. Another one records nothing and
// leaves the interval open for a value equal to the first.
let owned = first.beginInterval("owned")
second.endInterval(owned, .label("foreign"))
SystemTracing(subsystem: subsystem, category: "first").endInterval(owned, .number(7))
