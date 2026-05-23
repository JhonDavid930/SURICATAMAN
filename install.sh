#!/usr/bin/env bash

set -euo pipefail

PROJECT_NAME="SURICATAMAN"
REPO_URL="${SURICATAMAN_REPO_URL:-https://github.com/JhonDavid930/SURICATAMAN.git}"
ARCHIVE_URL_BASE="${SURICATAMAN_ARCHIVE_URL_BASE:-https://github.com/JhonDavid930/SURICATAMAN/archive}"
DEFAULT_REF="main"
DEFAULT_INSTALL_DIR="/opt/suricataman"
DEFAULT_BIN_PATH="/usr/local/bin/suricataman"

INSTALL_REF="${SURICATAMAN_REF:-$DEFAULT_REF}"
INSTALL_DIR="${SURICATAMAN_INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"
BIN_PATH="${SURICATAMAN_BIN_PATH:-$DEFAULT_BIN_PATH}"
CREATE_SYMLINK=true
RUN_AFTER_INSTALL=false

usage() {
    cat <<EOF
$PROJECT_NAME installer

Uso:
  bash install.sh [opciones]

Opciones:
  --ref <ref>        Rama, tag o commit a instalar. Default: $DEFAULT_REF
  --dir <ruta>      Directorio de instalacion. Default: $DEFAULT_INSTALL_DIR
  --bin <ruta>      Ruta del comando global. Default: $DEFAULT_BIN_PATH
  --no-symlink      No crear comando global.
  --run             Ejecuta SURICATAMAN despues de instalar la herramienta.
  --help            Muestra esta ayuda.

Variables de entorno:
  SURICATAMAN_REF
  SURICATAMAN_INSTALL_DIR
  SURICATAMAN_BIN_PATH
  SURICATAMAN_REPO_URL
  SURICATAMAN_ARCHIVE_URL_BASE

Ejemplos:
  curl -fsSL https://raw.githubusercontent.com/JhonDavid930/SURICATAMAN/main/install.sh | sudo bash
  curl -fsSL https://raw.githubusercontent.com/JhonDavid930/SURICATAMAN/main/install.sh | sudo bash -s -- --ref v2.6.0
  SURICATAMAN_INSTALL_DIR="\$HOME/.local/share/suricataman" bash install.sh --no-symlink
EOF
}

run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        echo "Error: se requieren permisos de root o sudo para instalar en $INSTALL_DIR." >&2
        return 1
    fi
}

require_command() {
    local command_name="$1"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Error: falta el comando requerido: $command_name" >&2
        return 1
    fi
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --ref)
                INSTALL_REF="${2:-}"
                shift 2
                ;;
            --dir)
                INSTALL_DIR="${2:-}"
                shift 2
                ;;
            --bin)
                BIN_PATH="${2:-}"
                shift 2
                ;;
            --no-symlink)
                CREATE_SYMLINK=false
                shift
                ;;
            --run)
                RUN_AFTER_INSTALL=true
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                echo "Opcion no reconocida: $1" >&2
                usage
                exit 1
                ;;
        esac
    done

    if [ -z "$INSTALL_REF" ] || [ -z "$INSTALL_DIR" ]; then
        echo "Error: --ref y --dir no pueden estar vacios." >&2
        exit 1
    fi
}

download_with_git() {
    local target_dir="$1"

    git clone --depth 1 --branch "$INSTALL_REF" "$REPO_URL" "$target_dir"
}

download_with_archive() {
    local target_dir="$1"
    local archive_file="$2"
    local encoded_ref

    encoded_ref="${INSTALL_REF//\//%2F}"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$ARCHIVE_URL_BASE/$encoded_ref.tar.gz" -o "$archive_file"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$archive_file" "$ARCHIVE_URL_BASE/$encoded_ref.tar.gz"
    else
        echo "Error: instala git, curl o wget para descargar $PROJECT_NAME." >&2
        return 1
    fi

    mkdir -p "$target_dir"
    tar -xzf "$archive_file" --strip-components=1 -C "$target_dir"
}

download_project() {
    local target_dir="$1"
    local archive_file="$2"

    if command -v git >/dev/null 2>&1 && download_with_git "$target_dir"; then
        return 0
    fi

    require_command tar
    download_with_archive "$target_dir" "$archive_file"
}

install_project() {
    local source_dir="$1"

    run_as_root mkdir -p "$INSTALL_DIR"
    run_as_root cp -R "$source_dir/." "$INSTALL_DIR/"
    run_as_root chmod +x "$INSTALL_DIR/suricataman.sh" "$INSTALL_DIR/src/suricataman.sh"

    if [ -f "$INSTALL_DIR/dist/suricataman-standalone.sh" ]; then
        run_as_root chmod +x "$INSTALL_DIR/dist/suricataman-standalone.sh"
    fi

    if [ "$CREATE_SYMLINK" = true ]; then
        run_as_root ln -sf "$INSTALL_DIR/suricataman.sh" "$BIN_PATH"
    fi
}

main() {
    local tmp_dir
    local source_dir
    local archive_file

    parse_args "$@"

    tmp_dir="$(mktemp -d)"
    source_dir="$tmp_dir/$PROJECT_NAME"
    archive_file="$tmp_dir/$PROJECT_NAME.tar.gz"
    trap 'rm -rf "${tmp_dir:-}"' EXIT

    echo "Descargando $PROJECT_NAME ($INSTALL_REF)..."
    download_project "$source_dir" "$archive_file"

    echo "Instalando herramienta en $INSTALL_DIR..."
    install_project "$source_dir"

    echo "$PROJECT_NAME instalado correctamente."
    echo "Directorio: $INSTALL_DIR"
    if [ "$CREATE_SYMLINK" = true ]; then
        echo "Comando global: $BIN_PATH"
        echo "Ejecuta: sudo $BIN_PATH"
    else
        echo "Ejecuta: sudo $INSTALL_DIR/suricataman.sh"
    fi

    if [ "$RUN_AFTER_INSTALL" = true ]; then
        run_as_root bash "$INSTALL_DIR/suricataman.sh"
    fi
}

main "$@"
