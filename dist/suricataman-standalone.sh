#!/usr/bin/env bash
# Archivo standalone generado desde src/suricataman.sh.
# No editar manualmente: ejecuta scripts/build-standalone.sh.

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Variables globales
PROJECT_VERSION="2.4.0"
LOG_DIR="/var/log/suricataman"
LOG_FILE="$LOG_DIR/suricataman.log"
LOGROTATE_FILE="/etc/logrotate.d/suricataman"
SURICATA_CONFIG="/etc/suricata/suricata.yaml"
REPORT_DIR="$LOG_DIR/reports"
SURICATA_FAST_LOG="/var/log/suricata/fast.log"
SURICATA_EVE_LOG="/var/log/suricata/eve.json"
PACKAGE_CACHE_UPDATED=false
DRY_RUN=false
SURICATAMAN_LOGS_REMOVED=false
ACTION="menu"
DOCTOR_WARNINGS=0
DOCTOR_FAILURES=0
LOG_STDOUT=true
EVENT_LINES=20

log() {
    local message="$1"
    local formatted_message

    if [ ! -d "$LOG_DIR" ]; then
        sudo mkdir -p "$LOG_DIR" 2>/dev/null || mkdir -p "$LOG_DIR"
    fi

    if [ ! -f "$LOG_FILE" ]; then
        sudo touch "$LOG_FILE" 2>/dev/null || touch "$LOG_FILE"
    fi

    if [ -n "${SUDO_USER:-}" ]; then
        sudo chown "$SUDO_USER":"$SUDO_USER" "$LOG_DIR" 2>/dev/null || true
        sudo chown "$SUDO_USER":"$SUDO_USER" "$LOG_FILE" 2>/dev/null || true
    fi

    formatted_message="$(date '+%Y-%m-%d %H:%M:%S') - $message"
    if [ "$LOG_STDOUT" = true ]; then
        echo -e "$formatted_message" | tee -a "$LOG_FILE"
    else
        printf '%b\n' "$formatted_message" >> "$LOG_FILE"
    fi
}

run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        log "${YELLOW}[DRY-RUN] $*${NC}"
        return 0
    fi

    "$@"
}

safe_clear() {
    if [ -t 1 ] && command -v clear >/dev/null 2>&1; then
        clear 2>/dev/null || true
    fi
}

show_progress() {
    local duration="$1"
    local title="$2"

    echo -ne "${YELLOW}${title}${NC}\n"
    for ((i = 0; i <= 100; i += 5)); do
        printf "\r["
        for ((j = 0; j <= i; j += 5)); do
            printf "#"
        done
        for ((j = i + 5; j <= 100; j += 5)); do
            printf " "
        done
        printf "] %d%%" "$i"
        if command -v bc >/dev/null 2>&1; then
            sleep "$(echo "scale=2; $duration/20" | bc)"
        else
            sleep 0.1
        fi
    done
    echo -e "\n"
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}Este script debe ejecutarse como root o con sudo.${NC}"
        exit 1
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        OS_NAME="${NAME:-Desconocido}"
        OS_VERSION="${VERSION_ID:-Desconocida}"
        ID="${ID:-}"
        log "${GREEN}Sistema detectado: $OS_NAME $OS_VERSION${NC}"
    else
        log "${RED}No se pudo detectar el sistema operativo.${NC}"
        return 1
    fi
}

is_suricata_installed() {
    command -v suricata >/dev/null 2>&1
}

is_package_installed() {
    local package="$1"

    case "$ID" in
        ubuntu | debian | kali)
            dpkg -s "$package" >/dev/null 2>&1
            ;;
        centos | rhel | fedora)
            rpm -q "$package" >/dev/null 2>&1
            ;;
        arch)
            pacman -Q "$package" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

update_package_cache() {
    if [ "$PACKAGE_CACHE_UPDATED" = true ]; then
        log "${YELLOW}La caché de paquetes ya fue actualizada en esta ejecución.${NC}"
        return 0
    fi

    log "${YELLOW}Actualizando caché de paquetes...${NC}"
    case "$ID" in
        ubuntu | debian | kali)
            run_cmd sudo apt-get update || { log "${RED}Fallo al actualizar la caché con apt-get.${NC}"; return 1; }
            ;;
        centos | rhel)
            run_cmd sudo yum makecache -y || { log "${RED}Fallo al actualizar la caché con yum.${NC}"; return 1; }
            ;;
        fedora)
            run_cmd sudo dnf makecache -y || { log "${RED}Fallo al actualizar la caché con dnf.${NC}"; return 1; }
            ;;
        arch)
            run_cmd sudo pacman -Sy --noconfirm || { log "${RED}Fallo al actualizar la caché con pacman.${NC}"; return 1; }
            ;;
        *)
            log "${RED}Distribución no soportada para actualizar caché de paquetes.${NC}"
            return 1
            ;;
    esac

    PACKAGE_CACHE_UPDATED=true
}

install_package() {
    local package="$1"

    if is_package_installed "$package"; then
        log "${GREEN}$package ya está instalado. No se requiere instalación.${NC}"
        return 0
    fi

    update_package_cache || return 1
    log "${YELLOW}Instalando paquete: $package${NC}"
    case "$ID" in
        ubuntu | debian | kali)
            run_cmd sudo apt-get install -y "$package"
            ;;
        centos | rhel)
            run_cmd sudo yum install -y "$package"
            ;;
        fedora)
            run_cmd sudo dnf install -y "$package"
            ;;
        arch)
            run_cmd sudo pacman -S --noconfirm "$package"
            ;;
        *)
            log "${RED}Distribución no soportada para instalar $package.${NC}"
            return 1
            ;;
    esac
}

