#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

require_command curl

INTERVAL_SECONDS="${1:-0.5}"
OUTPUT_FILE="${2:-$ROOT_DIR/analisis/trafico_base.csv}"
TARGET_URL="${3:-$WEB_URL}"

mkdir -p "$(dirname "$OUTPUT_FILE")"
echo "timestamp,http_code,latency_seconds" >"$OUTPUT_FILE"

echo "======================================================"
echo " Iniciando sonda de trafico HTTP hacia $TARGET_URL"
echo " Guardando muestras en: $OUTPUT_FILE"
echo " Presiona [Ctrl+C] para detener la ejecucion."
echo "======================================================"

cleanup() {
  echo
  echo "Trafico legitimo detenido. CSV disponible en: $OUTPUT_FILE"
}

trap cleanup EXIT INT TERM

while true; do
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
  response="$(curl -s -o /dev/null -w '%{http_code},%{time_total}' "$TARGET_URL")"
  http_code="${response%%,*}"
  latency="${response#*,}"
  echo "[$timestamp] Codigo HTTP: $http_code | Latencia: ${latency}s"
  echo "$timestamp,$http_code,$latency" >>"$OUTPUT_FILE"
  sleep "$INTERVAL_SECONDS"
done
