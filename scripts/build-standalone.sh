#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/src/suricataman.sh"
DIST_DIR="$ROOT_DIR/dist"
OUTPUT_FILE="$DIST_DIR/suricataman-standalone.sh"

mkdir -p "$DIST_DIR"

{
    echo "#!/usr/bin/env bash"
    echo "# Archivo standalone generado desde src/suricataman.sh."
    echo "# No editar manualmente: ejecuta scripts/build-standalone.sh."
    tail -n +2 "$SOURCE_FILE"
} > "$OUTPUT_FILE"

chmod +x "$OUTPUT_FILE"
echo "Standalone generado: $OUTPUT_FILE"