install_bc() {
    if command -v bc >/dev/null 2>&1; then
        log "${GREEN}bc ya está instalado. No se requiere instalación.${NC}"
        return 0
    fi

    install_package "bc" || { log "${RED}Fallo al instalar bc.${NC}"; return 1; }
}

install_dependencies() {
    local dependencies=("curl" "gnupg" "jq")
    local package

    log "${YELLOW}Verificando dependencias base...${NC}"
    for package in "${dependencies[@]}"; do
        install_package "$package" || { log "${RED}Fallo al instalar dependencia: $package${NC}"; return 1; }
    done
}

configure_logrotate() {
    log "${YELLOW}Verificando configuración de logrotate para Suricataman...${NC}"

    if [ -f "$LOGROTATE_FILE" ]; then
        log "${GREEN}Logrotate ya está configurado en $LOGROTATE_FILE${NC}"
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        log "${YELLOW}[DRY-RUN] Crear $LOGROTATE_FILE para rotar $LOG_FILE${NC}"
        return 0
    fi

    sudo tee "$LOGROTATE_FILE" >/dev/null <<EOF
$LOG_FILE {
    weekly
    rotate 4
    compress
    missingok
    notifempty
    create 640 root adm
}
EOF

    log "${GREEN}Configuración de logrotate creada en $LOGROTATE_FILE${NC}"
}

enable_suricata_service() {
    if [ "$DRY_RUN" = true ]; then
        run_cmd sudo systemctl enable suricata.service
        return 0
    fi

    if run_cmd sudo systemctl enable suricata.service >/dev/null 2>&1; then
        log "${GREEN}Servicio Suricata habilitado para iniciar en el arranque.${NC}"
    else
        log "${YELLOW}Advertencia: no se pudo habilitar Suricata en el arranque.${NC}"
    fi
}

install_suricata() {
    local reinstall_answer

    if is_suricata_installed; then
        read -r -p "Suricata ya está instalado. ¿Reinstalar? (S/N): " reinstall_answer
        case "$reinstall_answer" in
            S | s)
                log "${YELLOW}El usuario confirmó reinstalación de Suricata.${NC}"
                ;;
            N | n)
                log "${YELLOW}Instalación cancelada por el usuario. Suricata ya estaba instalado.${NC}"
                return 1
                ;;
            *)
                log "${RED}Respuesta inválida. Instalación cancelada.${NC}"
                return 1
                ;;
        esac
    fi

    log "${YELLOW}Instalando Suricata...${NC}"
    case "$ID" in
        ubuntu)
            update_package_cache || return 1
            run_cmd sudo add-apt-repository -y ppa:oisf/suricata-stable || { log "${RED}Fallo al añadir el repositorio estable de Suricata.${NC}"; return 1; }
            PACKAGE_CACHE_UPDATED=false
            update_package_cache || return 1
            run_cmd sudo apt-get install -y suricata || { log "${RED}Fallo al instalar Suricata con apt-get.${NC}"; return 1; }
            ;;
        debian | kali)
            update_package_cache || return 1
            run_cmd sudo apt-get install -y suricata || { log "${RED}Fallo al instalar Suricata con apt-get.${NC}"; return 1; }
            ;;
        centos | rhel)
            install_package "epel-release" || return 1
            run_cmd sudo yum install -y suricata || { log "${RED}Fallo al instalar Suricata con yum.${NC}"; return 1; }
            ;;
        fedora)
            update_package_cache || return 1
            run_cmd sudo dnf install -y suricata || { log "${RED}Fallo al instalar Suricata con dnf.${NC}"; return 1; }
            ;;
        arch)
            update_package_cache || return 1
            run_cmd sudo pacman -S --noconfirm suricata || { log "${RED}Fallo al instalar Suricata con pacman.${NC}"; return 1; }
            ;;
        *)
            log "${RED}Distribución no soportada para la instalación de Suricata.${NC}"
            return 1
            ;;
    esac

    if [ "$DRY_RUN" = true ] || is_suricata_installed; then
        local version="Suricata no disponible todavía"
        local paths="No disponible"
        if is_suricata_installed; then
            version="$(suricata -V 2>&1 | head -n 1)"
            paths="$(whereis suricata)"
        fi
        log "${GREEN}Suricata instalado exitosamente. $version${NC}"
        log "${YELLOW}Rutas donde se encuentra Suricata:${NC}"
        log "${PURPLE}$paths${NC}"
        enable_suricata_service
        return 0
    fi

    log "${RED}Fallo al instalar Suricata. Por favor, verifica los logs para más detalles.${NC}"
    return 1
}

ask_delete_suricataman_logs() {
    local answer

    read -r -p "¿Quieres eliminar también los logs de SURICATAMAN? (S/N): " answer
    case "$answer" in
        S | s)
            if [ -d "$LOG_DIR" ]; then
                run_cmd sudo rm -rf "$LOG_DIR" || { echo -e "${RED}No se pudieron eliminar los logs de SURICATAMAN.${NC}"; return 1; }
                if [ "$DRY_RUN" != true ]; then
                    SURICATAMAN_LOGS_REMOVED=true
                fi
                echo -e "${GREEN}Logs de SURICATAMAN eliminados.${NC}"
            else
                echo -e "${YELLOW}No existe $LOG_DIR.${NC}"
            fi
            ;;
        N | n)
            log "${YELLOW}Se conservan los logs de SURICATAMAN en $LOG_DIR.${NC}"
            ;;
        *)
            log "${YELLOW}Entrada inválida. Por seguridad se conservan los logs de SURICATAMAN.${NC}"
            ;;
    esac
}

