#!/usr/bin/env bash
# Widget catalog smoke test against the live shell.
# Flips enabled-set combos in widgets.json (no shell reload needed), counts new
# log errors per combo. --broken also drops a corrupt widget in to prove isolation.
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
WDIR="$REPO/dots/.config/quickshell/ii/modules/widgets"
STORE="$HOME/.config/illogical-impulse/widgets.json"
LIVE="$HOME/.config/quickshell/ii/modules/widgets"
SETTLE=3
FAIL=0
ERRS="ERROR|TypeError|Unable to assign|is not a type|not installed|failed to load"
NOISE="ToolbarTabBar.qml\[59" # Upstream, fires on every tab rebuild

mapfile -t WIDGETS < <(find "$WDIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
echo "widgets: ${WIDGETS[*]}"

# --- static: qmllint ---------------------------------------------------------
while IFS= read -r f; do
    out=$(qmllint "$f" 2>&1 | grep -v "qs\.\|import qs\|Quickshell\|Failed to import\|not installed\|--qmldirs\|^$")
    [ -n "$out" ] && { echo "qmllint: $f"; echo "$out"; FAIL=1; }
done < <(find "$WDIR" -name '*.qml')

# --- static: design lint (Material You contract) -----------------------------
hex=$(grep -rnE 'color:.*"#[0-9a-fA-F]{3,8}"' "$WDIR" | grep -v transparent)
fonts=$(grep -rn "font.family:" "$WDIR" | grep -v "Appearance\.")
[ -n "$hex" ] && { echo "design lint, hardcoded colors:"; echo "$hex"; FAIL=1; }
[ -n "$fonts" ] && { echo "design lint, fonts outside Appearance:"; echo "$fonts"; FAIL=1; }

# --- combos ------------------------------------------------------------------
orig=$(jq -c '.enabled' "$STORE")
combos=("[]")
for w in "${WIDGETS[@]}"; do combos+=("[\"$w\"]"); done
combos+=("$(printf '%s\n' "${WIDGETS[@]}" | jq -R . | jq -cs .)")
for ((i = 0; i < ${#WIDGETS[@]}; i++)); do
    for ((j = i + 1; j < ${#WIDGETS[@]}; j++)); do
        combos+=("[\"${WIDGETS[i]}\",\"${WIDGETS[j]}\"]")
    done
done

set_enabled() {
    jq --argjson e "$1" '.enabled = $e' "$STORE" > "$STORE.tmp" && mv "$STORE.tmp" "$STORE"
}

echo "running ${#combos[@]} combos..."
for combo in "${combos[@]}"; do
    n=$(qs -c ii log 2>/dev/null | wc -l)
    set_enabled "$combo"
    sleep "$SETTLE"
    errs=$(qs -c ii log 2>/dev/null | tail -n +$((n + 1)) | grep -E "$ERRS" | grep -cvE "$NOISE")
    if [ "$errs" -gt 0 ]; then
        printf 'FAIL %-60s %s new errors\n' "$combo" "$errs"
        qs -c ii log 2>/dev/null | tail -n +$((n + 1)) | grep -E "$ERRS" | grep -vE "$NOISE" | head -3
        FAIL=1
    else
        printf 'ok   %s\n' "$combo"
    fi
done

# --- broken widget isolation -------------------------------------------------
if [ "${1:-}" = "--broken" ]; then
    echo "dropping a corrupt widget..."
    n=$(qs -c ii log 2>/dev/null | wc -l)
    mkdir -p "$LIVE/zbroken"
    echo "syntax error {" > "$LIVE/zbroken/Manifest.qml"
    sleep "$SETTLE"
    if ! pgrep -x qs > /dev/null; then
        echo "FAIL shell died on a broken widget"
        FAIL=1
    elif ! qs -c ii log 2>/dev/null | tail -n +$((n + 1)) | grep -q "ErrorReporter\] zbroken"; then
        echo "FAIL broken widget not reported"
        FAIL=1
    else
        echo "ok   shell survived, error reported"
    fi
    rm -rf "$LIVE/zbroken"
fi

set_enabled "$orig"
echo "restored enabled = $orig"
[ "$FAIL" = 0 ] && echo PASS || echo FAIL
exit "$FAIL"
