#!/bin/bash
#
#   Scripts/check-signposts.sh
#
# No test can read a signpost back, so this check records them. It builds the program of
# Fixtures/Signposts for the Mac, with the sources of DMCore in the same binary image and against
# DMCore as a dynamic library of its own, each without and with optimization. It records each
# build with xctrace and compares the signposts with Fixtures/Signposts/expected.txt.
#
# It is run by hand after a change of SystemTracing: CI does not run it. It needs Xcode.
#
# Exit codes: 0 every recording is as expected; 1 a recording differs; 2 the check could not run.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE="$ROOT/Fixtures/Signposts"

scratch="$(mktemp -d "${TMPDIR:-/tmp}/check-signposts.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT

# The settings Package.swift gives the library.
flags=(-swift-version 6 -enable-upcoming-feature ExistentialAny -package-name dmcore)
sources=("$ROOT"/Sources/DMCore/*/*.swift)

could_not_run() {
    echo "check-signposts: $1" >&2
    exit 2
}

# Prints one line for each signpost of the subsystem of the check, in the order of the recording:
# type, category, interval, name and message. An interval is numbered by its first appearance.
rows() {
    python3 -I - "$1" <<'PY'
import sys
import xml.etree.ElementTree as ET

root = ET.parse(sys.argv[1]).getroot()
by_id = {element.get("id"): element for element in root.iter() if element.get("id")}
columns = [column.findtext("mnemonic") for column in root.find(".//schema").findall("col")]
intervals = {}
for row in root.iter("row"):
    cells = {key: by_id.get(cell.get("ref"), cell) for key, cell in zip(columns, list(row))}

    def value(key):
        cell = cells.get(key)
        return "-" if cell is None or cell.get("fmt") is None else cell.get("fmt")

    if value("subsystem") != "DMCoreSignpostCheck":
        continue
    interval = "-"
    if value("event-type") != "Event":
        interval = intervals.setdefault(value("identifier"), "#%d" % (len(intervals) + 1))
    print(" | ".join([value("event-type"), value("category"), interval, value("name"), value("message")]))
PY
}

# Records one build and compares it. The first argument names the build, the second is the program.
check() {
    local name="$1" program="$2" attempt=1 trace
    # The recording cannot start while another trace session of the Mac holds the kernel, as a test
    # run can for a moment, and then xctrace may fail or never return. So each attempt has a hard
    # time limit, which perl sets as an alarm, and it is tried a few times.
    while :; do
        trace="$scratch/$name.$attempt.trace"
        perl -e 'alarm shift; exec @ARGV' 120 \
            xcrun xctrace record --instrument os_signpost --time-limit 30s --output "$trace" --launch -- "$program" \
            > "$scratch/$name.record.log" 2>&1 && break
        if [ "$attempt" -ge 6 ]; then
            cat "$scratch/$name.record.log" >&2
            could_not_run "$name: xctrace did not record in $attempt attempts"
        fi
        echo "check-signposts: $name: xctrace did not record, trying again" >&2
        attempt=$((attempt + 1))
        sleep 15
    done
    xcrun xctrace export --input "$trace" \
        --xpath '/trace-toc/run[@number="1"]/data/table[@schema="os-signpost"]' > "$scratch/$name.xml" \
        || could_not_run "$name: xctrace did not export"
    rows "$scratch/$name.xml" > "$scratch/$name.rows" || could_not_run "$name: the export could not be read"
    [ -s "$scratch/$name.rows" ] || could_not_run "$name: no signpost was recorded"
    if diff -u "$FIXTURE/expected.txt" "$scratch/$name.rows"; then
        echo "check-signposts: $name: as expected"
    else
        echo "check-signposts: $name: the recording differs" >&2
        failures=$((failures + 1))
    fi
}

failures=0
for optimization in -Onone -O; do
    one="$scratch/one-image$optimization"
    mkdir -p "$one" "$scratch/own-library$optimization"
    xcrun swiftc "${flags[@]}" "$optimization" -module-name Signposts "${sources[@]}" "$FIXTURE/main.swift" \
        -o "$one/signposts" || could_not_run "one image $optimization did not build"
    check "one-image$optimization" "$one/signposts"

    own="$scratch/own-library$optimization"
    xcrun swiftc "${flags[@]}" "$optimization" -emit-library -emit-module -module-name DMCore \
        -emit-module-path "$own/DMCore.swiftmodule" -Xlinker -install_name -Xlinker @executable_path/libDMCore.dylib \
        "${sources[@]}" -o "$own/libDMCore.dylib" || could_not_run "the library $optimization did not build"
    xcrun swiftc "${flags[@]}" "$optimization" -I "$own" -L "$own" -lDMCore "$FIXTURE/main.swift" \
        -o "$own/signposts" || could_not_run "the program of the library $optimization did not build"
    check "own-library$optimization" "$own/signposts"
done

if [ "$failures" -ne 0 ]; then
    echo "check-signposts: $failures of 4 recordings differ" >&2
    exit 1
fi
echo "check-signposts: the 4 recordings are as expected."
