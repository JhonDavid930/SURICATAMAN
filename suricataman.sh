#!/bin/bash

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # Sin color

# Variables globales
LOG_DIR="/var/log/suricataman"
LOG_FILE="$LOG_DIR/suricataman.log"

# Función para registrar logs
log() {
    # Verificar si el directorio existe, si no, crearlo
    if [ ! -d "$LOG_DIR" ]; then
        sudo mkdir -p "$LOG_DIR"
        sudo chown $SUDO_USER "$LOG_DIR"
    fi

    # Verificar si el archivo de log existe, si no, crearlo
    if [ ! -f "$LOG_FILE" ]; then
        sudo touch "$LOG_FILE"
        sudo chown $SUDO_USER "$LOG_FILE"
    fi

    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Función para mostrar barra de progreso mejorada
show_progress() {
    local duration=${1}
    local title=${2}
    echo -ne "${YELLOW}${title}${NC}\n"
    for ((i=0; i<=100; i+=5)); do
        printf "\r["
        for ((j=0; j<=i; j+=5)); do
            printf "#"
        done
        for ((j=i+5; j<=100; j+=5)); do
            printf " "
        done
        printf "] %d%%" $i
        sleep $(echo "scale=2; $duration/20" | bc)
    done
    echo -e "\n"
}

# Función para verificar si el usuario es root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}Este script debe ejecutarse como root o con sudo.${NC}"
        exit 1
    fi
}

# Función para detectar el sistema operativo
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_VERSION=$VERSION_ID
        ID_LIKE=${ID_LIKE}
        ID=${ID}
    else
        log "${RED}No se pudo detectar el sistema operativo.${NC}"
        exit 1
    fi
}

# Función para instalar 'bc' antes de mostrar la barra de progreso
install_bc() {
    log "${YELLOW}Instalando 'bc' para la barra de progreso...${NC}"
    case "$ID" in
        ubuntu|debian|kali)
            sudo apt-get update
            sudo apt-get install -y bc
            ;;
        centos|rhel)
            sudo yum install -y bc
            ;;
        fedora)
            sudo dnf install -y bc
            ;;
        arch)
            sudo pacman -Sy --noconfirm bc
            ;;
        *)
            log "${RED}Distribución no soportada para la instalación de 'bc'.${NC}"
            exit 1
            ;;
    esac
}

# Función para instalar dependencias
install_dependencies() {
    log "${YELLOW}Verificando e instalando dependencias...${NC}"
    local dependencies=("curl" "gnupg" "jq")
    case "$ID" in
        ubuntu|debian|kali)
            sudo apt-get update
            for package in "${dependencies[@]}"; do
                if ! dpkg -l | grep -qw $package; then
                    log "${YELLOW}Instalando dependencia: $package${NC}"
                    sudo apt-get install -y $package
                fi
            done
            ;;
        centos|rhel)
            sudo yum update -y
            for package in "${dependencies[@]}"; do
                if ! rpm -q $package; then
                    log "${YELLOW}Instalando dependencia: $package${NC}"
                    sudo yum install -y $package
                fi
            done
            ;;
        fedora)
            sudo dnf update -y
            for package in "${dependencies[@]}"; do
                if ! rpm -q $package; then
                    log "${YELLOW}Instalando dependencia: $package${NC}"
                    sudo dnf install -y $package
                fi
            done
            ;;
        arch)
            sudo pacman -Sy --noconfirm "${dependencies[@]}"
            ;;
        *)
            log "${RED}Distribución no soportada automáticamente por este script.${NC}"
            exit 1
            ;;
    esac
}

# Función para instalar Suricata
install_suricata() {
    log "${YELLOW}Instalando Suricata...${NC}"
    case "$ID" in
        ubuntu|debian|kali)
            sudo add-apt-repository -y ppa:oisf/suricata-stable
            sudo apt-get update
            sudo apt-get install -y suricata
            ;;
        centos|rhel)
            sudo yum install -y epel-release
            sudo yum install -y suricata
            ;;
        fedora)
            sudo dnf install -y suricata
            ;;
        arch)
            sudo pacman -Sy --noconfirm suricata
            ;;
        *)
            log "${RED}Distribución no soportada para la instalación de Suricata.${NC}"
            exit 1
            ;;
    esac

    # Validar instalación exitosa
    if command -v suricata >/dev/null 2>&1; then
        local version=$(suricata -V 2>&1 | head -n 1)
        log "${GREEN}Suricata instalado exitosamente. ${version}${NC}"

        # Mostrar rutas donde se instaló Suricata
        local paths=$(whereis suricata)
        log "${YELLOW}Rutas donde se encuentra Suricata:${NC}"
        log "${PURPLE}$paths${NC}"
    else
        log "${RED}Fallo al instalar Suricata. Por favor, verifica los logs para más detalles.${NC}"
        exit 1
    fi
}

