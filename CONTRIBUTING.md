# Contributing to DMCore

Thank you for helping. This guide says how to build the package, what a test must do, and how to
propose a change. [ENGINEERING.md](ENGINEERING.md) has the architecture and the compatibility
policy.

## Build

You need Xcode 16.0 or later (Swift 6.0). CI runs Xcode 16.2 and 26.6. On the Mac, with warnings as
errors:

```bash
swift build --build-tests -Xswiftc -warnings-as-errors
```

For the iOS and watchOS Simulators, and for a watchOS device:

```bash
xcodebuild build-for-testing -scheme DMCore-Package -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
xcodebuild build-for-testing -scheme DMCore-Package -destination 'generic/platform=watchOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
xcodebuild build -scheme DMCore-Package -destination 'generic/platform=watchOS' -configuration Release SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
```

The package declares nothing yet and has no test: each target holds one placeholder file, which the
first real source file of the target replaces.

## The checks CI runs

The checks are scripts in `Scripts/`, and CI runs them as you do, except `check-wrappers.sh`, which
CI replaces by the command it forwards to,
`swift run --quiet --package-path Tools devkit check-wrappers`, so that a fault of the script cannot
turn the check into another one.

| Script | What it checks |
|---|---|
| `Scripts/lint.sh` | SwiftLint, at the version pinned in `.swiftlint.yml`. The first run fetches that version into `.build/tools` and checks its checksum |
| `Scripts/check-lint-contract.sh` | that the lint rules fire: it lints the fixtures of `Fixtures/Lint` where their folder says (the root and the subfolders as files of the library, `Outside/` outside it) and compares the diagnostics of the rules named in `devkit.conf` with the ones each line expects |
| `Scripts/check-lint-tool.sh` | that the helper which fetches SwiftLint is safe to run twice at once, with a fake archive and no network |
| `Scripts/check-wrappers.sh` | that the scripts which `WRAPPERS` in `devkit.conf` lists forward to `devkit` faithfully: command, arguments, directory, exit status and streams |
| `Scripts/ci-changes.sh --self-test` | the filter that decides which CI jobs a change needs, and that every job of the workflow is in one of its groups |

CI skips the build jobs of a pull request, or of a push to `main`, that changes only documents, and
skips every job but the filter for a change of `.coderabbit.yaml` alone. A weekly run and a manual
run start every job.

The checks run code that the branch contains: Swift Package Manager evaluates `Package.swift` and
`Tools/Package.swift`, and `devkit.conf` is shell code that runs with your rights. Before you run the
checks on someone else's branch, read what that branch changes in those files and in `Scripts/`.

## The tools

All the scripts but `ci-changes.sh` are wrappers of
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

## Commits and pull requests

- One topic per commit, with a conventional prefix: `test:`, `fix:`, `feat:`, `refactor:`, `docs:`,
  `chore:`, `ci:` or `perf:`.
- The commit with a failing test comes before the commit that makes it pass.
- Pull requests go to `main` and are merged with a merge commit, so the test and fix pairs stay
  visible.
- A review, by a person or by an automated reviewer, follows the lanes of
  [Documentation/Review/README.md](Documentation/Review/README.md).
- A change that people using the package can notice gets an entry in `CHANGELOG.md`.

## Security

Do not report a vulnerability in a public issue. See [SECURITY.md](SECURITY.md).
