## What and why

## How it was tested

- [ ] `swift test` and the `xcodebuild` runs of `CONTRIBUTING.md`, without a warning
- [ ] `Scripts/lint.sh`, `Scripts/check-lint-contract.sh`, `Scripts/check-api.sh` and
      `Scripts/check-consumer.sh`
- [ ] Every new test fails without the change

## Public API and behaviour

- [ ] Every added public declaration is documented, and none is changed or removed
- [ ] Every change that people using the package can notice is in `CHANGELOG.md`

## Compatibility

`ENGINEERING.md` in the repository root defines the classes.

`Documentation/Review/README.md` says how the change is reviewed.

- Class of the change: none / additive / breaking (a change of observable behaviour is breaking)
- Observable behaviour changes, each one listed, or "none":
- Dependency changes, or "none":
- For each new test, the change to the code that it fails on:
- The release it needs: none / patch / minor / major
