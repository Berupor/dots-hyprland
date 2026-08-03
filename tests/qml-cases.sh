#!/usr/bin/env bash
# Assertion cases for view code: every tests/cases/*.qml exposes `checks`,
# a list of { name, got, want[, tol] }, and runs through the probe harness in a
# throwaway shell instance. Reals compare with 0.5 tolerance unless `tol` says
# otherwise. First line of a case may carry probe flags:
#
#   //@ probe -g 320x260 -s 2000
#
# A case that needs widget options starts the line with the widget: `//@ probe
# hello -o badge=true`.
#
#   tests/qml-cases.sh [name ...]         # bare names, default all cases
#   tests/qml-cases.sh -x <widget dir>    # demo/*.qml of a widget repo
#   tests/qml-cases.sh -j N               # concurrent probes, default 4
#
# One instance per case, so put several fixtures in one file rather than
# splitting checks across files. Needs a Wayland session: grabbing aside, the
# harness only renders in a real window. Cases run -j at a time, each in its
# own probe (own harness copy, own config dir), output collected and printed
# in case order once everything finishes.
#
# A widget outside the tree keeps its cases in its own demo/, out of the way of the
# files a user installs (`import ".."` reaches them, qmldir singleton included). A
# scene feeds the widget's own singleton whatever state it wants drawn, so nothing
# needs faking from the host side, and shots.txt shoots the same files.
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
FAIL=0
XDIR=""
JOBS=4

while getopts "x:j:" flag; do
    case "$flag" in
        x) XDIR=$OPTARG ;;
        j) JOBS=$OPTARG ;;
    esac
done
shift $((OPTIND - 1))

CASES=()
if [ -n "$XDIR" ]; then
    [ "${XDIR#/}" = "$XDIR" ] && XDIR="$REPO/$XDIR"
    CASES=("$XDIR"/demo/*.qml)
    [ -e "${CASES[0]}" ] || { echo "no demo/*.qml in $XDIR"; exit 2; }
elif [ "$#" -gt 0 ]; then
    for name in "$@"; do CASES+=("$REPO/tests/cases/${name%.qml}.qml"); done
else
    CASES=("$REPO"/tests/cases/*.qml)
fi

TMP=$(mktemp -d /tmp/qml-cases.XXXXXX)
trap 'rm -rf "$TMP"' EXIT

names=()
for file in "${CASES[@]}"; do
    name=$(basename "$file" .qml)
    names+=("$name")
    [ -f "$file" ] || continue
    flags=$(sed -n '1s|^//@ probe ||p' "$file")
    # Exit code ignored on purpose: it also fails on a missing PNG, and the grab
    # sometimes gets no frame. A case with no checks is caught below anyway.
    # shellcheck disable=SC2086
    # Flags first: a case naming a widget needs it in the leading positional
    QS_PROBE_OUT="/tmp/qml-case-$name.png" "$REPO/tests/widget-probe.sh" $flags ${XDIR:+-x "$XDIR"} -f "$file" > "$TMP/$name.out" 2>&1 &
    while [ "$(jobs -r -p | wc -l)" -ge "$JOBS" ]; do wait -n; done
done
wait

for name in "${names[@]}"; do
    if [ ! -f "$TMP/$name.out" ]; then
        echo "case FAIL $name: no such case"
        FAIL=1
        continue
    fi
    out=$(<"$TMP/$name.out")
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
