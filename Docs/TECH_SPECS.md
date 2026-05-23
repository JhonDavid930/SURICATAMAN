# Especificacion Tecnica

## Tipo de Proyecto

Herramienta CLI interactiva y no interactiva escrita en Bash para administracion local de Suricata.

Version actual del proyecto: `2.6.0`.

## Arquitectura

```text
SURICATAMAN
├── suricataman.sh              # Wrapper compatible
├── src/
│   └── suricataman.sh          # Logica principal
├── tests/
│   └── static-check.sh         # Validaciones estaticas
├── install.sh                  # Instalador remoto/local
├── scripts/
│   └── build-standalone.sh     # Generador de distribucion standalone
├── dist/
│   └── suricataman-standalone.sh
├── console/
│   ├── backend/                # API local FastAPI
│   └── frontend/               # UI React + Vite
├── .github/workflows/
│   └── static-check.yml        # CI con ShellCheck
├── Docs/
│   ├── INSTALLATION_GUIDE.md
│   ├── DEPLOY_GUIDE.md
│   ├── RELEASE_GUIDE.md
│   ├── TECH_SPECS.md
│   ├── CHANGELOG.md
│   └── TODO.md
└── Recursos/
```

## Componentes del Script

- `log`: crea y escribe logs de forma robusta aunque `SUDO_USER` este vacio.
- `run_cmd`: ejecuta comandos reales o los muestra en modo `--dry-run`.
- `check_root`: exige privilegios salvo para `--help`.
- `detect_os`: carga datos de `/etc/os-release`.
- `is_suricata_installed`: detecta si existe el binario `suricata`.
- `is_package_installed`: valida paquetes por gestor (`dpkg`, `rpm`, `pacman`).
- `update_package_cache`: actualiza cache una sola vez por ejecucion.
- `install_bc`: evita reinstalar `bc`.
- `install_dependencies`: instala `curl`, `gnupg` y `jq` solo si faltan.
- `configure_logrotate`: crea `/etc/logrotate.d/suricataman`.
- `install_suricata`: controla reinstalacion y habilita el servicio al arranque.
- `uninstall_suricata`: desinstala Suricata sin borrar logs propios por defecto.
- `backup_suricata_config`: crea backups con timestamp antes de modificar YAML.
- `configure_suricata`: detecta y valida interfaz antes de editar `suricata.yaml`.
- `validate_suricata_config`: ejecuta `suricata -T -c /etc/suricata/suricata.yaml`.
- `restart_suricata`: valida antes de reiniciar `suricata.service`.
- `update_rules`: ejecuta `suricata-update`.
- `advanced_config_menu`: permite habilitar o deshabilitar `af-packet`.
- `manage_paths`: muestra rutas, permisos, contenido y estado de archivos clave.
- `show_status`: muestra resumen rapido de instalacion, servicio, configuracion, interfaz y reglas.
- `run_doctor`: ejecuta diagnostico operativo de Suricata y SURICATAMAN.
- `generate_report`: crea reporte versionado en `/var/log/suricataman/reports`.
- `generate_json_report`: crea reporte JSON para automatizacion.
- `show_events`: muestra ultimos eventos desde `fast.log` y `eve.json`.
- `show_events_json`: exporta eventos filtrados desde `eve.json` como JSON.
- `run_upgrade_all`: actualiza Suricata, reglas, reinicia y ejecuta diagnostico.
- `run_health_check`: ejecuta comprobacion silenciosa para cron o monitorizacion.
- `create_support_bundle`: empaqueta estado, diagnostico, eventos, logs y resumen de configuracion.
- `parse_arguments`: habilita modo no interactivo.
- `show_version`: imprime la version actual del proyecto.
- `show_menu`: experiencia interactiva principal.

## Distribucion e Instalacion

El repositorio mantiene la estructura profesional principal, pero ofrece varias vias de instalacion:

- `git clone`: recomendado para desarrollo y auditoria completa.
- `install.sh`: instala la herramienta completa desde GitHub.
- `curl | bash` o `wget -qO- | bash`: instalacion remota cuando no se puede copiar carpeta.
- ZIP/TAR.GZ de GitHub Releases: instalacion manual sin Git.
- copia minima: `suricataman.sh` + `src/suricataman.sh`.
- standalone: `dist/suricataman-standalone.sh` para servidores donde solo se puede mover un archivo.

