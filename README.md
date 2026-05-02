# SURICATAMAN

SURICATAMAN es una herramienta Bash para instalar, configurar, actualizar, endurecer y administrar Suricata de forma guiada o automatizada en distribuciones Linux compatibles.

[![Video Tutorial](https://img.youtube.com/vi/mWlxgF9nbmk/maxresdefault.jpg)](https://www.youtube.com/watch?v=mWlxgF9nbmk&t=0s)

Video tutorial: [Instalacion automatica de Suricata](https://www.youtube.com/watch?v=mWlxgF9nbmk&t=0s)

## Funciones Principales

- Instalacion y configuracion interactiva de Suricata.
- Control de reinstalacion si Suricata ya existe.
- Instalacion de dependencias evitando reinstalar paquetes ya presentes.
- Cache de paquetes actualizada una sola vez por ejecucion.
- Backups versionados de `/etc/suricata/suricata.yaml`.
- Validacion de interfaz de red antes de modificar configuracion.
- Validacion con `suricata -T` antes de reiniciar el servicio.
- Habilitacion de `suricata.service` al arranque.
- Configuracion de logrotate para los logs de SURICATAMAN.
- Menu de rutas importantes y configuracion avanzada.
- Modo no interactivo y modo `--dry-run`.

## Estructura del Proyecto

```text
SURICATAMAN
├── suricataman.sh
├── src/
│   └── suricataman.sh
├── tests/
│   └── static-check.sh
├── Docs/
│   ├── ANALISIS_PROYECTO.md
│   ├── TECH_SPECS.md
│   ├── DEPLOY_GUIDE.md
│   ├── CHANGELOG.md
│   └── TODO.md
└── Recursos/
    └── IMG/
        └── Instala_SuricataDeformaRapida.jpeg
```

## Uso Interactivo

```bash
chmod +x suricataman.sh src/suricataman.sh
sudo ./suricataman.sh
```

Menu disponible:

```text
1) Instalar y configurar Suricata
2) Desinstalar Suricata
3) Actualizar Suricata
4) Configuracion basica de Suricata
5) Actualizar reglas de Suricata
6) Reiniciar Suricata
7) Configuracion avanzada de Suricata
8) Ver rutas y archivos importantes
9) Salir
```

## Uso No Interactivo

```bash
sudo ./suricataman.sh --help
sudo ./suricataman.sh --install
sudo ./suricataman.sh --uninstall
sudo ./suricataman.sh --update
sudo ./suricataman.sh --configure
sudo ./suricataman.sh --update-rules
sudo ./suricataman.sh --restart
sudo ./suricataman.sh --advanced-config
sudo ./suricataman.sh --show-paths
```

Ejemplos:

```bash
sudo ./suricataman.sh --install
sudo ./suricataman.sh --update-rules
sudo ./suricataman.sh --dry-run --install
```

## Rutas Importantes

- `/var/log/suricataman/suricataman.log`: logs de SURICATAMAN.
- `/etc/logrotate.d/suricataman`: rotacion de logs.
- `/etc/suricata/suricata.yaml`: configuracion principal de Suricata.
- `/etc/suricata/suricata.yaml.bak.*`: backups versionados.
- `/var/log/suricata`: logs nativos de Suricata.
- `/var/lib/suricata`: reglas y datos internos.
- `/usr/share/suricata`: archivos compartidos y recursos.

## Validacion para Desarrollo

```bash
bash tests/static-check.sh
```

El workflow de GitHub Actions ejecuta la misma validacion en cada `push` y `pull_request`.

## Documentacion

- [Analisis del proyecto](Docs/ANALISIS_PROYECTO.md)
- [Especificacion tecnica](Docs/TECH_SPECS.md)
- [Guia de instalacion y uso](Docs/DEPLOY_GUIDE.md)
- [Changelog](Docs/CHANGELOG.md)
- [Roadmap tecnico](Docs/TODO.md)

## Advertencia de Seguridad

Este script ejecuta operaciones reales con privilegios elevados: instala paquetes, edita configuracion, crea backups, administra servicios y puede eliminar archivos de Suricata durante la desinstalacion. Se recomienda probar primero en una maquina virtual o entorno controlado.
