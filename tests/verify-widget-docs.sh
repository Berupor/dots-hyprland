#!/usr/bin/env bash
# Two contract surfaces are explicit lists in code - slotSchema's keys and the
# option type switch in WidgetCard.qml. Checked against docs/widgets.md in both
# directions: something the code knows and the doc doesn't (means shellVersion
# probably wants a bump too), or something the doc still claims that code dropped.
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
CATALOG="$REPO/dots/.config/quickshell/ii/modules/widgets/WidgetCatalog.qml"
CARD="$REPO/dots/.config/quickshell/ii/modules/widgets/WidgetCard.qml"
DOCS="$REPO/docs/widgets.md"
FAIL=0

check() { # check <what> <code-list> <docs-list>
    local what="$1" missing extra
    missing=$(comm -23 <(sort -u <<< "$2") <(sort -u <<< "$3"))
    extra=$(comm -13 <(sort -u <<< "$2") <(sort -u <<< "$3"))
    [ -n "$missing" ] && { echo "undocumented $what in docs/widgets.md:"; echo "$missing" | sed 's/^/  /'; FAIL=1; }
    [ -n "$extra" ] && { echo "docs/widgets.md has $what code no longer has:"; echo "$extra" | sed 's/^/  /'; FAIL=1; }
}

slots_code=$(awk '/slotSchema: \(\{/{f=1;next} f&&/^[ \t]*\}\)[ \t]*$/{f=0} f' "$CATALOG" | grep -oP '"\K\w+(?=":)')
slots_docs=$(awk '/^## Slots/{f=1;next} f&&/^## /{f=0} f' "$DOCS" | grep -oP '^\| `\K\w+(?=`)')
check "slots" "$slots_code" "$slots_docs"

types_code=$(grep -oP 'case "\K\w+(?=":)' "$CARD")
types_docs=$(awk '/^## Option types/{f=1;next} f&&/^## /{f=0} f' "$DOCS" | grep -oP '^- `\K\w+(?=`)')
check "option types" "$types_code" "$types_docs"

[ "$FAIL" = 0 ] && echo "PASS widget docs" || echo "FAIL widget docs"
exit "$FAIL"
