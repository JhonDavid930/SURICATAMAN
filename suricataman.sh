#!/bin/bash

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # Sin color

# Comprobar si el script se está ejecutando como root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Este script debe ejecutarse como root o con sudo.${NC}"
  exit 1
fi

# Mensaje personalizado
echo -e "${BLUE}*************************************************${NC}"
echo -e "${BLUE}********* Script creado por JHON DAVID **********${NC}"
echo -e "${BLUE}********* para la instalación y configuración ****"
echo -e "${BLUE}********* de Suricata ****************************${NC}"
echo -e "${BLUE}*************************************************${NC}"
echo -e "${YELLOW}Inicio de la instalación y configuración...${NC}"
echo -e "${YELLOW}===========================================${NC}"
sleep 3

# Instalación de Suricata
echo -e "${YELLOW}Instalando Suricata...${NC}"
sudo apt-get update || { echo -e "${RED}Fallo al actualizar el repositorio.${NC}"; exit 1; }
sudo apt-get install -y software-properties-common || { echo -e "${RED}Fallo al instalar dependencias.${NC}"; exit 1; }
sudo add-apt-repository -y ppa:oisf/suricata-stable || { echo -e "${RED}Fallo al añadir el repositorio de Suricata.${NC}"; exit 1; }
sudo apt-get update || { echo -e "${RED}Fallo al actualizar el repositorio tras añadir PPA.${NC}"; exit 1; }
sudo apt-get install -y suricata jq || { echo -e "${RED}Fallo al instalar Suricata y jq.${NC}"; exit 1; }

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
