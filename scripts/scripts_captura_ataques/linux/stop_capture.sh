#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

require_command docker

if [[ "$(docker inspect -f '{{.State.Status}}' router 2>/dev/null || true)" != "running" ]]; then
  echo "El contenedor router no esta corriendo." >&2
  exit 1
fi

docker exec router sh /opt/lab_scripts/monitor/stop_capture.sh

echo
echo "Archivos de captura en: $ROOT_DIR/analisis/pcaps"
