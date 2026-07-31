#!/usr/bin/env bash
# Probe one widget slot in a throwaway shell instance: repo files straight from
# the worktree, own config dir, own options. The live shell is untouched, and
# the instance renders into an 8x8 window in a screen corner, so nothing is in
# the way and no clicks or keystrokes are synthesized.
#
#   tests/widget-probe.sh <widget> <slot> [flags]
#   tests/widget-probe.sh [<widget>] -f modules/widgets/foo/Bar.qml [flags]
#
#   -o key=value  widget option for this run (json value, else string)
#   -K key=value  ditto, but a top-level widgets.json key: error report settings
#                 and anything else that is not per-widget. The report target is
#                 blanked for every run, so probes never ship reports anywhere
#   -p prop=value ditto, set on the loaded item after load: hover states,
#                 model stubs, anything the slot exposes
#   -r prop.path  print that property after settling, dotted paths ok
#   -g WxH        item size, default 640x360
#   -s ms         settle time before probing, default 1200
#   -f file.qml   load a path relative to the ii dir, skipping the catalog. Name the
#                 widget too if its polling waits on the catalog switch
#   -b color      backdrop behind the item, default the shell background. Items that
#                 expect a host surface (popup bodies) come out washed out without it
#   -S name       symlink ~/.config/<name> into the temp config dir, for widgets
#                 whose real state lives outside illogical-impulse (accounts,
#                 tokens). Without it that state reads as empty, which is often
#                 the condition you want to probe
#   -k            keep the temp config dir and print it
#
# Grabbing needs a rendering window, and a hidden one does not render, hence
# the corner. Slots that only exist for some option value need that -o.
# harness.qml lives here but is copied into the ii dir for the run, since
# `import qs.*` resolves against the config root. Runs serialize on a flock.
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
II="$REPO/dots/.config/quickshell/ii"
HARNESS="$II/harness.qml" # Copied in for the run, `import qs.*` needs it in the ii root
OUT="${QS_PROBE_OUT:-/tmp/widget-probe.png}"
OPTS='{}'
KEYS='{}'
PROPS='{}'
PROBE='[]'
FILE=""
KEEP=0
IW=640
IH=360
SETTLE=1200
BG=""
FAIL=0

WIDGET=""
SLOT=""
# Positional widget, then an optional slot: `-f` runs may name the widget alone
[ "${1:-}" ] && [ "${1#-}" = "${1:-}" ] && { WIDGET="$1"; shift; }
[ "${1:-}" ] && [ "${1#-}" = "${1:-}" ] && { SLOT="$1"; shift; }
SHARE=()
while getopts "o:K:p:r:g:s:f:S:b:k" flag; do
    case "$flag" in
        o) OPTS=$(jq -c --arg k "${OPTARG%%=*}" --arg v "${OPTARG#*=}" '.[$k] = (try ($v|fromjson) catch $v)' <<< "$OPTS") ;;
        K) KEYS=$(jq -c --arg k "${OPTARG%%=*}" --arg v "${OPTARG#*=}" '.[$k] = (try ($v|fromjson) catch $v)' <<< "$KEYS") ;;
        p) PROPS=$(jq -c --arg k "${OPTARG%%=*}" --arg v "${OPTARG#*=}" '.[$k] = (try ($v|fromjson) catch $v)' <<< "$PROPS") ;;
        r) PROBE=$(jq -c --arg p "$OPTARG" '. + [$p]' <<< "$PROBE") ;;
        g) IW=${OPTARG%x*}; IH=${OPTARG#*x} ;;
        s) SETTLE=$OPTARG ;;
        f) FILE=$OPTARG ;;
        S) SHARE+=("$OPTARG") ;;
        b) BG=$OPTARG ;;
        k) KEEP=1 ;;
    esac
done

[ -n "$FILE" ] && [ "${FILE#/}" = "$FILE" ] && FILE="$II/$FILE" # Absolute, harness wants file://
[ -z "$WIDGET$FILE" ] && { echo "usage: $0 <widget> <slot> | -f <file.qml>  [-o k=v] [-p k=v] [-r path] [-g WxH] [-s ms] [-k]"; exit 2; }

CFG=""
cleanup() {
    rm -f "$HARNESS"
    [ -z "$CFG" ] && return
    [ "$KEEP" = 1 ] && echo "kept: $CFG" || rm -rf "$CFG"
}
trap cleanup EXIT INT TERM

# The harness copy and the pkill pattern are shared, so runs have to queue up
exec 9> /tmp/widget-probe.lock
flock -w 120 9 || { echo "another probe holds the lock"; exit 2; }
cp "$REPO/tests/harness.qml" "$HARNESS"

# Throwaway config dir seeded from the real one, so theme and colors match but
# nothing we write lands in the live config
CFG=$(mktemp -d /tmp/widget-probe.XXXXXX)
cp -r "$HOME/.config/illogical-impulse" "$CFG/"
jq -c --arg w "$WIDGET" --argjson o "$OPTS" --argjson k "$KEYS" \
    '.errorReportsTarget = "" | . * $k | .enabled = [$w] | .options[$w] = ((.options[$w] // {}) * $o)' \
    "$HOME/.config/illogical-impulse/widgets.json" > "$CFG/illogical-impulse/widgets.json"
for name in ${SHARE[@]+"${SHARE[@]}"}; do
    ln -sfn "$HOME/.config/$name" "$CFG/$name"
done

LOG="$CFG/probe.log"
rm -f "$OUT"
cat > "$CFG/run.sh" <<EOF
#!/usr/bin/env bash
export XDG_CONFIG_HOME="$CFG"
export QS_HARNESS_WIDGET="$WIDGET" QS_HARNESS_SLOT="$SLOT" QS_HARNESS_FILE="$FILE"
export QS_HARNESS_OUT="$OUT" QS_HARNESS_SETTLE="$SETTLE"
export QS_HARNESS_IW="$IW" QS_HARNESS_IH="$IH" QS_HARNESS_W=8 QS_HARNESS_H=8
export QS_HARNESS_PROPS='$PROPS' QS_HARNESS_PROBE='$PROBE' QS_HARNESS_BG="$BG"
exec timeout 40 qs -p "$HARNESS"
EOF
chmod +x "$CFG/run.sh"

echo "probe ${WIDGET:-$FILE}${SLOT:+/$SLOT}  options $(jq -c --arg w "$WIDGET" '.options[$w] // {}' "$CFG/illogical-impulse/widgets.json")${PROPS#\{\}}"

RULES="float;size 8 8;move 100%-8 100%-8;noinitialfocus;noanim;noborder;noshadow"
if command -v hyprctl > /dev/null && hyprctl dispatch "hl.dsp.exec_cmd(\"[$RULES] $CFG/run.sh > $LOG 2>&1\")" > /dev/null; then
    : # Spawned out of the way, keeps focus and the current workspace as they are
else
    "$CFG/run.sh" > "$LOG" 2>&1 &
fi

for _ in $(seq 80); do
    grep -q "\[harness\] done" "$LOG" 2>/dev/null && break
    sleep 0.5
done
pkill -f "qs -p $HARNESS"

grep -E "\[harness\]|WARN|ERROR" "$LOG" 2>/dev/null |
    grep -vE "Saving logs|Shell ID|Launching config|translations/.*failed" |
    sed -E 's/\x1b\[[0-9;]*m//g; s/^ *(DEBUG|WARN|ERROR)[^:]*: *//; s/\[harness\] //'
grep -q "\[harness\] FAIL" "$LOG" 2>/dev/null && FAIL=1
[ -f "$OUT" ] && echo "png: $OUT" || FAIL=1
exit "$FAIL"
