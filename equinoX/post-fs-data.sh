#!/system/bin/sh
BB="/data/adb/modules/camera_fixer/binaries/busybox"
[ ! -x "$BB" ] && BB=$(which busybox 2>/dev/null || echo "/data/adb/ksu/busybox")

LOGFILE="/data/local/tmp/maintenance.log"
STATEFILE="/data/local/tmp/maintenance_last_run"
INTERVAL_SEC=$((7 * 24 * 60 * 60))

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') | $*" >> "$LOGFILE"; }

NOW=$(date +%s)
LASTRUN=0
[ -f "$STATEFILE" ] && LASTRUN=$(cat "$STATEFILE" 2>/dev/null || echo 0)
DIFF=$((NOW - LASTRUN))

if [ $DIFF -ge $INTERVAL_SEC ]; then
    log "Starting weekly maintenance..."
    $BB fstrim -v /data >> "$LOGFILE" 2>&1
    if command -v cmd >/dev/null 2>&1; then
        cmd package compile -r bg-dexopt -a
    fi
    echo "$NOW" > "$STATEFILE"
    log "Maintenance done."
else
    log "Skipped. Last run $((DIFF / 3600 / 24)) days ago."
fi