# Guia de Instalacion y Uso

## Requisitos

- Sistema Linux compatible.
- Usuario con permisos `sudo`.
- Conexion a internet.
- Bash disponible.

## Instalacion Local

1. Clona el repositorio:

```bash
git clone https://github.com/JhonDavid930/SURICATAMAN.git
cd SURICATAMAN
```

2. Da permisos de ejecucion:

```bash
chmod +x suricataman.sh src/suricataman.sh tests/static-check.sh
```

3. Ejecuta el menu interactivo:

```bash
sudo ./suricataman.sh
```

## Uso Automatizado

```bash
sudo ./suricataman.sh --install
sudo ./suricataman.sh --update
sudo ./suricataman.sh --update-rules
sudo ./suricataman.sh --restart
sudo ./suricataman.sh --show-paths
```

Para revisar acciones sin aplicar cambios reales:

```bash
sudo ./suricataman.sh --dry-run --install
```

## Verificacion para Desarrollo

Antes de publicar cambios:

```bash
bash -n suricataman.sh
bash -n src/suricataman.sh
bash tests/static-check.sh
```

## Notas Importantes

- El script modifica configuraciones del sistema.
- La opcion de desinstalacion elimina archivos relacionados con Suricata.
- Los logs de SURICATAMAN no se eliminan por defecto.
- Antes de modificar `suricata.yaml`, se crea un backup versionado.
- Antes de reiniciar Suricata, se valida la configuracion con `suricata -T`.
- Se recomienda probar primero en una maquina virtual o entorno controlado.
