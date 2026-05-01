#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash -n "$ROOT_DIR/suricataman.sh"
bash -n "$ROOT_DIR/src/suricataman.sh"

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$ROOT_DIR/suricataman.sh" "$ROOT_DIR/src/suricataman.sh"
else
  echo "shellcheck no esta instalado; se omitio esa validacion."
fi

echo "Validacion estatica completada."
