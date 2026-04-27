#!/bin/sh

set -eu

mode="${1:-todas}"
label="${2:-captura}"
ring_size_mb="${3:-25}"
ring_files="${4:-5}"

captures_dir="/captures"
state_dir="$captures_dir/.capture_state"
log_dir="$captures_dir/.capture_logs"
state_file="$state_dir/active_capture.env"
capture_public_ip="${CAPTURE_PUBLIC_IP:-172.20.10.50}"
capture_private_ip="${CAPTURE_PRIVATE_IP:-172.20.20.50}"
capture_attack_ip="${CAPTURE_ATTACK_IP:-172.20.30.50}"
capture_node="${CAPTURE_NODE:-monitor}"

normalize_mode() {
    case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
        red_publica|publica|dmz) echo "red_publica" ;;
        red_privada|privada|db|mysql) echo "red_privada" ;;
        red_ataque|ataque|attack) echo "red_ataque" ;;
        todas|todo|all|any) echo "todas" ;;
        *)
            echo "Modo de captura no reconocido: $1" >&2
            echo "Opciones: red_publica, red_privada, red_ataque, todas" >&2
            exit 1
            ;;
    esac
}

sanitize_label() {
    sanitized="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/_/g; s/__*/_/g; s/^_//; s/_$//')"
    if [ -z "$sanitized" ]; then
        sanitized="captura"
    fi
    printf '%s\n' "$sanitized"
}

resolve_interface_by_ip() {
    target_ip="$1"
    ip -o -4 addr show | awk -v target="$target_ip" '$4 ~ ("^" target "/") {print $2; exit}'
}

process_snapshot() {
    ps -o pid=,args= 2>/dev/null || ps w 2>/dev/null || ps 2>/dev/null || true
}

capture_is_running() {
    base_name="$1"
    process_snapshot | grep -F -- "/captures/$base_name" | grep -v grep >/dev/null 2>&1
}

find_capture_pids() {
    base_name="$1"
    process_snapshot | grep -F -- "/captures/$base_name" | grep -v grep | awk '{print $1}'
}

capture_mode="$(normalize_mode "$mode")"
capture_label="$(sanitize_label "$label")"
timestamp="$(date -u +%Y%m%d_%H%M%S)"
base_name="${capture_label}_${capture_mode}_${timestamp}"

mkdir -p "$captures_dir" "$state_dir" "$log_dir"

if [ -f "$state_file" ]; then
    previous_base="$(sed -n 's/^BASE_NAME=//p' "$state_file" | head -n 1)"
    if [ -n "$previous_base" ] && capture_is_running "$previous_base"; then
        echo "Ya existe una captura activa: $previous_base" >&2
        exit 1
    fi
    rm -f "$state_file"
fi

case "$capture_mode" in
    red_publica)
        capture_ip="$capture_public_ip"
        interface="$(resolve_interface_by_ip "$capture_ip")"
        ;;
    red_privada)
        capture_ip="$capture_private_ip"
        interface="$(resolve_interface_by_ip "$capture_ip")"
        ;;
    red_ataque)
        capture_ip="$capture_attack_ip"
        interface="$(resolve_interface_by_ip "$capture_ip")"
        ;;
    todas)
        capture_ip="any"
        interface="any"
        ;;
esac

if [ -z "$interface" ]; then
    echo "No se pudo resolver la interfaz para el modo $capture_mode." >&2
    exit 1
fi

writer="tshark"
output_extension="pcapng"
if command -v dumpcap >/dev/null 2>&1; then
    writer="dumpcap"
elif command -v tcpdump >/dev/null 2>&1; then
    writer="tcpdump"
    output_extension="pcap"
fi

ring_size_kb=$((ring_size_mb * 1024))
output_file="$captures_dir/${base_name}.${output_extension}"
log_file="$log_dir/${base_name}.log"

cat >"$state_file" <<EOF
BASE_NAME=$base_name
MODE=$capture_mode
INTERFACE=$interface
CAPTURE_IP=$capture_ip
OUTPUT_FILE=$output_file
LOG_FILE=$log_file
WRITER=$writer
OUTPUT_EXTENSION=$output_extension
CAPTURE_NODE=$capture_node
EOF

if [ "$writer" = "dumpcap" ]; then
    nohup dumpcap -q -i "$interface" -w "$output_file" -b "filesize:$ring_size_kb" -b "files:$ring_files" >/dev/null 2>"$log_file" &
elif [ "$writer" = "tcpdump" ]; then
    nohup tcpdump -i "$interface" -n -U -C "$ring_size_mb" -W "$ring_files" -w "$output_file" >/dev/null 2>"$log_file" &
else
    nohup tshark -q -i "$interface" -F pcapng -w "$output_file" -b "filesize:$ring_size_kb" -b "files:$ring_files" >/dev/null 2>"$log_file" &
fi

sleep 2

if ! capture_is_running "$base_name"; then
    rm -f "$state_file"
    echo "No se pudo iniciar la captura. Revisa $log_file" >&2
    exit 1
fi

echo "Captura iniciada correctamente."
echo "Nodo de captura: $capture_node"
echo "Modo: $capture_mode"
echo "Interfaz: $interface"
echo "Archivo base: $output_file"
echo "Rotacion: ${ring_files} archivos de ${ring_size_mb} MB"
