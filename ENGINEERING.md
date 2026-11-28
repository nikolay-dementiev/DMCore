# Engineering standard

This is the standard DMCore is built by: what a change to its public interface and behaviour costs,
what the package is made of, and which toolchains and platforms it promises.
[CONTRIBUTING.md](CONTRIBUTING.md) has the commands, the checks CI runs and the rules for tests.
This file does not repeat them.

The rules apply from version 1.0.0.

## Public API and behaviour

DMCore is a published library that other libraries are built on, so what a consumer can see is a
contract: every `public` declaration and every observable behaviour. Each change belongs to one of
three classes:

- **none**: no declaration and no observable behaviour changes.
- **additive**: new declarations only, and nothing a consumer must do.
- **breaking**: anything else.

The rule is strict: every change of observable behaviour is breaking. That includes a crash that
stops happening and a behaviour brought back in line with the documentation. One thing is a
diagnostic and outside the contract: how a signpost of `SystemTracing` reads in a recording, that
is its fixed name and the form of its message.

| Change | Class |
|---|---|
| A changed default value | breaking |
| A new case in a public enum that a consumer can switch over | breaking |
| A new protocol requirement without a default implementation | breaking |
| A new protocol requirement with a default implementation | additive or breaking, see below |
| An added overload | additive, or breaking if an existing call now resolves to it or becomes ambiguous |
| A raised platform floor or `swift-tools-version` | breaking |
| A CI or tool pin, such as a runner image or the SwiftLint version | none |
| A pure refactor | none |

A new protocol requirement with a default implementation is additive only when its name is new to
the protocol and to its extensions, and a review finds no member of a conformer that the
requirement would capture.

### Version 1 is additive only

Every release of major version 1 adds to the library and never changes or removes what it has.
Several libraries can depend on DMCore in one app, and Swift Package Manager resolves one version of
it for all of them. A new major version needs the maintainer's decision and a coordinated release of
the libraries that depend on DMCore.

No compiler deprecation attribute ships within a major version. Its warning appears at every use of
the symbol and fails a consumer that builds with warnings as errors. A symbol is retired in the
documentation instead: the replacement and a migration example say what to use.

Who checks. `Scripts/check-api.sh` compares the public interface of `DMCore` with the committed
baseline `Fixtures/API/public-interface.txt`, and CI runs it: a change of the interface updates the
baseline in the same commit. It covers `DMCore` only. The interface of `DMCoreTesting` is held by
compilation: `Scripts/check-consumer.sh` builds `Fixtures/Consumer`, which names its public
declarations. `Scripts/check-release.sh` requires a new major version when the baseline lost or
changed a line since the release before. The review classifies added lines and behaviour, which no
script sees.

## The package

- **Two products.** `DMCore` is what a library links. `DMCoreTesting` holds test doubles, as a
  product of its own, so that a test double is linked only where a target names it.
- **Library type.** Both products are automatic. A static product lets Swift Package Manager and
  Xcode report duplicated library code when two linkers need it, and a dynamic one makes every app
  embed one more framework.
- **No dependency.** The manifest declares none, and adding one needs the maintainer's approval.
- **No shared mutable state.** No global mutable variable, no singleton and no Objective-C class.
- **Concurrency is checked by the compiler.** `DMCore` declares no `@unchecked Sendable`: state
  that threads share is behind a lock that the compiler knows to be safe, such as
  `OSAllocatedUnfairLock`, or in an actor. The review checks this.
- **Only `DMCore` creates a `TraceInterval`.** A conformer of `Tracing` outside this package can
  only hand on the token of a value of `DMCore`, so an adapter that keeps its own state for an
  interval is added here. Such conformers can exist, so a new requirement without a default
  implementation stays breaking.
- **Layers.** Inside `Sources/DMCore`, `Domain/` holds the interfaces and plain values and imports
  nothing, and `Adapters/` holds the code that talks to a system framework. Dependencies point
  inward: a Domain type never names an adapter.
- **Imports.** The library imports `os` only, and `DMCoreTesting` also `DMCore`. No import is
  re-exported with `@_exported`: it would reach every file of the module, `Domain/` included, and
  every consumer. `Scripts/lint.sh` enforces this with the custom rules `library_imports`,
  `domain_no_imports` and `no_reexport`. The first rule covers both library folders with one list,
  so a review keeps `DMCore` itself to `os`.
- **The library never stops its host.** No `fatalError`, `preconditionFailure`,
  `assertionFailure`, `precondition`, `assert`, `dispatchPrecondition`, `abort`, `exit`, `_exit`,
  `_Exit`, `raise`, `kill` or `pthread_kill`, no `assumeIsolated`, `preconditionIsolated` or
  `assertIsolated`, no force unwrap, no `try!` and no `as!`. `Scripts/lint.sh` enforces this: the
  custom rule `no_process_termination` over the two library folders, and SwiftLint's
  `force_unwrapping`, `force_try` and `force_cast`. The custom rule sees calls: a name used without
  one, or written in backticks, is left to the review. The force unwrap rule has no exemption for a
  call with a literal argument.
- **The rules are proved.** A rule that never matches reports nothing, so
  `Scripts/check-lint-contract.sh` lints the fixtures of `Fixtures/Lint` and proves that the rules
  named in `devkit.conf` fire on the lines that expect them and on no other line. It lints the
  fixtures inside the library as files of `Sources/DMCore`; it does not show that a rule reaches
  `Sources/DMCoreTesting`.

## Toolchain and platforms

- The manifest declares `swift-tools-version: 6.2` and the Swift 6 language mode, so the package
  needs Xcode 26.0 or later. `ExistentialAny` is on in every target.
- The declared platforms are iOS 17.0, watchOS 10.0 and macOS 13.0.
- `.github/workflows/ci.yml` is the place that says what CI runs. The jobs that compile use
  Xcode 26.6, except the iOS 18.6 cell, which uses Xcode 26.3 (Swift 6.2.4) on `macos-15`. No run
  covers an older compiler of Swift 6.2, which the manifest admits. The tests also run on the iOS
  Simulator at 26.5 and 18.6 and on the watchOS Simulator at 26.5: no run covers iOS 17 or
  watchOS 10, the oldest versions the manifest declares.
- XCTest is the test framework. Another one comes only by the maintainer's decision.

## Where the rest lives

- [CONTRIBUTING.md](CONTRIBUTING.md): how to build, the checks CI runs, the rules for tests and
  commits.
- [Documentation/Review/README.md](Documentation/Review/README.md): how a change is reviewed.
- [CHANGELOG.md](CHANGELOG.md): the history of the releases.
- [README.md](README.md): what the package is and how to add it.
