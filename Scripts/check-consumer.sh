#!/bin/bash
#
#   Scripts/check-consumer.sh
#
# Builds Fixtures/Consumer, a package that uses DMCore as a library of the family does, for the Mac
# with warnings as errors. Then it adds each file of Fixtures/Consumer/Rejected, one at a time and
# in a scratch copy, to the target that depends on DMCore alone, and requires that build to fail
# with the error the first line of the file names.
#
# Exit codes: 0 everything holds; 1 a rejected shape compiled or failed in another way; any other
# status, a build that should pass did not, or the check could not run.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE="$ROOT/Fixtures/Consumer"

echo "check-consumer: building the fixture"
# The build folder is outside Fixtures, which the linter reads.
swift build --package-path "$FIXTURE" --scratch-path "$ROOT/.build/consumer" -Xswiftc -warnings-as-errors

shapes=("$FIXTURE"/Rejected/*.swift.txt)
if [ ! -f "${shapes[0]}" ]; then
    echo "check-consumer: no rejected shape in $FIXTURE/Rejected" >&2
    exit 2
fi

scratch="$(mktemp -d "${TMPDIR:-/tmp}/check-consumer.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT
cp -R "$FIXTURE/Package.swift" "$FIXTURE/Sources" "$scratch/"
# The copy is elsewhere, so the path to DMCore is written out.
sed -i '' "s|path: \"../..\"|path: \"$ROOT\"|" "$scratch/Package.swift"

build_copy() {
    swift build --package-path "$scratch" --scratch-path "$scratch/.build" --target Consumer 2>&1 \
        | sed $'s/\x1b\\[[0-9;]*m//g' > "$scratch/build.log"
}

# The copy has to build before a shape is added, or a failure below would prove nothing.
if ! build_copy; then
    cat "$scratch/build.log" >&2
    echo "check-consumer: the scratch copy of the fixture does not build" >&2
    exit 2
fi

failures=0
for shape in "${shapes[@]}"; do
    name="$(basename "$shape" .swift.txt)"
    expected="$(sed -n '1s|^// expect: ||p' "$shape")"
    if [ -z "$expected" ]; then
        echo "check-consumer: the first line of $name does not name the expected error" >&2
        exit 2
    fi
    cp "$shape" "$scratch/Sources/Consumer/Rejected.swift"
    if build_copy; then
        echo "check-consumer: $name compiled, and it must not" >&2
        failures=$((failures + 1))
    elif ! grep -qF "error: $expected" "$scratch/build.log"; then
        grep -E 'error:' "$scratch/build.log" >&2 || cat "$scratch/build.log" >&2
        echo "check-consumer: $name failed without the error '$expected'" >&2
        failures=$((failures + 1))
    else
        echo "check-consumer: $name is rejected: $expected"
    fi
    rm "$scratch/Sources/Consumer/Rejected.swift"
done

if [ "$failures" -ne 0 ]; then
    echo "check-consumer: $failures of ${#shapes[@]} rejected shapes are not rejected as expected" >&2
    exit 1
fi
echo "check-consumer: the fixture builds, and its ${#shapes[@]} rejected shapes are rejected."
