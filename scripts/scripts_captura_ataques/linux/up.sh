#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo "Levantando el laboratorio y la capa de monitoreo..."
compose up -d --build

echo
echo "Servicios principales:"
compose ps

echo
echo "URLs:"
echo "  Web EmpresaX: $WEB_URL"
echo "  Panel DDoS:   $PANEL_URL"
echo "  Grafana:      $GRAFANA_URL"
echo "  Prometheus:   $PROM_URL"
echo "  Loki ready:   $LOKI_URL/ready"