La guia operativa completa vive en `Docs/INSTALLATION_GUIDE.md`.

## SURICATAMAN Console

`console/` agrega una capa grafica local sin reemplazar el CLI Bash.

- Backend FastAPI en `127.0.0.1:8000`.
- Frontend React + Vite en `127.0.0.1:5173`.
- CORS limitado a origenes locales `localhost` y `127.0.0.1` para permitir puertos de desarrollo o preview sin abrir acceso remoto.
- Endpoints predefinidos para estado, doctor, eventos, reglas, health-check, actualizacion, reinicio y bundle.
- La gestion de reglas usa `/etc/suricata/disable.conf`, crea backup, ejecuta `suricata-update`, valida con `suricata -T` y reinicia solo si la validacion pasa.
- La v0.1 no expone acceso remoto, usuarios ni multi-host.

`install.sh` instala por defecto en:

```text
/opt/suricataman
```

Y crea el comando global:

```text
/usr/local/bin/suricataman
```

Variables soportadas:

- `SURICATAMAN_REF`
- `SURICATAMAN_INSTALL_DIR`
- `SURICATAMAN_BIN_PATH`
- `SURICATAMAN_REPO_URL`
- `SURICATAMAN_ARCHIVE_URL_BASE`

## Matriz de QA de Instalacion

Antes de publicar `v2.2.0`, la instalacion se valido en Kali Linux con:

- copia completa del proyecto;
- copia minima;
- standalone;
- `install.sh` local;
- instalador remoto via `curl`;
- instalador remoto via `wget`;
- TAR.GZ extraido.

Cada metodo ejecuto instalacion real de Suricata, actualizacion de reglas, validacion con `suricata -T`, habilitacion del servicio y verificacion de `suricata.service` como `active`.

La consola v0.1 se valido en Kali Linux mediante backend FastAPI local, tunel SSH hacia el anfitrion y frontend React en preview local. Se comprobaron:

- `GET /api/status` con Suricata instalado, activo, habilitado e interfaz `eth0`.
- `GET /api/doctor` con 0 fallos y 0 advertencias.
- `GET /api/events` leyendo eventos reales desde `eve.json`.
- `GET /api/rules` leyendo reglas reales desde `/var/lib/suricata/rules/suricata.rules`.
- `POST /api/health-check`, `POST /api/support-bundle` y `POST /api/restart`.
- ciclo reversible `POST /api/rules/{sid}/disable` y `POST /api/rules/{sid}/enable` con backup, validacion y servicio activo al finalizar.

## Modo No Interactivo

Opciones disponibles:

- `--help`
- `--version`
- `--install`
- `--uninstall`
- `--update`
- `--configure`
- `--update-rules`
- `--restart`
- `--advanced-config`
- `--show-paths`
- `--status`
- `--doctor`
- `--report`
- `--report-json`
- `--events`
- `--events-json`
- `--alerts`
- `--ssh`
- `--dns`
- `--limit`
- `--src`
- `--dst`
- `--upgrade-all`
- `--health-check`
- `--support-bundle`
- `--dry-run`

`--install` ejecuta dependencias, logrotate, instalacion, configuracion, reglas y reinicio. Si `install_suricata` retorna error o cancelacion, no se ejecutan pasos posteriores.

## Estado y Diagnostico Operativo

`--status` muestra una vista rapida para operacion diaria:

- Suricata instalado;
- version;
- estado del servicio;
- habilitacion al arranque;
- validez de configuracion;
- interfaz configurada;
- ultima actualizacion de reglas;
- ruta del log de SURICATAMAN.

`--doctor` valida el estado real de la instalacion sin modificar configuracion:

- presencia del binario `suricata`;
- version instalada;
- estado `active` de `suricata.service`;
- habilitacion al arranque;
- existencia de `/etc/suricata/suricata.yaml`;
- interfaz configurada y existencia en el sistema;
- validacion con `suricata -T`;
- existencia de rutas de reglas, logs y logrotate.

