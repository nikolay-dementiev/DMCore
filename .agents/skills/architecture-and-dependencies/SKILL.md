---
name: architecture-and-dependencies
description: Review a change to DMCore for imports, dependencies, products, platform floors and where code lives. Use it on any change to Sources, Package.swift, devkit.conf, .swiftlint.yml or the lint fixtures.
---

# Architecture and dependencies

The question of this lane: does the change keep the package what ENGINEERING.md says it is? The
lane applies the rules of the repository and states none of its own. Report each finding in the
format of [Documentation/Review/README.md](../../../Documentation/Review/README.md).

## What it checks

- A dependency or a plugin added to `Package.swift`. No script checks the manifest, so the
  reviewer does. (ENGINEERING.md, "No dependency.")
  (AGENTS.md, "Add no dependency without the maintainer's approval")
- A product added or removed, a library type set to static or dynamic, or a test double in `DMCore`.
  (ENGINEERING.md, "Two products.") (ENGINEERING.md, "Library type.")
- A raised platform floor or `swift-tools-version`, another language mode, a target without
  `ExistentialAny`, or a test framework other than XCTest.
  (ENGINEERING.md, "Toolchain and platforms")
- An import in `DMCore` of any module but `os`. The lint rule `library_imports` also lets the name
  `DMCore` pass there, and it does not see an import that follows a block comment on the same line.
  (ENGINEERING.md, "Imports.")
- A type in `Domain/` that names an adapter, or code in the wrong folder. No lint rule sees which
  type names which. (ENGINEERING.md, "Layers.")
- A lint rule added or widened without a fixture that proves that it fires on the lines that expect
  it and on no other line. A change of the paths that a rule covers needs a reading of both library
  folders: the fixtures do not show that a rule reaches `Sources/DMCoreTesting`.
  (ENGINEERING.md, "The rules are proved.")

## What it ignores

- What a CI script already enforces: `Scripts/lint.sh` and its rules (the imports of the two
  library folders, the imports in `Domain/`, process termination, force unwraps, force tries and
  force casts, missing documentation, formatting), `Scripts/check-lint-contract.sh`,
  `Scripts/check-lint-tool.sh`, `Scripts/check-wrappers.sh` and `Scripts/ci-changes.sh --self-test`.
- Shared state and what can stop the host: that is the lane correctness-and-concurrency.
- The class of a change and its documentation: that is the lane public-api-and-documentation.
- The quality of a test: that is the lane test-discrimination.
