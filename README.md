# SURICATAMAN

Version actual: `2.3.0`

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
- Diagnostico operativo con `--doctor`.
- Reporte operativo versionado con `--report`.
- Modo no interactivo y modo `--dry-run`.

## Estructura del Proyecto

```text
SURICATAMAN
├── suricataman.sh
├── src/
│   └── suricataman.sh
├── tests/
│   └── static-check.sh
├── install.sh
├── scripts/
│   └── build-standalone.sh
├── dist/
│   └── suricataman-standalone.sh
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

## Formas de Instalacion

SURICATAMAN se puede instalar o ejecutar de varias formas para que copiar una carpeta completa no sea una limitacion.

Guia completa: [Docs/INSTALLATION_GUIDE.md](Docs/INSTALLATION_GUIDE.md)

### 1. Clonar el repositorio

```bash
git clone https://github.com/JhonDavid930/SURICATAMAN.git
cd SURICATAMAN
chmod +x suricataman.sh src/suricataman.sh
sudo ./suricataman.sh
```

### 2. Instalador remoto con curl

Instala la herramienta completa en `/opt/suricataman` y crea el comando global `suricataman`:

```bash
curl -fsSL https://raw.githubusercontent.com/JhonDavid930/SURICATAMAN/main/install.sh | sudo bash
sudo suricataman
```

Para instalar una version concreta:

```bash
curl -fsSL https://raw.githubusercontent.com/JhonDavid930/SURICATAMAN/main/install.sh | sudo bash -s -- --ref v2.3.0
```

### 3. Instalador remoto con wget

```bash
wget -qO- https://raw.githubusercontent.com/JhonDavid930/SURICATAMAN/main/install.sh | sudo bash
sudo suricataman
```

### 4. Copia minima

Si solo puedes copiar pocos archivos, bastan:

```text
suricataman.sh
src/suricataman.sh
```

### 5. Un solo archivo standalone

Si el servidor solo permite descargar o pegar un archivo, usa:

```text
dist/suricataman-standalone.sh
```

Ejecutalo con:

```bash
chmod +x suricataman-standalone.sh
sudo ./suricataman-standalone.sh
```

### 6. Descargar ZIP o TAR.GZ desde GitHub

Tambien puedes descargar el release desde GitHub, descomprimirlo y ejecutar `sudo ./suricataman.sh`.

Todos estos metodos fueron probados en Kali Linux antes de publicar la version `2.2.0`.

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
9) Diagnostico operativo
10) Generar reporte operativo
11) Salir
```

## Uso No Interactivo

```bash
sudo ./suricataman.sh --help
sudo ./suricataman.sh --version
sudo ./suricataman.sh --install
sudo ./suricataman.sh --uninstall
sudo ./suricataman.sh --update
sudo ./suricataman.sh --configure
sudo ./suricataman.sh --update-rules
sudo ./suricataman.sh --restart
sudo ./suricataman.sh --advanced-config
sudo ./suricataman.sh --show-paths
sudo ./suricataman.sh --doctor
sudo ./suricataman.sh --report
```

Ejemplos:

```bash
sudo ./suricataman.sh --install
sudo ./suricataman.sh --update-rules
sudo ./suricataman.sh --doctor
sudo ./suricataman.sh --report
sudo ./suricataman.sh --dry-run --install
```

## Diagnostico y Reportes

`--doctor` revisa el estado operativo de Suricata y SURICATAMAN:

- binario y version de Suricata;
- estado y habilitacion de `suricata.service`;
- existencia de `suricata.yaml`;
- interfaz configurada;
- validacion con `suricata -T`;
- rutas de reglas, logs y logrotate.

`--report` genera un informe en:

```text
/var/log/suricataman/reports/
```

Ejemplo:

```bash
sudo ./suricataman.sh --report
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

## Versionado

- Version actual: `2.3.0`.
- Fuente de version del repositorio: `VERSION`.
- Historial de cambios: [Docs/CHANGELOG.md](Docs/CHANGELOG.md).

## Documentacion

- [Analisis del proyecto](Docs/ANALISIS_PROYECTO.md)
- [Especificacion tecnica](Docs/TECH_SPECS.md)
- [Guia completa de instalacion](Docs/INSTALLATION_GUIDE.md)
- [Guia de instalacion y uso](Docs/DEPLOY_GUIDE.md)
- [Changelog](Docs/CHANGELOG.md)
- [Roadmap tecnico](Docs/TODO.md)

## Advertencia de Seguridad

Este script ejecuta operaciones reales con privilegios elevados: instala paquetes, edita configuracion, crea backups, administra servicios y puede eliminar archivos de Suricata durante la desinstalacion. Se recomienda probar primero en una maquina virtual o entorno controlado.