uninstall_suricata() {
    log "${YELLOW}Desinstalando Suricata...${NC}"
    case "$ID" in
        ubuntu)
            run_cmd sudo apt-get remove --purge -y suricata || { log "${RED}Fallo al desinstalar Suricata con apt-get.${NC}"; return 1; }
            run_cmd sudo add-apt-repository -r -y ppa:oisf/suricata-stable || log "${YELLOW}Advertencia: no se pudo retirar el repositorio PPA de Suricata.${NC}"
            PACKAGE_CACHE_UPDATED=false
            update_package_cache || log "${YELLOW}Advertencia: no se pudo actualizar la caché después de desinstalar.${NC}"
            ;;
        debian | kali)
            run_cmd sudo apt-get remove --purge -y suricata || { log "${RED}Fallo al desinstalar Suricata con apt-get.${NC}"; return 1; }
            ;;
        centos | rhel)
            run_cmd sudo yum remove -y suricata || { log "${RED}Fallo al desinstalar Suricata con yum.${NC}"; return 1; }
            ;;
        fedora)
            run_cmd sudo dnf remove -y suricata || { log "${RED}Fallo al desinstalar Suricata con dnf.${NC}"; return 1; }
            ;;
        arch)
            run_cmd sudo pacman -Rns --noconfirm suricata || { log "${RED}Fallo al desinstalar Suricata con pacman.${NC}"; return 1; }
            ;;
        *)
            log "${RED}Distribución no soportada para la desinstalación de Suricata.${NC}"
            return 1
            ;;
    esac

    log "${YELLOW}Eliminando archivos de configuración y datos de Suricata...${NC}"
    run_cmd sudo rm -rf /etc/suricata /var/lib/suricata /usr/share/suricata /var/log/suricata || {
        log "${RED}Fallo al eliminar archivos relacionados con Suricata.${NC}"
        return 1
    }

    ask_delete_suricataman_logs
    if [ "$SURICATAMAN_LOGS_REMOVED" = true ]; then
        echo -e "${GREEN}Suricata y archivos relacionados han sido desinstalados exitosamente.${NC}"
    else
        log "${GREEN}Suricata y archivos relacionados han sido desinstalados exitosamente.${NC}"
    fi
}

update_suricata() {
    log "${YELLOW}Actualizando Suricata...${NC}"
    case "$ID" in
        ubuntu | debian | kali)
            update_package_cache || return 1
            run_cmd sudo apt-get install --only-upgrade -y suricata || { log "${RED}Fallo al actualizar Suricata con apt-get.${NC}"; return 1; }
            ;;
        centos | rhel)
            update_package_cache || return 1
            run_cmd sudo yum update -y suricata || { log "${RED}Fallo al actualizar Suricata con yum.${NC}"; return 1; }
            ;;
        fedora)
            update_package_cache || return 1
            run_cmd sudo dnf upgrade -y suricata || { log "${RED}Fallo al actualizar Suricata con dnf.${NC}"; return 1; }
            ;;
        arch)
            update_package_cache || return 1
            run_cmd sudo pacman -S --noconfirm suricata || { log "${RED}Fallo al actualizar Suricata con pacman.${NC}"; return 1; }
            ;;
        *)
            log "${RED}Distribución no soportada para la actualización de Suricata.${NC}"
            return 1
            ;;
    esac

    if [ "$DRY_RUN" = true ] || is_suricata_installed; then
        local version="Suricata no disponible todavía"
        local paths="No disponible"
        if is_suricata_installed; then
            version="$(suricata -V 2>&1 | head -n 1)"
            paths="$(whereis suricata)"
        fi
        log "${GREEN}Suricata actualizado exitosamente. $version${NC}"
        log "${YELLOW}Rutas donde se encuentra Suricata:${NC}"
        log "${PURPLE}$paths${NC}"
        return 0
    fi

    log "${RED}Fallo al actualizar Suricata. Por favor, verifica los logs para más detalles.${NC}"
    return 1
}

backup_suricata_config() {
    local backup_file="/etc/suricata/suricata.yaml.bak.$(date '+%Y%m%d_%H%M%S')"

    if [ ! -f "$SURICATA_CONFIG" ]; then
        if [ "$DRY_RUN" = true ]; then
            log "${YELLOW}[DRY-RUN] Crear backup $backup_file desde $SURICATA_CONFIG${NC}"
            printf '%s\n' "$backup_file"
            return 0
        fi
        log "${RED}No existe $SURICATA_CONFIG. No se puede crear backup.${NC}"
        return 1
    fi

    run_cmd sudo cp "$SURICATA_CONFIG" "$backup_file" || { log "${RED}No se pudo crear backup de $SURICATA_CONFIG.${NC}"; return 1; }
    log "${GREEN}Backup creado: $backup_file${NC}"
    printf '%s\n' "$backup_file"
}

detect_default_interface() {
    ip route show default 2>/dev/null | awk '{print $5; exit}'
}

configure_suricata() {
    local interface

    log "${YELLOW}Configurando Suricata...${NC}"
    interface="$(detect_default_interface)"

    if [ -z "$interface" ]; then
        log "${RED}No se pudo determinar automáticamente la interfaz de red.${NC}"
        read -r -p "Introduce el nombre de la interfaz de red manualmente (ej. eth0, wlan0): " interface
        if [ -z "$interface" ]; then
            log "${RED}No se ha proporcionado ninguna interfaz válida. Cancelando configuración.${NC}"
            return 1
        fi
    else
        log "${GREEN}Se ha detectado automáticamente la interfaz de red: $interface${NC}"
    fi

    if ! ip link show "$interface" >/dev/null 2>&1; then
        log "${RED}La interfaz $interface no existe. Cancelando configuración.${NC}"
        return 1
    fi

    backup_suricata_config >/dev/null || return 1
    run_cmd sudo sed -i "/^  - interface:/c\\  - interface: $interface" "$SURICATA_CONFIG" || {
        log "${RED}Fallo al modificar $SURICATA_CONFIG.${NC}"
        return 1
    }

    log "${GREEN}Suricata ha sido configurado para usar la interfaz: $interface${NC}"
}

