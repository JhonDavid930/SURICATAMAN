# Especificacion Tecnica

## Tipo de Proyecto

Herramienta CLI interactiva y no interactiva escrita en Bash para administracion local de Suricata.

## Arquitectura

```text
SURICATAMAN
├── suricataman.sh              # Wrapper compatible
├── src/
│   └── suricataman.sh          # Logica principal
├── tests/
│   └── static-check.sh         # Validaciones estaticas
├── .github/workflows/
│   └── static-check.yml        # CI con ShellCheck
├── Docs/
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
- `parse_arguments`: habilita modo no interactivo.
- `show_menu`: experiencia interactiva principal.

## Modo No Interactivo

Opciones disponibles:

- `--help`
- `--install`
- `--uninstall`
- `--update`
- `--configure`
- `--update-rules`
- `--restart`
- `--advanced-config`
- `--show-paths`
- `--dry-run`

`--install` ejecuta dependencias, logrotate, instalacion, configuracion, reglas y reinicio. Si `install_suricata` retorna error o cancelacion, no se ejecutan pasos posteriores.

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
