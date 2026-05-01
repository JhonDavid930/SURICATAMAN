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

3. Ejecuta el script:

```bash
sudo ./suricataman.sh
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
- Se recomienda probar primero en una maquina virtual o entorno controlado.