update_rules() {
    log "${YELLOW}Descargando e instalando reglas de Suricata...${NC}"

    if ! is_suricata_installed && [ "$DRY_RUN" != true ]; then
        log "${RED}Suricata no está instalado. No se pueden actualizar reglas.${NC}"
        return 1
    fi

    run_cmd sudo suricata-update || { log "${RED}Fallo al actualizar las reglas de Suricata.${NC}"; return 1; }
    log "${GREEN}Reglas de Suricata actualizadas correctamente.${NC}"
}

validate_suricata_config() {
    log "${YELLOW}Validando configuración de Suricata...${NC}"

    if [ "$DRY_RUN" = true ]; then
        log "${YELLOW}[DRY-RUN] sudo suricata -T -c $SURICATA_CONFIG${NC}"
        log "${GREEN}Configuración de Suricata válida en modo dry-run.${NC}"
        return 0
    fi

    if sudo suricata -T -c "$SURICATA_CONFIG"; then
        log "${GREEN}Configuración de Suricata válida.${NC}"
        return 0
    fi

    log "${RED}Configuración de Suricata inválida. No se reinicia el servicio.${NC}"
    return 1
}

restart_suricata() {
    log "${YELLOW}Preparando reinicio de Suricata...${NC}"

    if ! is_suricata_installed && [ "$DRY_RUN" != true ]; then
        log "${RED}Suricata no está instalado. No se puede reiniciar.${NC}"
        return 1
    fi

    validate_suricata_config || return 1
    run_cmd sudo systemctl restart suricata.service || { log "${RED}Fallo al reiniciar el servicio de Suricata.${NC}"; return 1; }
    log "${GREEN}Servicio Suricata reiniciado correctamente.${NC}"
}

set_af_packet_state() {
    local desired_state="$1"
    local backup_file

    if [ ! -f "$SURICATA_CONFIG" ]; then
        log "${RED}No existe $SURICATA_CONFIG. No se puede modificar af-packet.${NC}"
        return 1
    fi

    backup_file="$(backup_suricata_config | tail -n 1)" || return 1

    run_cmd sudo sed -i "/^[[:space:]]*af-packet:/,/^[^[:space:]#]/ s/^\\([[:space:]]*enabled:[[:space:]]*\\).*/\\1$desired_state/" "$SURICATA_CONFIG" || {
        log "${RED}No se pudo modificar af-packet en $SURICATA_CONFIG.${NC}"
        return 1
    }

    if validate_suricata_config; then
        log "${GREEN}af-packet actualizado a enabled: $desired_state.${NC}"
        return 0
    fi

    log "${RED}La configuración resultó inválida después de modificar af-packet.${NC}"
    if [ "$DRY_RUN" = true ]; then
        log "${YELLOW}[DRY-RUN] Restaurar backup $backup_file${NC}"
        return 1
    fi

    if run_cmd sudo cp "$backup_file" "$SURICATA_CONFIG"; then
        log "${YELLOW}Se restauró el backup: $backup_file${NC}"
    else
        log "${RED}No se pudo restaurar el backup automáticamente: $backup_file${NC}"
    fi
    return 1
}

advanced_config_menu() {
    local option

    while true; do
        safe_clear
        echo -e "${BLUE}Configuración avanzada de Suricata${NC}"
        echo "1) Habilitar af-packet"
        echo "2) Deshabilitar af-packet"
        echo "3) Volver al menú principal"
        read -r -p "Opción [1-3]: " option

        case "$option" in
            1)
                set_af_packet_state "yes"
                ;;
            2)
                set_af_packet_state "no"
                ;;
            3)
                return 0
                ;;
            *)
                log "${RED}Opción avanzada inválida.${NC}"
                ;;
        esac
        read -r -p "Presiona Enter para continuar..."
    done
}

show_path_info() {
    local path="$1"
    local description="$2"

    echo -e "${PURPLE}$path${NC}"
    echo "Descripción: $description"

    if compgen -G "$path" >/dev/null 2>&1; then
        local matched_path
        # shellcheck disable=SC2086
        for matched_path in $path; do
            echo -e "${GREEN}Existe:${NC} $matched_path"
            ls -ld "$matched_path" || true
            if [ -d "$matched_path" ]; then
                echo "Primeros elementos:"
                ls -la "$matched_path" 2>/dev/null | head -n 12 || true
            elif [ -f "$matched_path" ]; then
                echo "Tamaño:"
                stat -c '%s bytes' "$matched_path" 2>/dev/null || wc -c < "$matched_path"
                echo "Últimas 10 líneas:"
                tail -n 10 "$matched_path" 2>/dev/null || true
            fi
            echo ""
        done
    else
        echo -e "${YELLOW}No existe.${NC}"
        echo ""
    fi
}

offer_safe_path_recreation() {
    local answer

    read -r -p "¿Deseas recrear rutas seguras faltantes de SURICATAMAN? (S/N): " answer
    case "$answer" in
        S | s)
            run_cmd sudo mkdir -p "$LOG_DIR" || log "${RED}No se pudo recrear $LOG_DIR.${NC}"
            configure_logrotate
            ;;
        N | n)
            log "${YELLOW}No se recrearon rutas seguras.${NC}"
            ;;
        *)
            log "${YELLOW}Entrada inválida. No se recrearon rutas por seguridad.${NC}"
            ;;
    esac
}

