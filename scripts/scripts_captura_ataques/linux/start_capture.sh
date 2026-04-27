#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

require_command docker

mode="${1:-todas}"
label="${2:-captura}"
ring_size_mb="${3:-25}"
ring_files="${4:-5}"
capture_container="router"

mkdir -p "$ROOT_DIR/analisis/pcaps"

if [[ "$(docker inspect -f '{{.State.Status}}' monitor 2>/dev/null || true)" != "running" ]]; then
  echo "El contenedor monitor no esta corriendo. Levanta primero el laboratorio." >&2
  exit 1
fi

if [[ "$(docker inspect -f '{{.State.Status}}' "$capture_container" 2>/dev/null || true)" != "running" ]]; then
  echo "El contenedor $capture_container no esta corriendo. Levanta primero el laboratorio." >&2
  exit 1
fi

docker exec \
  -e CAPTURE_NODE="$capture_container" \
  -e CAPTURE_PUBLIC_IP="172.20.10.254" \
  -e CAPTURE_PRIVATE_IP="172.20.20.254" \
  -e CAPTURE_ATTACK_IP="172.20.30.254" \
  "$capture_container" \
  sh /opt/lab_scripts/monitor/start_capture.sh "$mode" "$label" "$ring_size_mb" "$ring_files"

echo
echo "Archivos de captura en: $ROOT_DIR/analisis/pcaps"
