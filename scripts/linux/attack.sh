#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [[ $# -lt 1 ]]; then
  echo "Uso: $(basename "$0") <udp|syn|ack|conntrack|http|sqli_dos>" >&2
  exit 1
fi

attack="$(normalize_attack "$1")"
trigger_attack "$attack"
echo
echo "Ataque lanzado: $attack"
