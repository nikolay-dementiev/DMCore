# Seeing the signposts

Record what a program emits with Instruments, or from the command line with `xctrace`.

## In Instruments

Profile the app with an instrument that shows signposts, such as the `os_signpost` instrument, and
filter by the subsystem that the library documents.

## From the command line

No unit test can read a signpost back, so this is a manual check. On the Mac, in the root of the
DMCore repository, build the tests:

```bash
swift build --build-tests
```

Record one run of the tests that use the system adapter:

```bash
xcrun xctrace record --instrument os_signpost --output signposts.trace --launch -- "$(xcrun --find xctest)" -XCTest DMCoreTests.SystemTracingTests "$(swift build --show-bin-path)/DMCoreTests.xctest"
```

Export the signpost table:

```bash
xcrun xctrace export --input signposts.trace --xpath '/trace-toc/run[@number="1"]/data/table[@schema="os-signpost"]'
```

The rows of the subsystem `DMCoreTests` show the type of each signpost (`Begin`, `End` or
`Event`), its identifier, its name, its category and its detail. The exported table prints a
negative number as the unsigned number with the same bits.