manage_paths() {
    safe_clear
    echo -e "${BLUE}Rutas y archivos importantes de Suricataman${NC}"
    echo ""

    show_path_info "$SURICATA_CONFIG" "Configuración principal de Suricata."
    show_path_info "/etc/suricata/suricata.yaml.bak.*" "Backups de configuración."
    show_path_info "$LOG_FILE" "Logs de SURICATAMAN."
    show_path_info "$LOGROTATE_FILE" "Configuración de rotación de logs."
    show_path_info "/var/log/suricata" "Logs nativos de Suricata."
    show_path_info "/var/lib/suricata" "Reglas y datos internos de Suricata."
    show_path_info "/usr/share/suricata" "Archivos compartidos, plantillas o recursos de Suricata."

    echo -e "${YELLOW}No se borran rutas críticas desde este submenú.${NC}"
    offer_safe_path_recreation
}

doctor_line() {
    local status="$1"
    local label="$2"
    local detail="${3:-}"
    local recommendation="${4:-}"

    case "$status" in
        OK)
            echo -e "${GREEN}[OK]${NC} $label${detail:+ - $detail}"
            ;;
        WARN)
            DOCTOR_WARNINGS=$((DOCTOR_WARNINGS + 1))
            echo -e "${YELLOW}[WARN]${NC} $label${detail:+ - $detail}"
            if [ -n "$recommendation" ]; then
                echo "      Recomendacion: $recommendation"
            fi
            ;;
        FAIL)
            DOCTOR_FAILURES=$((DOCTOR_FAILURES + 1))
            echo -e "${RED}[FAIL]${NC} $label${detail:+ - $detail}"
            if [ -n "$recommendation" ]; then
                echo "      Recomendacion: $recommendation"
            fi
            ;;
        INFO)
            echo -e "${BLUE}[INFO]${NC} $label${detail:+ - $detail}"
            ;;
    esac
}

get_configured_interface() {
    if [ -f "$SURICATA_CONFIG" ]; then
        awk '/^[[:space:]]*-[[:space:]]*interface:/ {print $3; exit}' "$SURICATA_CONFIG" 2>/dev/null
    fi
}

get_suricata_version() {
    if is_suricata_installed; then
        suricata -V 2>&1 | head -n 1
    else
        printf '%s\n' "No instalado"
    fi
}

get_service_state() {
    local query="$1"

    if command -v systemctl >/dev/null 2>&1; then
        systemctl "$query" suricata.service 2>/dev/null || true
    else
        printf '%s\n' "systemctl-no-disponible"
    fi
}

check_suricata_config_quiet() {
    if [ "$DRY_RUN" = true ]; then
        return 0
    fi

    is_suricata_installed || return 1
    [ -f "$SURICATA_CONFIG" ] || return 1
    sudo suricata -T -c "$SURICATA_CONFIG" >/dev/null 2>&1
}

get_rules_update_time() {
    local rules_file="/var/lib/suricata/rules/suricata.rules"

    if [ -f "$rules_file" ]; then
        stat -c '%y' "$rules_file" 2>/dev/null | cut -d'.' -f1
    else
        printf '%s\n' "No disponible"
    fi
}

json_escape() {
    local value="$1"

    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\n'/\\n}"
    value="${value//$'\r'/}"
    printf '%s' "$value"
}

run_doctor() {
    local suricata_version="No instalado"
    local service_active="No disponible"
    local service_enabled="No disponible"
    local configured_interface=""
    local rules_path="/var/lib/suricata/rules"

    DOCTOR_WARNINGS=0
    DOCTOR_FAILURES=0

    echo -e "${BLUE}Diagnostico operativo de SURICATAMAN${NC}"
    echo "Version: $PROJECT_VERSION"
    echo "Sistema: ${OS_NAME:-Desconocido} ${OS_VERSION:-Desconocida} (${ID:-sin-id})"
    echo ""

    if is_suricata_installed; then
        suricata_version="$(get_suricata_version)"
        doctor_line "OK" "Binario de Suricata encontrado" "$suricata_version"
    else
        doctor_line "FAIL" "Binario de Suricata no encontrado" "no instalado" "Ejecuta sudo suricataman --install."
    fi

    if command -v systemctl >/dev/null 2>&1; then
        service_active="$(get_service_state is-active)"
        service_enabled="$(get_service_state is-enabled)"

        if [ "$service_active" = "active" ]; then
            doctor_line "OK" "Servicio suricata.service activo" "$service_active"
        else
            doctor_line "WARN" "Servicio suricata.service no activo" "$service_active" "Ejecuta sudo suricataman --restart despues de validar la configuracion."
        fi

        if [ "$service_enabled" = "enabled" ]; then
            doctor_line "OK" "Servicio habilitado al arranque" "$service_enabled"
        else
            doctor_line "WARN" "Servicio no habilitado al arranque" "$service_enabled" "Ejecuta sudo systemctl enable suricata.service."
        fi
    else
        doctor_line "WARN" "systemctl no esta disponible" "no se puede consultar estado del servicio"
    fi

    if [ -f "$SURICATA_CONFIG" ]; then
        doctor_line "OK" "Configuracion principal encontrada" "$SURICATA_CONFIG"
    else
        doctor_line "FAIL" "Configuracion principal no encontrada" "$SURICATA_CONFIG" "Ejecuta sudo suricataman --install o reinstala el paquete de Suricata."
    fi

    configured_interface="$(get_configured_interface)"
    if [ -n "$configured_interface" ]; then
        if ip link show "$configured_interface" >/dev/null 2>&1; then
            doctor_line "OK" "Interfaz configurada existe" "$configured_interface"
        else
            doctor_line "FAIL" "Interfaz configurada no existe" "$configured_interface" "Ejecuta sudo suricataman --configure y selecciona una interfaz valida."
        fi
    else
        doctor_line "WARN" "No se pudo detectar la interfaz configurada" "$SURICATA_CONFIG" "Revisa af-packet en suricata.yaml o ejecuta sudo suricataman --configure."
    fi

    if is_suricata_installed && [ -f "$SURICATA_CONFIG" ]; then
        if [ "$DRY_RUN" = true ]; then
            doctor_line "INFO" "Validacion de configuracion omitida en dry-run" "sudo suricata -T -c $SURICATA_CONFIG"
        elif check_suricata_config_quiet; then
            doctor_line "OK" "Configuracion validada con suricata -T" "$SURICATA_CONFIG"
        else
            doctor_line "FAIL" "Configuracion invalida segun suricata -T" "$SURICATA_CONFIG" "Restaura el ultimo backup o corrige el YAML antes de reiniciar."
        fi
    else
        doctor_line "WARN" "Validacion de configuracion no ejecutada" "faltan Suricata o $SURICATA_CONFIG" "Completa la instalacion antes de validar."
    fi

    if [ -d "$rules_path" ]; then
        doctor_line "OK" "Directorio de reglas encontrado" "$rules_path, ultima actualizacion: $(get_rules_update_time)"
    else
        doctor_line "WARN" "Directorio de reglas no encontrado" "$rules_path" "Ejecuta sudo suricataman --update-rules."
    fi

    if [ -f "$LOG_FILE" ]; then
        doctor_line "OK" "Log de SURICATAMAN disponible" "$LOG_FILE"
    else
        doctor_line "WARN" "Log de SURICATAMAN no encontrado" "$LOG_FILE" "Ejecuta cualquier accion de SURICATAMAN para crearlo."
    fi

    if [ -f "$LOGROTATE_FILE" ]; then
        doctor_line "OK" "Logrotate configurado" "$LOGROTATE_FILE"
    else
        doctor_line "WARN" "Logrotate no configurado" "$LOGROTATE_FILE" "Ejecuta sudo suricataman --install o recrea rutas desde --show-paths."
    fi

    echo ""
    echo "Resumen: $DOCTOR_FAILURES fallo(s), $DOCTOR_WARNINGS advertencia(s)."

    if [ "$DOCTOR_FAILURES" -gt 0 ]; then
        log "${RED}Doctor finalizado con $DOCTOR_FAILURES fallo(s) y $DOCTOR_WARNINGS advertencia(s).${NC}"
        return 1
    fi

    log "${GREEN}Doctor finalizado con $DOCTOR_FAILURES fallo(s) y $DOCTOR_WARNINGS advertencia(s).${NC}"
    return 0
}

