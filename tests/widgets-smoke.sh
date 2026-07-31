#!/usr/bin/env bash
# Widget catalog smoke test against the live shell.
# Flips enabled-set combos in widgets.json (no shell reload needed), counts new
# log errors per combo. --broken also drops a corrupt widget in to prove isolation.
# --static stops after the lints: no live shell, no writes, safe in a git hook.
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
WDIR="$REPO/dots/.config/quickshell/ii/modules/widgets"
STORE="$HOME/.config/illogical-impulse/widgets.json"
BAK="$STORE.smoke-bak"
LIVE="$HOME/.config/quickshell/ii/modules/widgets"
SETTLE=3
FAIL=0
ERRS="ERROR|TypeError|Unable to assign|is not a type|not installed|failed to load"
NOISE="ToolbarTabBar.qml\[59" # Upstream, fires on every tab rebuild

mapfile -t WIDGETS < <(find "$WDIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
echo "widgets: ${WIDGETS[*]}"

# --- static: qmllint ---------------------------------------------------------
# The qmllint in PATH is Qt5's and dies with 255 and no output on this tree, so
# take the Qt6 one. Only syntax level counts: type warnings on the qs.* imports
# and on JsonAdapter properties are noise it cannot resolve outside qs.
QMLLINT=$(ls /usr/lib/qt6/bin/qmllint 2> /dev/null || command -v qmllint6 qmllint 2> /dev/null | head -1)
if [ -n "$QMLLINT" ]; then
    while IFS= read -r f; do
        out=$("$QMLLINT" "$f" 2>&1 | grep -E "^Error:|\[syntax")
        [ -n "$out" ] && { echo "qmllint: $f"; echo "$out"; FAIL=1; }
    done < <(find "$WDIR" "$REPO/tests/cases" -name '*.qml')
else
    echo "no qmllint, syntax lint skipped"
fi

# --- static: design lint (Material You contract) -----------------------------
hex=$(grep -rnE 'color:.*"#[0-9a-fA-F]{3,8}"' "$WDIR" | grep -v transparent)
fonts=$(grep -rn "font.family:" "$WDIR" | grep -v "Appearance\.")
[ -n "$hex" ] && { echo "design lint, hardcoded colors:"; echo "$hex"; FAIL=1; }
[ -n "$fonts" ] && { echo "design lint, fonts outside Appearance:"; echo "$fonts"; FAIL=1; }

if [ "${1:-}" = "--static" ]; then
    [ "$FAIL" = 0 ] && echo "PASS static" || echo FAIL
    exit "$FAIL"
fi

# --- save/restore ------------------------------------------------------------
write_store() { # Atomic: FileView reads on the rename, never a partial file
    cat > "$STORE.new" && jq -e . "$STORE.new" > /dev/null && mv "$STORE.new" "$STORE" && return
    echo "WARN bad write to $STORE"
    rm -f "$STORE.new"
    return 1
}

set_enabled() {
    jq --argjson e "$1" '.enabled = $e' "$STORE" | write_store
}

restore() { # The shell keeps widgets.json in memory and rewrites it whole on any
    [ -f "$BAK" ] || return 0 # UI change, so one write can lose the race
    rm -rf "$LIVE/zbroken"
    for _ in 1 2 3; do
        write_store < "$BAK"
        sleep "$SETTLE"
        if cmp -s <(jq -S . "$BAK") <(jq -S . "$STORE"); then
            rm -f "$BAK"
            echo "restored widgets.json"
            return 0
        fi
    done
    echo "WARN could not restore widgets.json, backup kept at $BAK"
}

if [ -f "$BAK" ]; then # Killed run, its backup is the real state
    echo "leftover $BAK, restoring it first"
    restore
fi
cp "$STORE" "$BAK"
trap restore EXIT
trap 'restore; exit 130' INT TERM # bash would resume the loop otherwise

# --- combos ------------------------------------------------------------------
combos=("[]")
for w in "${WIDGETS[@]}"; do combos+=("[\"$w\"]"); done
combos+=("$(printf '%s\n' "${WIDGETS[@]}" | jq -R . | jq -cs .)")
for ((i = 0; i < ${#WIDGETS[@]}; i++)); do
    for ((j = i + 1; j < ${#WIDGETS[@]}; j++)); do
        combos+=("[\"${WIDGETS[i]}\",\"${WIDGETS[j]}\"]")
    done
done

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

restore
[ "$FAIL" = 0 ] && echo PASS || echo FAIL
exit "$FAIL"
