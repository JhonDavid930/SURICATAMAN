#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash -n "$ROOT_DIR/suricataman.sh"
bash -n "$ROOT_DIR/src/suricataman.sh"
bash -n "$ROOT_DIR/install.sh"
bash -n "$ROOT_DIR/scripts/build-standalone.sh"
bash -n "$ROOT_DIR/dist/suricataman-standalone.sh"

bash "$ROOT_DIR/suricataman.sh" --help >/dev/null
bash "$ROOT_DIR/suricataman.sh" --dry-run --help >/dev/null
bash "$ROOT_DIR/suricataman.sh" --version >/dev/null
HELP_OUTPUT="$(bash "$ROOT_DIR/suricataman.sh" --help)"
if ! grep -q -- "--doctor" <<<"$HELP_OUTPUT"; then
  echo "No se encontro --doctor en la ayuda."
  exit 1
fi
if ! grep -q -- "--report" <<<"$HELP_OUTPUT"; then
  echo "No se encontro --report en la ayuda."
  exit 1
fi
for option in --status --report-json --events --events-json --health-check --support-bundle --upgrade-all --limit --src --dst; do
  if ! grep -q -- "$option" <<<"$HELP_OUTPUT"; then
    echo "No se encontro $option en la ayuda."
    exit 1
  fi
done
bash "$ROOT_DIR/install.sh" --help >/dev/null
bash "$ROOT_DIR/dist/suricataman-standalone.sh" --version >/dev/null

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck \
    "$ROOT_DIR/suricataman.sh" \
    "$ROOT_DIR/src/suricataman.sh" \
    "$ROOT_DIR/install.sh" \
    "$ROOT_DIR/scripts/build-standalone.sh" \
    "$ROOT_DIR/dist/suricataman-standalone.sh"
else
  echo "shellcheck no esta instalado; se omitio esa validacion."
fi

echo "Validacion estatica completada."
