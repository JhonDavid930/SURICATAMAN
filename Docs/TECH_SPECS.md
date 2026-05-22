# Especificacion Tecnica

## Tipo de Proyecto

Herramienta CLI interactiva y no interactiva escrita en Bash para administracion local de Suricata.

Version actual del proyecto: `2.3.0`.

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
├── .github/workflows/
│   └── static-check.yml        # CI con ShellCheck
├── Docs/
│   ├── INSTALLATION_GUIDE.md
│   ├── DEPLOY_GUIDE.md
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
- `run_doctor`: ejecuta diagnostico operativo de Suricata y SURICATAMAN.
- `generate_report`: crea reporte versionado en `/var/log/suricataman/reports`.
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
- `--doctor`
- `--report`
- `--dry-run`

`--install` ejecuta dependencias, logrotate, instalacion, configuracion, reglas y reinicio. Si `install_suricata` retorna error o cancelacion, no se ejecutan pasos posteriores.

## Diagnostico Operativo

`--doctor` valida el estado real de la instalacion sin modificar configuracion:

- presencia del binario `suricata`;
- version instalada;
- estado `active` de `suricata.service`;
- habilitacion al arranque;
- existencia de `/etc/suricata/suricata.yaml`;
- interfaz configurada y existencia en el sistema;
- validacion con `suricata -T`;
- existencia de rutas de reglas, logs y logrotate.

El diagnostico retorna error si detecta fallos criticos. Las advertencias se muestran en pantalla y quedan registradas en el log.

## Reporte Operativo

`--report` crea un informe de diagnostico con timestamp en:

```text
/var/log/suricataman/reports/suricataman-report-YYYYMMDD_HHMMSS.txt
```

El reporte incluye version, fecha, resultado de `--doctor` y rutas clave para auditoria o soporte.

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
