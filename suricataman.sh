#!/usr/bin/env bash

#LANZADOR DEL PROGRAMA SURICATAMAN
#ESTE SCRIPT LANZA EL PROGRAMA SURICATAMAN.SH QUE ES EL PROGRAMA PRINCIPAL
#PARA PODER EJECUTAR ESTE PROGRAMA SE DEBE TENER PERMISOS DE EJECUCION

set -euo pipefail

SOURCE_PATH="${BASH_SOURCE[0]}"
while [ -L "$SOURCE_PATH" ]; do
    SOURCE_DIR="$(cd -P "$(dirname "$SOURCE_PATH")" && pwd)"
    SOURCE_PATH="$(readlink "$SOURCE_PATH")"
    case "$SOURCE_PATH" in
        /*) ;;
        *) SOURCE_PATH="$SOURCE_DIR/$SOURCE_PATH" ;;
    esac
done

SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE_PATH")" && pwd)"
exec bash "$SCRIPT_DIR/src/suricataman.sh" "$@"
