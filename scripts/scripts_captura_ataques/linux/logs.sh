#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

service="${1:-}"

if [[ -n "$service" ]]; then
  compose logs -f "$service"
else
  compose logs -f
fi
