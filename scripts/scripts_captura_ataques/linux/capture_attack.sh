#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

attack="${1:-}"
duration_seconds="${2:-45}"

if [[ -z "$attack" ]]; then
  echo "Uso: $(basename "$0") <udp|syn|http|sqli_dos> [duracion_segundos]" >&2
  exit 1
fi

attack_key="$(normalize_attack "$attack")"

capture_mode_for_attack() {
  case "$1" in
    syn) echo "red_publica" ;;
    udp) echo "red_publica" ;;
    http) echo "red_publica" ;;
    sqli_dos) echo "red_privada" ;;
    *)
      echo "No se pudo resolver el modo de captura para: $1" >&2
      exit 1
      ;;
  esac
}

capture_label_for_attack() {
  local attack_name="$1"
  local duration_tag="$2"
  case "$attack_name" in
    syn) echo "syn_${duration_tag}s" ;;
    udp) echo "udp_${duration_tag}s" ;;
    http) echo "http_${duration_tag}s" ;;
    sqli_dos) echo "sqli_${duration_tag}s" ;;
  esac
}

capture_mode="$(capture_mode_for_attack "$attack_key")"
capture_label="$(capture_label_for_attack "$attack_key" "$duration_seconds")"

cleanup() {
  bash "$SCRIPT_DIR/stop_attacks.sh" >/dev/null 2>&1 || true
  bash "$SCRIPT_DIR/stop_capture.sh" >/dev/null 2>&1 || true
}

trap cleanup EXIT

bash "$SCRIPT_DIR/stop_attacks.sh" >/dev/null 2>&1 || true
bash "$SCRIPT_DIR/stop_capture.sh" >/dev/null 2>&1 || true

echo "Iniciando captura de $attack_key durante $duration_seconds segundos..."
echo "Modo de captura: $capture_mode"

bash "$SCRIPT_DIR/start_capture.sh" "$capture_mode" "$capture_label"
bash "$SCRIPT_DIR/attack.sh" "$attack_key"
sleep "$duration_seconds"
bash "$SCRIPT_DIR/stop_attacks.sh"
bash "$SCRIPT_DIR/stop_capture.sh"

trap - EXIT

echo
echo "Captura finalizada para $attack_key."
