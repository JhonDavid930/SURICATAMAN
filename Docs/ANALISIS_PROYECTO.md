# Analisis del Proyecto SURICATAMAN

## Resumen Ejecutivo

SURICATAMAN es una herramienta Bash orientada a automatizar tareas basicas de administracion de Suricata: instalacion, configuracion de interfaz de red, actualizacion de reglas, reinicio del servicio, actualizacion del paquete y desinstalacion.

El proyecto original era funcional, pero estaba concentrado en tres archivos de raiz: `README.md`, `suricataman.sh` y una imagen. La reorganizacion actual separa codigo, documentacion y recursos, manteniendo compatibilidad con el comando historico `./suricataman.sh`.

## Inventario Actual

- `suricataman.sh`: lanzador compatible desde la raiz.
- `src/suricataman.sh`: script principal de gestion de Suricata.
- `Docs/`: documentacion tecnica, despliegue, changelog y roadmap.
- `Recursos/IMG/`: recursos visuales del proyecto.
- `tests/static-check.sh`: validacion estatica basica para Bash.
- `AGENTS.md`: reglas de trabajo para agentes o colaboradores.
- `.gitignore`: exclusiones basicas para desarrollo.

## Flujo Principal

1. Verifica que el usuario sea root.
2. Detecta la distribucion desde `/etc/os-release`.
3. Muestra un menu interactivo.
4. Ejecuta tareas segun opcion:
   - Instalar y configurar Suricata.
   - Desinstalar Suricata.
   - Actualizar Suricata.
   - Reconfigurar interfaz.
   - Salir.

## Sistemas Soportados

El script declara soporte para:

- Ubuntu, Debian y Kali mediante `apt`.
- CentOS y RHEL mediante `yum`.
- Fedora mediante `dnf`.
- Arch mediante `pacman`.

## Riesgos Tecnicos Detectados

- El script realiza cambios reales en el sistema: instala paquetes, modifica `/etc/suricata/suricata.yaml`, reinicia servicios y elimina directorios durante desinstalacion.
- No existe modo `--dry-run`, por lo que no se puede ensayar sin efectos.
- La configuracion de interfaz usa una sustitucion `sed` amplia sobre `suricata.yaml`; puede fallar si el formato del archivo cambia.
- La instalacion de `bc` se hace siempre antes de la barra de progreso en el flujo completo, aunque podria validarse primero si ya existe.
- No hay pruebas automatizadas funcionales por distribucion; actualmente solo se agrego validacion estatica.

## Fortalezas

- Objetivo claro y facil de explicar.
- Menu interactivo simple.
- Soporte multi-distribucion.
- Logging centralizado en `/var/log/suricataman`.
- Separacion de funciones entendible para mantenimiento.

## Recomendaciones

- Agregar argumentos no interactivos como `install`, `uninstall`, `update`, `configure` y `--help`.
- Implementar modo `--dry-run`.
- Validar dependencias antes de ejecutar comandos privilegiados.
- Crear backups de configuracion antes de editar `suricata.yaml`.
- Anadir pruebas con contenedores Linux para validar rutas por distribucion.
- Versionar releases con una politica clara en `Docs/CHANGELOG.md`.