generate_report() {
    local timestamp
    local report_file
    local tmp_report
    local doctor_status=0
    local old_red="$RED"
    local old_green="$GREEN"
    local old_yellow="$YELLOW"
    local old_blue="$BLUE"
    local old_purple="$PURPLE"
    local old_nc="$NC"
    local old_log_stdout="$LOG_STDOUT"

    timestamp="$(date '+%Y%m%d_%H%M%S')"
    report_file="$REPORT_DIR/suricataman-report-$timestamp.txt"

    if [ "$DRY_RUN" = true ]; then
        log "${YELLOW}[DRY-RUN] Crear reporte operativo en $report_file${NC}"
        run_doctor || return 1
        return 0
    fi

    sudo mkdir -p "$REPORT_DIR" || { log "${RED}No se pudo crear $REPORT_DIR.${NC}"; return 1; }
    tmp_report="$(mktemp)"
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    PURPLE=""
    NC=""
    LOG_STDOUT=false

    {
        echo "SURICATAMAN - Reporte operativo"
        echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Version: $PROJECT_VERSION"
        echo ""
        run_doctor || doctor_status=$?
        echo ""
        echo "Rutas clave:"
        echo "- Configuracion: $SURICATA_CONFIG"
        echo "- Logs SURICATAMAN: $LOG_FILE"
        echo "- Reporte: $report_file"
        echo "- Logrotate: $LOGROTATE_FILE"
        echo "- Logs Suricata: /var/log/suricata"
        echo "- Datos Suricata: /var/lib/suricata"
    } > "$tmp_report"

    RED="$old_red"
    GREEN="$old_green"
    YELLOW="$old_yellow"
    BLUE="$old_blue"
    PURPLE="$old_purple"
    NC="$old_nc"
    LOG_STDOUT="$old_log_stdout"

    sudo cp "$tmp_report" "$report_file" || {
        rm -f "$tmp_report"
        log "${RED}No se pudo escribir el reporte en $report_file.${NC}"
        return 1
    }
    rm -f "$tmp_report"

    log "${GREEN}Reporte operativo creado: $report_file${NC}"
    echo -e "${GREEN}Reporte creado:${NC} $report_file"
    return "$doctor_status"
}

show_status() {
    local installed="no"
    local version
    local active
    local enabled
    local configured_interface
    local config_status="no validada"
    local rules_time

    if is_suricata_installed; then
        installed="si"
    fi

    version="$(get_suricata_version)"
    active="$(get_service_state is-active)"
    enabled="$(get_service_state is-enabled)"
    configured_interface="$(get_configured_interface)"
    rules_time="$(get_rules_update_time)"

    if check_suricata_config_quiet; then
        if [ "$DRY_RUN" = true ]; then
            config_status="simulada en dry-run"
        else
            config_status="valida"
        fi
    else
        config_status="invalida o no disponible"
    fi

    echo -e "${BLUE}Estado rapido de SURICATAMAN${NC}"
    echo "Suricata instalado: $installed"
    echo "Version: $version"
    echo "Servicio activo: $active"
    echo "Servicio al arranque: $enabled"
    echo "Configuracion: $config_status"
    echo "Interfaz configurada: ${configured_interface:-No detectada}"
    echo "Ultima actualizacion de reglas: $rules_time"
    echo "Log SURICATAMAN: $LOG_FILE"
}

