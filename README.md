# Suricata-instalacion
Instalación Automática de Suricata.
Este script en Bash ha sido diseñado para instalar y configurar de forma rápida y eficaz Suricata, una poderosa herramienta de monitorización y detección de intrusiones en redes.

Características:
Instalación de Suricata:
Automáticamente añade el repositorio de Suricata estable y realiza la instalación en el sistema.

Configuración Automática:
Detecta la interfaz de red predeterminada y la configura en el archivo suricata.yaml de forma automática.

Descarga y Actualización de Reglas: 
Descarga y actualiza las reglas de Suricata para asegurar la detección de las últimas amenazas.

Reinicio del Servicio:
Reinicia Suricata para aplicar todas las configuraciones y actualizaciones realizadas.
Este script simplifica el proceso de instalación y configuración, permitiéndote tener Suricata en funcionamiento en cuestión de minutos, sin necesidad de intervención manual. Ideal para entornos de pruebas y despliegues rápidos en producción.

Instrucciones de Uso:
Asegúrate de otorgar permisos de ejecución al script antes de ejecutarlo. Puedes hacerlo con el siguiente comando:

bash
Copiar código
chmod +x instalar_suricata.sh
Ejecuta el script en la misma rama o directorio donde se descargó el archivo:

bash
Copiar código
./instalar_suricata.sh
Con estos simples pasos, tendrás Suricata instalado y configurado de manera automática en tu sistema.
