# Roadmap Tecnico

## Completado

- Agregar modo `--help`.
- Agregar comandos no interactivos: `--install`, `--uninstall`, `--update`, `--configure`, `--update-rules`, `--restart`, `--advanced-config`, `--show-paths`.
- Crear backups antes de modificar `/etc/suricata/suricata.yaml`.
- Agregar modo `--dry-run`.
- Evitar reinstalar dependencias que ya existen.
- Mejorar deteccion y validacion de interfaz de red.
- Validar configuracion con `suricata -T` antes de reiniciar.
- Configurar logrotate para logs de SURICATAMAN.
- Agregar workflow de GitHub Actions para validacion estatica.
- Agregar instalador remoto `install.sh`.
- Agregar version standalone de un solo archivo.
- Documentar instalacion con Git, curl, wget, ZIP/TAR.GZ, copia minima y standalone.
- Validar todos los metodos de instalacion en Kali Linux antes de publicar.

## Pendiente

- Agregar pruebas en contenedores para Ubuntu, Debian, Fedora, Arch y derivados RHEL.
- Crear futuras integraciones graficas.
- Separar mensajes de UI de la logica de instalacion.
- Publicar capturas nuevas en `Recursos/IMG/`.
- Crear ejemplos de ejecucion ampliados en `Docs/`.
- Agregar plantillas para issues y pull requests.
