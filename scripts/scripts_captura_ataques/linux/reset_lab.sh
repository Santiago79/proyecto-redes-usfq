#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo "Reinicializando el laboratorio (down -v y nuevo up -d --build)..."
compose down -v --remove-orphans
compose up -d --build

echo
echo "Laboratorio reiniciado."
