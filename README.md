# **Suricata-instalación**

**Instalación Automática de Suricata**

Este script en Bash ha sido diseñado para **instalar y configurar** de forma rápida y eficaz **Suricata**, una poderosa herramienta de monitorización y detección de intrusiones en redes.

---

## **Características**:

### **1. Instalación de Suricata:**
- Automáticamente añade el repositorio de Suricata estable y realiza la instalación en el sistema.

### **2. Configuración Automática:**
- Detecta la interfaz de red predeterminada y la configura en el archivo `suricata.yaml` de forma automática.

### **3. Descarga y Actualización de Reglas:**
- Descarga y actualiza las reglas de Suricata para asegurar la detección de las últimas amenazas.

### **4. Reinicio del Servicio:**
- Reinicia Suricata para aplicar todas las configuraciones y actualizaciones realizadas.

---

Este script simplifica el proceso de instalación y configuración, permitiéndote tener **Suricata** en funcionamiento en cuestión de minutos, sin necesidad de intervención manual. Ideal para entornos de pruebas y despliegues rápidos en producción.

---

## **Instrucciones de Uso**:

1. **Asegúrate de otorgar permisos de ejecución al script antes de ejecutarlo.**  
   Puedes hacerlo con el siguiente comando:

   ```bash
   chmod +x instalar_suricata.sh
