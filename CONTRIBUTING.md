# Contributing to DMCore

Thank you for helping. This guide says how to build the package, what a test must do, and how to
propose a change. [ENGINEERING.md](ENGINEERING.md) has the architecture and the compatibility
policy.

## Build

You need Xcode 16.0 or later (Swift 6.0). CI runs Xcode 16.2, 16.4 and 26.6. Build and test on the
Mac, with warnings as errors, and once more under the Thread Sanitizer:

```bash
swift test -Xswiftc -warnings-as-errors
```

```bash
swift test --sanitize=thread -Xswiftc -warnings-as-errors
```

On a simulator, with a device name and an OS version that your machine has:

```bash
xcodebuild test -scheme DMCore-Package -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
```

```bash
xcodebuild test -scheme DMCore-Package -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm),OS=26.5' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
```

For an iOS and a watchOS device:

```bash
xcodebuild build -scheme DMCore-Package -destination 'generic/platform=iOS' -configuration Release SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
```

```bash
xcodebuild build -scheme DMCore-Package -destination 'generic/platform=watchOS' -configuration Release SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
```

## The checks CI runs

The checks are scripts in `Scripts/`, and CI runs them as you do, except `check-wrappers.sh`, which
CI replaces by the command it forwards to,
`swift run --quiet --package-path Tools devkit check-wrappers`, so that a fault of the script cannot
turn the check into another one. CI also builds the documentation, with the warnings of DocC as
errors. One script, `Scripts/check-signposts.sh`, CI does not run: see [Tests](#tests).

| Script | What it checks |
|---|---|
| `Scripts/lint.sh` | SwiftLint, at the version pinned in `.swiftlint.yml`. The first run fetches that version into `.build/tools` and checks its checksum. With `--analyze <xcodebuild log>` it runs the analyzer rules, such as `unused_import`, on the log of a clean `build-for-testing` whose DerivedData is still on disk |
| `Scripts/check-api.sh` | that the public interface of `DMCore` matches `Fixtures/API/public-interface.txt`. `--update` rewrites the baseline; commit it with the change. The text depends on the compiler, and CI compares it on Xcode 26.6 |
| `Scripts/check-consumer.sh` | that a package which uses DMCore as a library of the family does, `Fixtures/Consumer`, builds, and that each shape of `Fixtures/Consumer/Rejected` fails with the error it names |
| `Scripts/check-release.sh <version>` | that the changelog, the baseline of the interface and the table of `SECURITY.md` are ready for that version |
| `Scripts/count-tests.sh` | that a result bundle holds every test of the test files, run and passed |
| `Scripts/export-coverage.sh` | writes the line coverage of the library from a result bundle |
| `Scripts/prepare-simulator.sh` | finds or creates the simulator that a CI job tests on, and prints its identifier |
| `Scripts/check-lint-contract.sh` | that the lint rules fire: it lints the fixtures of `Fixtures/Lint` where their folder says (the root and the subfolders as files of the library, `Outside/` outside it) and compares the diagnostics of the rules named in `devkit.conf` with the ones each line expects |
| `Scripts/check-lint-tool.sh` | that the helper which fetches SwiftLint is safe to run twice at once, with a fake archive and no network |
| `Scripts/check-wrappers.sh` | that the scripts which `WRAPPERS` in `devkit.conf` lists forward to `devkit` faithfully: command, arguments, directory, exit status and streams |
| `Scripts/ci-changes.sh --self-test` | the filter that decides which CI jobs a change needs, that every job of the workflow but the filter's own, `changes`, is in one of its groups, and that only the runs of one pull request share a concurrency group |

For a pull request, or a push to `main`, that changes only documents, CI skips the jobs that build
and test the code for each platform and toolchain: `floor`, `test`, `ios`, `watchos` and
`thread-sanitizer`. For a change of `.coderabbit.yaml` alone it skips every job but the filter. A
weekly run, a manual run and a release start every job. A push to `main` is judged by its own changes: after a push whose run failed, a
later push of documents alone can be green although the failure is still there.

The checks run code that the branch contains: Swift Package Manager evaluates `Package.swift`,
`Tools/Package.swift` and `Fixtures/Consumer/Package.swift`, `devkit.conf` is shell code that runs
with your rights, and `Scripts/check-signposts.sh` runs the program of `Fixtures/Signposts`. Before
you run the checks on someone else's branch, read what that branch changes in those files and in
`Scripts/`.

## The tools

All the scripts but `ci-changes.sh`, `check-consumer.sh` and `check-signposts.sh` are wrappers of
[DMDevKit](https://github.com/nikolay-dementiev/DMDevKit), the tooling of the DM libraries. Each
goes to the repository root, which `devkit` finds with git, so run them in a clone, and runs
`swift run --quiet --package-path Tools devkit <command>` with the arguments it was given.

- `Tools/Package.swift` is a package of its own. It pins a release of DMDevKit, and
  `Tools/Package.resolved` pins its commit; Dependabot proposes the newer releases. SwiftPM reads
  only the manifest at the root of a dependency, so a package that depends on DMCore does not fetch
  DMDevKit.
- `devkit.conf` holds the settings of this repository that the commands read. A change to a command
  is a change to DMDevKit.
- The first run builds `devkit` and prints the lines that SwiftPM writes while it fetches DMDevKit.
  Fetching SwiftLint needs `curl`, `unzip` and `shasum`.
- `swift run --quiet --package-path Tools devkit --help` lists the commands.

## Tests

- XCTest, through the public API only: no `@testable import`.
- One `makeSUT()` factory per test class, and hand-written spies that record calls.
- Names say the subject, the condition and the expected result:
  `test_<subject>_<condition>_<expected>`.
- In a test with two or more assertions, every assertion carries a message.
- A test must be able to fail. Show it red against the code before your change, or, for a test of
  behaviour that already holds, with a temporary change of the code it covers.
- A fix starts with a test that reproduces the defect.
- No test reads signposts back from the system. After a change of `SystemTracing`, run
  `Scripts/check-signposts.sh`, which records them with `xctrace` and compares them with
  `Fixtures/Signposts/expected.txt`, and put its output in the pull request.
  [Seeing the signposts](Sources/DMCore/DMCore.docc/SeeingSignposts.md) says what a signpost holds.

## Commits and pull requests

- One topic per commit, with a conventional prefix: `test:`, `fix:`, `feat:`, `refactor:`, `docs:`,
  `chore:`, `ci:` or `perf:`.
- The commit with a failing test comes before the commit that makes it pass.
- Pull requests go to `main` and are merged with a merge commit, so the test and fix pairs stay
  visible.
- A review, by a person or by an automated reviewer, follows the lanes of
  [Documentation/Review/README.md](Documentation/Review/README.md).
- A change that people using the package can notice gets an entry in `CHANGELOG.md`.

## Releases

A release is a tag that is the version itself, such as `1.0.0`, on a commit of `main`.

1. The newest heading of `CHANGELOG.md` is `## [<version>] - <date>`, and the table of `SECURITY.md`
   has a row for the version.
2. `Scripts/check-release.sh <version>` passes.
3. The maintainer pushes the tag. `.github/workflows/release.yml` checks it, runs every CI job on it
   and drafts the GitHub release from the changelog. A person publishes the draft.

## Security

Do not report a vulnerability in a public issue. See [SECURITY.md](SECURITY.md).
