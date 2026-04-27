#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

require_command curl

DURATION_SECONDS="${1:-60}"
INTERVAL_SECONDS="${2:-1}"
OUTPUT_FILE="${3:-$ROOT_DIR/analisis/trafico_legitimo.csv}"

mkdir -p "$(dirname "$OUTPUT_FILE")"
echo "timestamp,http_code,latency_seconds" >"$OUTPUT_FILE"

end_at=$((SECONDS + DURATION_SECONDS))
while (( SECONDS < end_at )); do
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
  response="$(curl -s -o /dev/null -w '%{http_code},%{time_total}' "$WEB_URL")"
  echo "$timestamp,$response" | tee -a "$OUTPUT_FILE"
  sleep "$INTERVAL_SECONDS"
done

echo
echo "Trafico legitimo registrado en: $OUTPUT_FILE"
