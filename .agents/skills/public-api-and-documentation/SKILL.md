---
name: public-api-and-documentation
description: Review a change to DMCore for the class of the change, the public interface, the changelog and the documents. Use it on any change that touches a public declaration, an observable behaviour or a document that people using the package read.
---

# Public API and documentation

The question of this lane: is the change classified as ENGINEERING.md classifies it, and does
everything that people using the package read say so? The lane applies the rules of the repository
and states none of its own. Report each finding in the format of
[Documentation/Review/README.md](../../../Documentation/Review/README.md).

## What it checks

- The class of the change, none, additive or breaking, is stated and is right. A change of
  observable behaviour is breaking, including a crash that stops happening.
  (ENGINEERING.md, "Public API and behaviour")
  (AGENTS.md, "Classify every change")
- A change that is not additive. It needs the maintainer's decision on a new major version and a
  coordinated release of the libraries that depend on DMCore.
  (ENGINEERING.md, "Version 1 is additive only")
- An added overload that makes an existing call ambiguous, or a protocol requirement with a default
  implementation whose name a protocol extension already declares, or that a member of a conformer
  would capture. (ENGINEERING.md, "A new protocol requirement with a default implementation is
  additive only")
- A change of the public interface without the baseline updated in the same commit, or a change of
  `DMCoreTesting` that `Fixtures/Consumer` does not hold. (ENGINEERING.md, "a change of the
  interface updates the")
- A compiler deprecation attribute within a major version.
  (ENGINEERING.md, "No compiler deprecation attribute")
- A change that people using the package can notice, with no entry in `CHANGELOG.md`.
  (CONTRIBUTING.md, "A change that people using the package can notice gets an entry")
- The release the change needs is stated in the pull request.
  (PR template, "The release it needs")

## What it ignores

- What a CI script already enforces: `Scripts/lint.sh`, including the rule that every public symbol
  is documented.
- How the implementation is built: that is the lane architecture-and-dependencies.
- What can harm the host: that is the lane correctness-and-concurrency.
- The quality of a test: that is the lane test-discrimination.