El diagnostico retorna error si detecta fallos criticos. Las advertencias se muestran en pantalla, quedan registradas en el log y ahora incluyen recomendaciones accionables.

## Reporte Operativo

`--report` crea un informe de diagnostico con timestamp en:

```text
/var/log/suricataman/reports/suricataman-report-YYYYMMDD_HHMMSS.txt
```

El reporte incluye version, fecha, resultado de `--doctor` y rutas clave para auditoria o soporte.

`--report-json` crea un informe estructurado en:

```text
/var/log/suricataman/reports/suricataman-report-YYYYMMDD_HHMMSS.json
```

El JSON contiene informacion de sistema, version del proyecto, estado de Suricata, servicio, configuracion, interfaz, reglas y rutas clave.

## Eventos

`--events` revisa:

```text
/var/log/suricata/fast.log
/var/log/suricata/eve.json
```

Si `jq` esta disponible, `eve.json` se resume con fecha, tipo de evento, IP origen, IP destino y firma. Si no esta disponible, se muestran las ultimas lineas crudas.

Filtros soportados:

- `--alerts`: eventos `alert`.
- `--ssh`: eventos `ssh`.
- `--dns`: eventos `dns`.
- `--limit N`: numero de lineas/eventos revisados.
- `--src IP`: filtro por IP origen.
- `--dst IP`: filtro por IP destino.

`--events-json` exporta eventos filtrados como JSON usando `jq`.

## Health-check y Bundle de Soporte

`--health-check` ejecuta `--doctor` de forma silenciosa y retorna:

- `0` si no hay fallos criticos;
- `1` si hay problemas.

`--support-bundle` crea un `.tar.gz` en `/var/log/suricataman/reports/` con:

- `status.txt`;
- `doctor.txt`;
- `events.txt`;
- salida de reporte JSON;
- log de SURICATAMAN;
- ultimas lineas de `journalctl -u suricata.service`;
- resumen inicial de `suricata.yaml`.

## Actualizacion Completa

`--upgrade-all` ejecuta:

1. actualizacion del paquete Suricata;
2. actualizacion de reglas;
3. validacion de configuracion;
4. reinicio controlado del servicio;
5. diagnostico final.

Si una etapa critica falla, el flujo se detiene y registra el error.

## Dry Run

`--dry-run` activa `DRY_RUN=true`. Los comandos criticos pasan por `run_cmd`, por lo que se registran como acciones simuladas sin modificar el sistema.

Comandos cubiertos:

- Instalacion y actualizacion de paquetes.
- Copias de backup.
- Eliminacion de rutas.
- Modificacion de YAML.
- `systemctl restart`.
- `systemctl enable`.
- `suricata-update`.

## Backups y Validacion

Antes de modificar `/etc/suricata/suricata.yaml`, el script crea:

```text
/etc/suricata/suricata.yaml.bak.YYYYMMDD_HHMMSS
```

Antes de reiniciar Suricata se ejecuta:

```bash
sudo suricata -T -c /etc/suricata/suricata.yaml
```

Si la validacion falla, el servicio no se reinicia.

## Logrotate

SURICATAMAN crea `/etc/logrotate.d/suricataman` para rotar:

```text
/var/log/suricataman/suricataman.log
```

Politica: semanal, cuatro rotaciones, compresion, `missingok`, `notifempty`.

## Seguridad Operativa

Zonas criticas:

- Desinstalacion y borrado de rutas de Suricata.
- Edicion de `/etc/suricata/suricata.yaml`.
- Cambios de servicio con `systemctl`.
- Actualizacion de reglas.

Los logs propios de SURICATAMAN no se eliminan automaticamente al desinstalar. El usuario debe confirmarlo.

## Compatibilidad

Mantener siempre:

- `suricataman.sh` en raiz como wrapper.
- `src/suricataman.sh` como logica principal.
- `tests/static-check.sh` como verificacion minima.
- `Docs/` como fuente de documentacion.
- `VERSION` como fuente simple de versionado del repositorio.
- `dist/suricataman-standalone.sh` como artefacto de un solo archivo.
