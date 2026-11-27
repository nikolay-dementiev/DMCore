#!/bin/bash
#
#   Scripts/check-consumer.sh
#
# Builds Fixtures/Consumer, a package that uses DMCore as a library of the family does, for the Mac
# with warnings as errors. Then it adds each file of Fixtures/Consumer/Rejected, one at a time and
# in a scratch copy, to the target that depends on DMCore alone, and requires that build to fail
# with an error line that holds one of the texts of the file's `// expect: ` lines.
#
# Exit codes: 0 everything holds; 1 a rejected shape compiled or failed in another way; any other
# status, a build that should pass did not, or the check could not run.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE="$ROOT/Fixtures/Consumer"

echo "check-consumer: building the fixture"
# The build folder is outside Fixtures, which the linter reads.
swift build --package-path "$FIXTURE" --scratch-path "$ROOT/.build/consumer" -Xswiftc -warnings-as-errors || exit 2

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
    sed -n 's|^// expect: ||p' "$shape" > "$scratch/expected"
    # An empty text would be found in every line.
    if [ ! -s "$scratch/expected" ] || grep -qx '' "$scratch/expected"; then
        echo "check-consumer: $name has no expect line, or an empty one" >&2
        exit 2
    fi
    cp "$shape" "$scratch/Sources/Consumer/Rejected.swift"
    if build_copy; then
        echo "check-consumer: $name compiled, and it must not" >&2
        failures=$((failures + 1))
    elif ! found="$(grep -F 'error:' "$scratch/build.log" | grep -oF -f "$scratch/expected")"; then
        grep -F 'error:' "$scratch/build.log" >&2 || cat "$scratch/build.log" >&2
        echo "check-consumer: $name failed without an expected error" >&2
        failures=$((failures + 1))
    else
        echo "check-consumer: $name is rejected: ${found%%$'\n'*}"
    fi
    rm "$scratch/Sources/Consumer/Rejected.swift"
done

if [ "$failures" -ne 0 ]; then
    echo "check-consumer: $failures of ${#shapes[@]} rejected shapes are not rejected as expected" >&2
    exit 1
fi
echo "check-consumer: the fixture builds, and its ${#shapes[@]} rejected shapes are rejected."
