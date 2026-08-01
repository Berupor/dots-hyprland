#!/usr/bin/env bash
# Restart the live qs instance so it actually picks up what's on disk.
# Quickshell's own reload is unreliable (touch doesn't trigger it, Loader-loaded
# files never watch, and a broken config can hang silently) - a restart is the
# only reload that's ever verified to work. See wip/quickshell-gotchas.md.
set -u

mapfile -t PIDS < <(pgrep -f "^qs -c ii$")

if [ "${#PIDS[@]}" -gt 0 ]; then
    kill "${PIDS[@]}"
    sleep 2
fi

setsid qs -c ii > /dev/null 2>&1 &
disown
sleep 2

mapfile -t NEW_PIDS < <(pgrep -f "^qs -c ii$")
if [ "${#NEW_PIDS[@]}" -ne 1 ]; then
    echo "warning: ${#NEW_PIDS[@]} instances of 'qs -c ii' running, expected 1" >&2
    exit 1
fi
echo "restarted, pid ${NEW_PIDS[0]}"
