#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

require_command curl
require_command docker

failures=0

check() {
  local name="$1"
  shift
  if "$@"; then
    echo "[OK] $name"
  else
    echo "[FAIL] $name" >&2
    failures=$((failures + 1))
  fi
}

http_code() {
  curl -s -o /dev/null -w "%{http_code}" "$1"
}

docker_state() {
  docker inspect -f '{{.State.Status}} {{if .State.Health}}{{.State.Health.Status}}{{end}}' "$1" 2>/dev/null
}

is_running() {
  [[ "$(docker_state "$1")" == running* ]]
}

is_healthy() {
  [[ "$(docker_state "$1")" == *healthy* ]]
}

syncookies_disabled() {
  [[ "$(docker exec servidor_web cat /proc/sys/net/ipv4/tcp_syncookies)" == "0" ]]
}

web_ready() {
  [[ "$(http_code "$WEB_URL")" == "200" ]]
}

panel_ready() {
  [[ "$(http_code "$PANEL_URL")" == "200" ]]
}

grafana_ready() {
  local code
  code="$(http_code "$GRAFANA_URL")"
  [[ "$code" == "200" || "$code" == "302" ]]
}

loki_ready() {
  [[ "$(curl -fsS "$LOKI_URL/ready")" == "ready" ]]
}

targets_up() {
  local response
  response="$(curl -fsS "$PROM_URL/api/v1/targets")"
  for job in apache_exporter blackbox_http blackbox_tcp cadvisor docker_metrics_exporter mysqld_exporter panel_control prometheus; do
    if ! grep -q "\"job\":\"$job\"" <<<"$response"; then
      return 1
    fi
    if ! grep -q "\"job\":\"$job\".*\"health\":\"up\"" <<<"$response"; then
      return 1
    fi
  done
}

dashboards_ready() {
  local response
  response="$(curl -fsS -u admin:admin "$GRAFANA_URL/api/search?query=")"
  for title in "Infraestructura General" "Servidor Web" "Base de Datos" "Red y Ataques" "Academico Explicativo" "Logs del Laboratorio"; do
    if ! grep -q "\"title\":\"$title\"" <<<"$response"; then
      return 1
    fi
  done
}

lab_metrics_ready() {
  local response
  response="$(curl -fsS --get --data-urlencode 'query=lab_container_up' "$PROM_URL/api/v1/query")"
  grep -q '"container":"servidor_web"' <<<"$response" &&
    grep -q '"container":"base_datos"' <<<"$response" &&
    grep -q '"container":"atacante"' <<<"$response"
}

check "router activo" is_running router
check "servidor_web saludable" is_healthy servidor_web
check "base_datos saludable" is_healthy base_datos
check "atacante saludable" is_healthy atacante
check "panel_control saludable" is_healthy panel_control
check "prometheus activo" is_running prometheus
check "grafana activo" is_running grafana
check "loki activo" is_running loki
check "tcp_syncookies desactivado" syncookies_disabled
check "EmpresaX responde 200" web_ready
check "Panel responde 200" panel_ready
check "Grafana responde 200 o 302" grafana_ready
check "Loki ready" loki_ready
check "Prometheus scrapea targets reales" targets_up
check "Grafana provisiono dashboards" dashboards_ready
check "Prometheus expone metricas del laboratorio" lab_metrics_ready

if (( failures > 0 )); then
  echo
  echo "Validacion finalizada con $failures fallo(s)." >&2
  exit 1
fi

echo
echo "Validacion completada sin fallos."
