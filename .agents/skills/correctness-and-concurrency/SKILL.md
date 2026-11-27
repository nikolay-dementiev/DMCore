---
name: correctness-and-concurrency
description: Review a change to DMCore for shared mutable state, for anything that can stop the host and for changed behaviour. Use it on any change to Sources.
---

# Correctness and concurrency

The question of this lane: can the change harm the host that links the library? The lane applies
the rules of the repository and states none of its own. Report each finding in the format of
[Documentation/Review/README.md](../../../Documentation/Review/README.md).

## What it checks

- A global mutable variable, a singleton or an Objective-C class.
  (ENGINEERING.md, "No shared mutable state.")
- A way to stop the host that no lint rule sees, such as a subscript or a range that can be out of
  bounds, an integer operation that can overflow, or a division by zero.
  (ENGINEERING.md, "The library never stops its host.")
- A change of observable behaviour. Hand it to the lane public-api-and-documentation, which owns
  its class. (ENGINEERING.md, "every change of observable behaviour is breaking")

## What it ignores

- What a CI script already enforces: `Scripts/lint.sh` and its rules (`no_process_termination`,
  `force_unwrapping`, `force_try`, `force_cast`, the imports, missing documentation, formatting),
  and what the compiler rejects in the Swift 6 language mode.
- Where code lives and which dependencies it uses: that is the lane architecture-and-dependencies.
- The class of a change and its documentation: that is the lane public-api-and-documentation.
- The quality of a test: that is the lane test-discrimination.
