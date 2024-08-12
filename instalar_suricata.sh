#!/bin/bash

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # Sin color

# Mensaje personalizado
echo -e "${BLUE}*************************************************${NC}"
echo -e "${BLUE}********* Script creado por JHON DAVID **********${NC}"
echo -e "${BLUE}********* para la instalación y configuración ****"
echo -e "${BLUE}********* de Suricata ****************************${NC}"
echo -e "${BLUE}*************************************************${NC}"
echo -e "${YELLOW}Inicio de la instalación y configuración...${NC}"
sleep 3

# Instalación de Suricata
echo -e "${YELLOW}Instalando Suricata...${NC}"
sudo apt-get update
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:oisf/suricata-stable
sudo apt-get update
sudo apt-get install -y suricata jq

# Configuración de Suricata
echo -e "${YELLOW}Configurando Suricata...${NC}"
interface=$(ip route | grep default | awk '{print $5}')
sudo sed -i "/af-packet:/!b;n;c\  - interface: $interface" /etc/suricata/suricata.yaml

# Mostrar la interfaz configurada
echo -e "${PURPLE}###########################################${NC}"
echo -e "${PURPLE}## Suricata ha sido configurado para usar la interfaz: ${RED}${interface}${NC}${PURPLE} ##${NC}"
echo -e "${PURPLE}###########################################${NC}"

# Descargar e instalar reglas de Suricata
echo -e "${YELLOW}Descargando e instalando reglas de Suricata...${NC}"
sudo suricata-update

# Reiniciar Suricata para aplicar los cambios
echo -e "${YELLOW}Reiniciando Suricata para aplicar los cambios...${NC}"
sudo systemctl restart suricata.service

# Mostrar mensaje de éxito
echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}¡Suricata ha sido instalado y configurado de forma eficiente!${NC}"
echo -e "${GREEN}===========================================${NC}"