generate_json_report() {
    local timestamp
    local report_file
    local installed=false
    local version
    local active
    local enabled
    local configured_interface
    local config_valid=false
    local rules_time

    timestamp="$(date '+%Y%m%d_%H%M%S')"
    report_file="$REPORT_DIR/suricataman-report-$timestamp.json"

    if is_suricata_installed; then
        installed=true
    fi

    version="$(get_suricata_version)"
    active="$(get_service_state is-active)"
    enabled="$(get_service_state is-enabled)"
    configured_interface="$(get_configured_interface)"
    rules_time="$(get_rules_update_time)"

    if check_suricata_config_quiet; then
        config_valid=true
    fi

    if [ "$DRY_RUN" = true ]; then
        log "${YELLOW}[DRY-RUN] Crear reporte JSON en $report_file${NC}"
        return 0
    fi

    sudo mkdir -p "$REPORT_DIR" || { log "${RED}No se pudo crear $REPORT_DIR.${NC}"; return 1; }
    {
        printf '{\n'
        printf '  "project": "SURICATAMAN",\n'
        printf '  "version": "%s",\n' "$(json_escape "$PROJECT_VERSION")"
        printf '  "generated_at": "%s",\n' "$(date '+%Y-%m-%d %H:%M:%S')"
        printf '  "system": {\n'
        printf '    "name": "%s",\n' "$(json_escape "${OS_NAME:-Desconocido}")"
        printf '    "version": "%s",\n' "$(json_escape "${OS_VERSION:-Desconocida}")"
        printf '    "id": "%s"\n' "$(json_escape "${ID:-sin-id}")"
        printf '  },\n'
        printf '  "suricata": {\n'
        printf '    "installed": %s,\n' "$installed"
        printf '    "version": "%s",\n' "$(json_escape "$version")"
        printf '    "service_active": "%s",\n' "$(json_escape "$active")"
        printf '    "service_enabled": "%s",\n' "$(json_escape "$enabled")"
        printf '    "config_file": "%s",\n' "$(json_escape "$SURICATA_CONFIG")"
        printf '    "config_valid": %s,\n' "$config_valid"
        printf '    "configured_interface": "%s",\n' "$(json_escape "${configured_interface:-}")"
        printf '    "rules_last_update": "%s"\n' "$(json_escape "$rules_time")"
        printf '  },\n'
        printf '  "paths": {\n'
        printf '    "suricataman_log": "%s",\n' "$(json_escape "$LOG_FILE")"
        printf '    "logrotate": "%s",\n' "$(json_escape "$LOGROTATE_FILE")"
        printf '    "suricata_logs": "/var/log/suricata",\n'
        printf '    "suricata_data": "/var/lib/suricata",\n'
        printf '    "report": "%s"\n' "$(json_escape "$report_file")"
        printf '  }\n'
        printf '}\n'
    } | sudo tee "$report_file" >/dev/null

    log "${GREEN}Reporte JSON creado: $report_file${NC}"
    echo -e "${GREEN}Reporte JSON creado:${NC} $report_file"
}

show_events() {
    echo -e "${BLUE}Ultimos eventos de Suricata${NC}"
    echo ""

    if [ -f "$SURICATA_FAST_LOG" ]; then
        echo -e "${YELLOW}$SURICATA_FAST_LOG${NC}"
        tail -n "$EVENT_LINES" "$SURICATA_FAST_LOG" || true
    else
        echo -e "${YELLOW}No existe $SURICATA_FAST_LOG.${NC}"
    fi

    echo ""
    if [ -f "$SURICATA_EVE_LOG" ]; then
        echo -e "${YELLOW}$SURICATA_EVE_LOG${NC}"
        if command -v jq >/dev/null 2>&1; then
            tail -n "$EVENT_LINES" "$SURICATA_EVE_LOG" | jq -r '
                "[\(.timestamp // "sin-fecha")] \(.event_type // "evento") src=\(.src_ip // "-") dst=\(.dest_ip // "-") sig=\(.alert.signature // "-")"
            ' 2>/dev/null || tail -n "$EVENT_LINES" "$SURICATA_EVE_LOG"
        else
            tail -n "$EVENT_LINES" "$SURICATA_EVE_LOG"
        fi
    else
        echo -e "${YELLOW}No existe $SURICATA_EVE_LOG.${NC}"
    fi
}

run_upgrade_all() {
    log "${YELLOW}Ejecutando actualizacion completa de Suricata...${NC}"
    update_suricata || return 1
    update_rules || return 1
    restart_suricata || return 1
    run_doctor
}

run_install_flow() {
    install_bc || return 1
    show_progress 2 "Verificando dependencias..."
    install_dependencies || return 1
    configure_logrotate || return 1

    if install_suricata; then
        configure_suricata || return 1
        update_rules || return 1
        restart_suricata || return 1
        log "${GREEN}Suricata instalado y configurado exitosamente.${NC}"
    else
        log "${YELLOW}Instalación cancelada. No se ejecutan pasos posteriores.${NC}"
        return 1
    fi
}

