#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
duration_seconds="${1:-45}"
summary_file="$ROOT_DIR/analisis/pcaps/capturas_45s_resumen.txt"

mkdir -p "$ROOT_DIR/analisis/pcaps"

label_prefix_for_attack() {
  case "$1" in
    syn) echo "syn_${duration_seconds}s_red_publica" ;;
    udp) echo "udp_${duration_seconds}s_red_publica" ;;
    http) echo "http_${duration_seconds}s_red_publica" ;;
    sqli_dos) echo "sqli_${duration_seconds}s_red_privada" ;;
  esac
}

{
  echo "Resumen de capturas de 45 segundos"
  echo "Fecha UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Duracion por ataque: $duration_seconds segundos"
  echo ""
} >"$summary_file"

for attack in syn udp http sqli_dos; do
  echo "=============================="
  echo "Capturando ataque: $attack"
  bash "$SCRIPT_DIR/capture_attack.sh" "$attack" "$duration_seconds"
  echo "- $attack completado" >>"$summary_file"
  prefix="$(label_prefix_for_attack "$attack")"
  find "$ROOT_DIR/analisis/pcaps" -maxdepth 1 -type f \( -name "${prefix}*.pcap*" -o -name "${prefix}*.pcapng*" \) -printf "%T@ %f\n" |
    sort -nr |
    head -n 10 |
    awk '{print $2}' >>"$summary_file"
  echo "" >>"$summary_file"
  sleep 3
done

echo "Resumen guardado en: $summary_file"
