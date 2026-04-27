#!/bin/sh

set -eu

captures_dir="/captures"
state_file="$captures_dir/.capture_state/active_capture.env"

process_snapshot() {
    ps -o pid=,args= 2>/dev/null || ps w 2>/dev/null || ps 2>/dev/null || true
}

find_capture_pids() {
    base_name="$1"
    process_snapshot | grep -F -- "/captures/$base_name" | grep -v grep | awk '{print $1}'
}

capture_is_running() {
    base_name="$1"
    process_snapshot | grep -F -- "/captures/$base_name" | grep -v grep >/dev/null 2>&1
}

if [ ! -f "$state_file" ]; then
    echo "No hay una captura activa registrada." >&2
    exit 1
fi

. "$state_file"

pids="$(find_capture_pids "$BASE_NAME" || true)"

if [ -n "$pids" ]; then
    for pid in $pids; do
        kill -INT "$pid" 2>/dev/null || true
    done
    sleep 2
fi

pids="$(find_capture_pids "$BASE_NAME" || true)"
if [ -n "$pids" ]; then
    for pid in $pids; do
        kill -TERM "$pid" 2>/dev/null || true
    done
    sleep 1
fi

if capture_is_running "$BASE_NAME"; then
    echo "No se pudo detener la captura $BASE_NAME." >&2
    exit 1
fi

echo "Captura detenida: $BASE_NAME"
echo "Archivos generados:"
find "$captures_dir" -maxdepth 1 -type f \( -name "${BASE_NAME}*.pcapng" -o -name "${BASE_NAME}*.pcap*" \) | sort

rm -f "$state_file"
