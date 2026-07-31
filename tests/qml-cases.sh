#!/usr/bin/env bash
# Assertion cases for view code: every tests/cases/*.qml exposes `checks`,
# a list of { name, got, want[, tol] }, and runs through the probe harness in a
# throwaway shell instance. Reals compare with 0.5 tolerance unless `tol` says
# otherwise. First line of a case may carry probe flags:
#
#   //@ probe -g 320x260 -s 2000
#
#   tests/qml-cases.sh [name ...]   # bare names, default all cases
#
# One instance per case, so put several fixtures in one file rather than
# splitting checks across files. Needs a Wayland session: grabbing aside, the
# harness only renders in a real window.
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
FAIL=0

CASES=()
if [ "$#" -gt 0 ]; then
    for name in "$@"; do CASES+=("$REPO/tests/cases/${name%.qml}.qml"); done
else
    CASES=("$REPO"/tests/cases/*.qml)
fi

for file in "${CASES[@]}"; do
    name=$(basename "$file" .qml)
    [ -f "$file" ] || { echo "case FAIL $name: no such case"; FAIL=1; continue; }
    flags=$(sed -n '1s|^//@ probe ||p' "$file")
    # Exit code ignored on purpose: it also fails on a missing PNG, and the grab
    # sometimes gets no frame. A case with no checks is caught below anyway.
    # shellcheck disable=SC2086
    out=$(QS_PROBE_OUT="/tmp/qml-case-$name.png" "$REPO/tests/widget-probe.sh" -f "$file" $flags 2>&1)
    checks=$(grep -c "^check \|^FAIL check " <<< "$out")
    bad=$(grep "^FAIL check \|^FAIL load \|^FAIL no slot" <<< "$out")
    if [ -z "$bad" ] && [ "$checks" -gt 0 ]; then
        echo "case ok    $name ($checks checks)"
    else
        echo "case FAIL  $name"
        [ "$checks" = 0 ] && echo "  no checks reported"
        sed 's/^/  /' <<< "$out" | grep -vE "^  (probe|source|size|png|done) "
        FAIL=1
    fi
done

[ "$FAIL" = 0 ] && echo "PASS cases" || echo "FAIL cases"
exit "$FAIL"