show_help() {
    cat <<EOF
SURICATAMAN $PROJECT_VERSION - Gestión de Suricata

Uso:
  sudo ./suricataman.sh [opciones]

Opciones:
  --help             Muestra esta ayuda.
  --version          Muestra la versión actual.
  --install          Instala, configura, actualiza reglas y reinicia Suricata.
  --uninstall        Desinstala Suricata.
  --update           Actualiza Suricata.
  --configure        Ejecuta configuración básica y reinicia si es válida.
  --update-rules     Actualiza reglas de Suricata.
  --restart          Valida configuración y reinicia Suricata.
  --advanced-config  Abre configuración avanzada.
  --show-paths       Muestra rutas y archivos importantes.
  --status           Muestra un resumen rapido del estado.
  --doctor           Ejecuta diagnostico operativo de Suricata y SURICATAMAN.
  --report           Genera un reporte operativo en /var/log/suricataman/reports.
  --report-json      Genera un reporte JSON para automatizacion.
  --events           Muestra ultimos eventos de fast.log y eve.json.
  --upgrade-all      Actualiza Suricata, reglas, reinicia y ejecuta diagnostico.
  --dry-run          Muestra lo que se haría sin ejecutar cambios reales.

Ejemplos:
  sudo ./suricataman.sh --install
  sudo ./suricataman.sh --update-rules
  sudo ./suricataman.sh --status
  sudo ./suricataman.sh --doctor
  sudo ./suricataman.sh --report
  sudo ./suricataman.sh --report-json
  sudo ./suricataman.sh --events
  sudo ./suricataman.sh --upgrade-all
  sudo ./suricataman.sh --dry-run --install
EOF
}

show_version() {
    echo "SURICATAMAN $PROJECT_VERSION"
}

parse_arguments() {
    local arg

    for arg in "$@"; do
        case "$arg" in
            --dry-run)
                DRY_RUN=true
                ;;
            --help)
                ACTION="help"
                ;;
            --version)
                ACTION="version"
                ;;
            --install)
                ACTION="install"
                ;;
            --uninstall)
                ACTION="uninstall"
                ;;
            --update)
                ACTION="update"
                ;;
            --configure)
                ACTION="configure"
                ;;
            --update-rules)
                ACTION="update-rules"
                ;;
            --restart)
                ACTION="restart"
                ;;
            --advanced-config)
                ACTION="advanced-config"
                ;;
            --show-paths)
                ACTION="show-paths"
                ;;
            --status)
                ACTION="status"
                ;;
            --doctor)
                ACTION="doctor"
                ;;
            --report)
                ACTION="report"
                ;;
            --report-json)
                ACTION="report-json"
                ;;
            --events)
                ACTION="events"
                ;;
            --upgrade-all)
                ACTION="upgrade-all"
                ;;
            *)
                echo -e "${RED}Opción no reconocida: $arg${NC}"
                show_help
                exit 1
                ;;
        esac
    done
}

show_menu() {
    local option

    while true; do
        safe_clear
        echo -e "${BLUE}*************************************************${NC}"
        echo -e "${BLUE}********* Script creado por JHON DAVID **********${NC}"
        echo -e "${BLUE}*********    Gestión de Suricata       **********${NC}"
        echo -e "${BLUE}*************************************************${NC}"
        echo ""
        echo -e "${YELLOW}Por favor, elige una opción:${NC}"
        echo "1) Instalar y configurar Suricata"
        echo "2) Desinstalar Suricata"
        echo "3) Actualizar Suricata"
        echo "4) Configuración básica de Suricata"
        echo "5) Actualizar reglas de Suricata"
        echo "6) Reiniciar Suricata"
        echo "7) Configuración avanzada de Suricata"
        echo "8) Ver rutas y archivos importantes"
        echo "9) Estado rapido"
        echo "10) Diagnostico operativo"
        echo "11) Generar reporte operativo"
        echo "12) Generar reporte JSON"
        echo "13) Ver eventos de Suricata"
        echo "14) Actualizacion completa"
        echo "15) Salir"
        read -r -p "Opción [1-15]: " option

        case "$option" in
            1)
                run_install_flow || true
                ;;
            2)
                uninstall_suricata || true
                ;;
            3)
                update_suricata || true
                ;;
            4)
                if configure_suricata && restart_suricata; then
                    log "${GREEN}Suricata ha sido reconfigurado exitosamente.${NC}"
                else
                    log "${RED}No se completó la configuración básica de Suricata.${NC}"
                fi
                ;;
            5)
                update_rules || true
                ;;
            6)
                restart_suricata || true
                ;;
            7)
                advanced_config_menu
                ;;
            8)
                manage_paths
                ;;
            9)
                show_status || true
                ;;
            10)
                run_doctor || true
                ;;
            11)
                generate_report || true
                ;;
            12)
                generate_json_report || true
                ;;
            13)
                show_events || true
                ;;
            14)
                run_upgrade_all || true
                ;;
            15)
                log "${YELLOW}Saliendo del script.${NC}"
                echo -e "${GREEN}El fichero de logs de Suricataman se encuentra en:${NC}"
                echo "$LOG_FILE"
                exit 0
                ;;
            *)
                log "${RED}Opción inválida. Por favor, intenta de nuevo.${NC}"
                ;;
        esac
        read -r -p "Presiona Enter para continuar..."
    done
}

main() {
    parse_arguments "$@"
    if [ "$ACTION" = "help" ]; then
        show_help
        exit 0
    fi

    if [ "$ACTION" = "version" ]; then
        show_version
        exit 0
    fi

    check_root
    detect_os || exit 1

    case "$ACTION" in
        menu)
            show_menu
            ;;
        install)
            run_install_flow
            ;;
        uninstall)
            uninstall_suricata
            ;;
        update)
            update_suricata
            ;;
        configure)
            configure_suricata && restart_suricata
            ;;
        update-rules)
            update_rules
            ;;
        restart)
            restart_suricata
            ;;
        advanced-config)
            advanced_config_menu
            ;;
        show-paths)
            manage_paths
            ;;
        status)
            show_status
            ;;
        doctor)
            run_doctor
            ;;
        report)
            generate_report
            ;;
        report-json)
            generate_json_report
            ;;
        events)
            show_events
            ;;
        upgrade-all)
            run_upgrade_all
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

main "$@"
