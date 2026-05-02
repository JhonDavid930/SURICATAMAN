# Changelog

Todas las modificaciones relevantes del proyecto se documentan aqui.

## v2.1.0 - Hardening, automatizacion y UX

- Agregado control de reinstalacion cuando Suricata ya existe.
- Evitada la reinstalacion innecesaria de `bc`, `curl`, `gnupg` y `jq`.
- Agregada cache de paquetes por ejecucion con `update_package_cache`.
- Agregados backups versionados de `/etc/suricata/suricata.yaml`.
- Agregada validacion real de interfaz de red antes de modificar YAML.
- Agregada validacion con `suricata -T` antes de reiniciar.
- Habilitado `suricata.service` al arranque tras instalacion correcta.
- Agregada configuracion de logrotate para `/var/log/suricataman/suricataman.log`.
- Endurecida la funcion `log` para ejecucion con `sudo` o root directo.
- Evitado el borrado automatico de logs propios durante desinstalacion.
- Agregado submenu de rutas y archivos importantes.
- Agregada configuracion avanzada para `af-packet`.
- Agregado modo no interactivo con flags CLI.
- Agregado modo `--dry-run`.
- Mejorado el menu interactivo con nueve opciones.
- Actualizados tests estaticos y agregado workflow de GitHub Actions.

## v2.0.1 - Estructura profesional

- Reorganizada la estructura profesional del repositorio.
- Movida la logica principal a `src/suricataman.sh`.
- Conservado `suricataman.sh` en la raiz como lanzador compatible.
- Movida la imagen del proyecto a `Recursos/IMG/`.
- Agregada documentacion tecnica en `Docs/`.
- Agregada validacion estatica basica en `tests/static-check.sh`.
- Agregado `.gitignore` y guia `AGENTS.md`.

## v2.0.0

- Version previa del proyecto con menu interactivo para instalar, configurar, actualizar y desinstalar Suricata.
