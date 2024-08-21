#!/bin/bash

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # Sin color

# Función para mostrar barra de progreso
show_progress() {
    local duration=${1}
    already_done() { for ((done=0; done<$elapsed; done++)); do printf "▓"; done }
    remaining() { for ((remain=$elapsed; remain<$duration; remain++)); do printf " "; done }
    percentage() { printf "| %s%%" $(( ($elapsed*100)/($duration*1) )); }

    for ((elapsed=1; elapsed<=$duration; elapsed++))
    do
        already_done; remaining; percentage
        sleep 0.1
        printf "\r"
    done
    printf "\n"
}

# Comprobar si el script se está ejecutando como root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Este script debe ejecutarse como root o con sudo.${NC}"
  exit 1
fi

# Detectar la distribución de Linux
OS=$(awk -F= '/^NAME/{print $2}' /etc/os-release)

echo -e "${BLUE}*************************************************${NC}"
echo -e "${BLUE}********* Script creado por JHON DAVID **********${NC}"
echo -e "${BLUE}********* para la instalación y configuración ****"
echo -e "${BLUE}********* de Suricata ****************************${NC}"
echo -e "${BLUE}*************************************************${NC}"
echo -e "${YELLOW}Inicio de la instalación y configuración...${NC}"
echo -e "${YELLOW}===========================================${NC}"
sleep 2

# Mostrar la distribución detectada
echo -e "${YELLOW}Detectando el sistema operativo...${NC}"
echo -e "${GREEN}Sistema operativo detectado: $OS${NC}"

# Verificar y instalar dependencias según la distribución
echo -e "${YELLOW}Verificando dependencias...${NC}"

if [[ "$OS" == *"Kali"* ]] || [[ "$OS" == *"Debian"* ]] || [[ "$OS" == *"Ubuntu"* ]]; then
    dependencies=("curl" "gnupg" "jq")
    for package in "${dependencies[@]}"; do
        dpkg -l | grep -qw $package || {
            echo -e "${YELLOW}Instalando dependencia: $package${NC}"
            sudo apt-get install -y $package
        }
    done
elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]] || [[ "$OS" == *"Fedora"* ]]; then
    dependencies=("curl" "gnupg" "jq")
    for package in "${dependencies[@]}"; do
        rpm -q $package || {
            echo -e "${YELLOW}Instalando dependencia: $package${NC}"
            sudo yum install -y $package
        }
    done
else
    echo -e "${RED}Distribución no soportada automáticamente por este script.${NC}"
    echo -e "${YELLOW}Por favor, instala Suricata manualmente o contacta al administrador.${NC}"
    exit 1
fi

# Mostrar barra de progreso para la instalación de dependencias
echo -e "${YELLOW}Dependencias verificadas e instaladas. Continuando...${NC}"
show_progress 20

# Intentar instalar la versión más reciente y estable de Suricata
if [[ "$OS" == *"Kali"* ]] || [[ "$OS" == *"Debian"* ]] || [[ "$OS" == *"Ubuntu"* ]]; then
    echo -e "${YELLOW}Intentando instalar Suricata desde el PPA para la versión más reciente...${NC}"
    echo "deb [trusted=yes] http://ppa.launchpad.net/oisf/suricata-stable/ubuntu focal main" | sudo tee /etc/apt/sources.list.d/suricata.list

    sudo apt-get update
    if sudo apt-get install -y suricata; then
        echo -e "${GREEN}Suricata instalado exitosamente desde el PPA.${NC}"
    else
        echo -e "${RED}Fallo al instalar Suricata desde el PPA. Intentando desde el repositorio nativo...${NC}"
        sudo rm /etc/apt/sources.list.d/suricata.list
        sudo apt-get update
        if sudo apt-get install -y suricata; then
            echo -e "${GREEN}Suricata instalado exitosamente desde el repositorio nativo.${NC}"
        else
            echo -e "${RED}Fallo al instalar Suricata desde el repositorio nativo. Saliendo del script.${NC}"
            exit 1
        fi
    fi
elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]] || [[ "$OS" == *"Fedora"* ]]; then
    echo -e "${YELLOW}Instalando Suricata desde el repositorio nativo...${NC}"
    if sudo yum install -y suricata; then
        echo -e "${GREEN}Suricata instalado exitosamente desde el repositorio nativo.${NC}"
    else
        echo -e "${RED}Fallo al instalar Suricata desde el repositorio nativo. Saliendo del script.${NC}"
        exit 1
    fi
else
    echo -e "${RED}Distribución no soportada. Saliendo del script.${NC}"
    exit 1
fi

# Configuración de Suricata
echo -e "${YELLOW}Configurando Suricata...${NC}"
interface=$(ip route | grep default | awk '{print $5}')

if [ -z "$interface" ]; then
  echo -e "${RED}No se pudo determinar automáticamente la interfaz de red.${NC}"
  echo -e "${RED}Posibles causas:${NC}"
  echo -e "${RED}1. El sistema no tiene una ruta predeterminada establecida.${NC}"
  echo -e "${RED}2. El sistema está desconectado de la red.${NC}"
  echo -e "${RED}3. La configuración de red es incorrecta.${NC}"
  echo -e "${YELLOW}Sugerencia: Por favor, verifica tu configuración de red.${NC}"
  
  # Opción para que el usuario ingrese manualmente la interfaz correcta
  read -p "Introduce el nombre de la interfaz de red manualmente (ej. eth0, wlan0): " interface
  
  if [ -z "$interface" ]; then
    echo -e "${RED}No se ha proporcionado ninguna interfaz válida. Saliendo del script.${NC}"
    exit 1
  else
    echo -e "${YELLOW}Usando la interfaz proporcionada: ${interface}${NC}"
  fi
else
  # Mensaje al encontrar una interfaz válida automáticamente
  echo -e "${GREEN}Se ha detectado automáticamente la interfaz de red: ${interface}${NC}"
fi

# Configurar la interfaz en el archivo de configuración de Suricata
sudo sed -i "/af-packet:/!b;n;c\  - interface: $interface" /etc/suricata/suricata.yaml

# Mostrar la interfaz configurada
echo -e "${PURPLE}###########################################${NC}"
echo -e "${PURPLE}## Suricata ha sido configurado para usar la interfaz: ${RED}${interface}${NC}${PURPLE} ##${NC}"
echo -e "${PURPLE}###########################################${NC}"

# Descargar e instalar reglas de Suricata
echo -e "${YELLOW}Descargando e instalando reglas de Suricata...${NC}"
sudo suricata-update || { echo -e "${RED}Fallo al actualizar las reglas de Suricata.${NC}"; exit 1; }

# Reiniciar Suricata para aplicar los cambios
echo -e "${YELLOW}Reiniciando Suricata para aplicar los cambios...${NC}"
sudo systemctl restart suricata.service || { echo -e "${RED}Fallo al reiniciar el servicio de Suricata.${NC}"; exit 1; }

# Mostrar mensaje de éxito
echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}¡Suricata ha sido instalado y configurado de forma eficiente!${NC}"
echo -e "${GREEN}===========================================${NC}"

# Mostrar las rutas donde se encuentra Suricata
echo -e "${YELLOW}Verificando las rutas de instalación de Suricata...${NC}"
whereis suricata
