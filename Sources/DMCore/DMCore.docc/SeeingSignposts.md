# Seeing the signposts

Record what a program emits with Instruments, or from the command line with `xctrace`.

## What a signpost holds

``SystemTracing`` records every interval under the signpost name `interval` and every event under
the name `event`. The message holds the name that the library gave, followed by the detail if there
is one:

| Call | Signpost name | Message |
|---|---|---|
| `beginInterval("load")` | `interval` | `load` |
| `endInterval(token, .label("done"))`, for that interval | `interval` | `load: done` |
| `emitEvent("retry", .number(2))` | `event` | `retry: 2` |

The signpost names are fixed because the system loses a name that lives in another binary image
than the code that emits the signpost, as a name written in a library does when DMCore is a dynamic
library of its own. So a recording reads the same however an app links DMCore. The two fixed names
and the form of the message are diagnostics, not part of the interface.

## In Instruments

Profile the app with an instrument that shows signposts, such as the `os_signpost` instrument, and
filter by the subsystem that the library documents.

## From the command line

Record a run of a program on the Mac:

```bash
xcrun xctrace record --instrument os_signpost --output signposts.trace --launch -- /path/to/program
```

Export the signpost table:

```bash
xcrun xctrace export --input signposts.trace --xpath '/trace-toc/run[@number="1"]/data/table[@schema="os-signpost"]'
```

Each row shows the type of a signpost (`Begin`, `End` or `Event`), its identifier, its name, its
subsystem, its category and its message.

## Checking the adapter

No unit test can read a signpost back, so a script of the DMCore repository records them. After a
change of ``SystemTracing``, run it in the root of the repository:

```bash
Scripts/check-signposts.sh
```

It builds a small program with DMCore in the same binary image and with DMCore as a dynamic library
of its own, records each build with `xctrace` and compares the signposts with the expected lines.
It is a manual check: CI does not run it.
