#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

require_command curl

echo "Targets de Prometheus:"
curl -fsS "$PROM_URL/api/v1/targets"
echo
echo
echo "Disponibilidad de contenedores del laboratorio:"
curl -fsS --get --data-urlencode 'query=lab_container_up' "$PROM_URL/api/v1/query"
echo
echo
echo "Estado del web y la base de datos:"
curl -fsS --get --data-urlencode 'query=probe_success or mysql_up or apache_up' "$PROM_URL/api/v1/query"
echo
