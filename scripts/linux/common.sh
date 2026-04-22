#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/infra/docker-compose.yml"
PANEL_URL="${PANEL_URL:-http://localhost:5000}"
WEB_URL="${WEB_URL:-http://localhost:8080}"
PROM_URL="${PROM_URL:-http://localhost:9090}"
GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
LOKI_URL="${LOKI_URL:-http://localhost:3100}"

compose() {
  docker compose -f "$COMPOSE_FILE" "$@"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Falta el comando requerido: $1" >&2
    exit 1
  fi
}

normalize_attack() {
  local raw="${1:-}"
  case "${raw,,}" in
    udp|udp_flood) echo "udp" ;;
    syn|syn_flood) echo "syn" ;;
    ack|ack_flood) echo "ack" ;;
    conntrack|conntrack_killer) echo "conntrack" ;;
    http|http_flood) echo "http" ;;
    sqli|sqli_dos|sqlidos|sqli-flood) echo "sqli_dos" ;;
    *)
      echo "Ataque no reconocido: $raw" >&2
      echo "Opciones: udp, syn, ack, conntrack, http, sqli_dos" >&2
      exit 1
      ;;
  esac
}

trigger_attack() {
  local attack="$1"
  require_command curl
  curl --fail --silent --show-error "$PANEL_URL/atacar/$attack"
}