# Función para desinstalar Suricata
uninstall_suricata() {
    log "${YELLOW}Desinstalando Suricata...${NC}"
    case "$ID" in
        ubuntu|debian|kali)
            sudo apt-get remove --purge -y suricata
            sudo add-apt-repository -r -y ppa:oisf/suricata-stable
            sudo apt-get update
            ;;
        centos|rhel)
            sudo yum remove -y suricata
            ;;
        fedora)
            sudo dnf remove -y suricata
            ;;
        arch)
            sudo pacman -Rns --noconfirm suricata
            ;;
        *)
            log "${RED}Distribución no soportada para la desinstalación de Suricata.${NC}"
            exit 1
            ;;
    esac

    # Eliminar archivos de configuración y logs
    log "${YELLOW}Eliminando archivos de configuración y logs...${NC}"
    sudo rm -rf /etc/suricata /var/lib/suricata /usr/share/suricata /var/log/suricata

    # Eliminar directorio de logs del script
    if [ -d "$LOG_DIR" ]; then
        sudo rm -rf "$LOG_DIR"
    fi

    log "${GREEN}Suricata y archivos relacionados han sido desinstalados exitosamente.${NC}"
}

# Función para actualizar Suricata
update_suricata() {
    log "${YELLOW}Actualizando Suricata...${NC}"
    case "$ID" in
        ubuntu|debian|kali)
            sudo apt-get update
            sudo apt-get upgrade -y suricata
            ;;
        centos|rhel)
            sudo yum update -y suricata
            ;;
        fedora)
            sudo dnf upgrade -y suricata
            ;;
        arch)
            sudo pacman -Sy --noconfirm suricata
            ;;
        *)
            log "${RED}Distribución no soportada para la actualización de Suricata.${NC}"
            exit 1
            ;;
    esac

    # Validar actualización exitosa
    if command -v suricata >/dev/null 2>&1; then
        local version=$(suricata -V 2>&1 | head -n 1)
        log "${GREEN}Suricata actualizado exitosamente. ${version}${NC}"

        # Mostrar rutas donde se encuentra Suricata
        local paths=$(whereis suricata)
        log "${YELLOW}Rutas donde se encuentra Suricata:${NC}"
        log "${PURPLE}$paths${NC}"
    else
        log "${RED}Fallo al actualizar Suricata. Por favor, verifica los logs para más detalles.${NC}"
        exit 1
    fi
}

# Función para configurar Suricata
configure_suricata() {
    log "${YELLOW}Configurando Suricata...${NC}"
    local interface=$(ip route | grep default | awk '{print $5}')
    if [ -z "$interface" ]; then
        log "${RED}No se pudo determinar automáticamente la interfaz de red.${NC}"
        read -p "Introduce el nombre de la interfaz de red manualmente (ej. eth0, wlan0): " interface
        if [ -z "$interface" ]; then
            log "${RED}No se ha proporcionado ninguna interfaz válida. Saliendo del script.${NC}"
            exit 1
        fi
    else
        log "${GREEN}Se ha detectado automáticamente la interfaz de red: ${interface}${NC}"
    fi

    # Modificar el archivo suricata.yaml
    sudo sed -i "/^  - interface:/c\  - interface: $interface" /etc/suricata/suricata.yaml
    log "${GREEN}Suricata ha sido configurado para usar la interfaz: ${interface}${NC}"
}

# Función para actualizar reglas de Suricata
update_rules() {
    log "${YELLOW}Descargando e instalando reglas de Suricata...${NC}"
    sudo suricata-update || { log "${RED}Fallo al actualizar las reglas de Suricata.${NC}"; exit 1; }
}

# Función para reiniciar Suricata
restart_suricata() {
    log "${YELLOW}Reiniciando Suricata para aplicar los cambios...${NC}"
    sudo systemctl restart suricata.service || { log "${RED}Fallo al reiniciar el servicio de Suricata.${NC}"; exit 1; }
}

# Función para mostrar el menú interactivo con bucle
show_menu() {
    while true; do
        clear
        echo -e "${BLUE}*************************************************${NC}"
        echo -e "${BLUE}********* Script creado por JHON DAVID **********${NC}"
        echo -e "${BLUE}*********    Gestión de Suricata       **********${NC}"
        echo -e "${BLUE}*************************************************${NC}"
        echo ""
        echo -e "${YELLOW}Por favor, elige una opción:${NC}"
        echo "1) Instalar y configurar Suricata"
        echo "2) Desinstalar Suricata"
        echo "3) Actualizar Suricata"
        echo "4) Configurar Suricata"
        echo "5) Salir"
        read -p "Opción [1-5]: " option
        case $option in
            1)
                install_bc
                show_progress 2 "Instalando dependencias..."
                install_dependencies
                install_suricata
                configure_suricata
                update_rules
                restart_suricata
                log "${GREEN}¡Suricata ha sido instalado y configurado exitosamente!${NC}"
                ;;
            2)
                uninstall_suricata
                ;;
            3)
                update_suricata
                ;;
            4)
                configure_suricata
                restart_suricata
                log "${GREEN}Suricata ha sido reconfigurado exitosamente.${NC}"
                ;;
            5)
                log "${YELLOW}Saliendo del script.${NC}"
                exit 0
                ;;
            *)
                log "${RED}Opción inválida. Por favor, intenta de nuevo.${NC}"
                ;;
        esac
        read -p "Presiona Enter para continuar..."
    done
}

# Función principal
main() {
    check_root
    detect_os
    show_menu
}

# Ejecutar función principal
main "$@"
