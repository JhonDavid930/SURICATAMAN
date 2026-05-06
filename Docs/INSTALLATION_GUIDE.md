# Guia de Instalacion de SURICATAMAN

Esta guia explica todas las formas soportadas de instalar o ejecutar SURICATAMAN. La idea es que el servidor destino no dependa de poder pegar una carpeta completa.

## Que Metodo Elegir

| Escenario | Metodo recomendado |
| --- | --- |
| Tienes Git disponible y quieres auditar todo el proyecto | `git clone` |
| Quieres instalar rapido desde internet | `curl` o `wget` con `install.sh` |
| Quieres fijar una version concreta | `install.sh --ref v2.2.0` |
| No puedes copiar carpetas, pero si un archivo | `dist/suricataman-standalone.sh` |
| Puedes copiar solo lo minimo | `suricataman.sh` + `src/suricataman.sh` |
| No tienes Git, pero puedes descargar archivos | ZIP/TAR.GZ de GitHub |
| Quieres instalar en una ruta propia | `install.sh --dir` y `--bin` |

## Metodo 1: Git Clone

Recomendado para desarrollo, auditoria, contribuciones y servidores donde Git esta disponible.

```bash
git clone https://github.com/JhonDavid930/SURICATAMAN.git
cd SURICATAMAN
chmod +x suricataman.sh src/suricataman.sh
sudo ./suricataman.sh
```

Para ejecutar instalacion directa no interactiva:

```bash
sudo ./suricataman.sh --install
```

## Metodo 2: Instalador Remoto con curl

Recomendado para servidores donde no quieres copiar carpetas manualmente.

```bash
curl -fsSL https://raw.githubusercontent.com/JhonDavid930/SURICATAMAN/main/install.sh | sudo bash
sudo suricataman
```

Instalar una version especifica:

```bash
curl -fsSL https://raw.githubusercontent.com/JhonDavid930/SURICATAMAN/main/install.sh | sudo bash -s -- --ref v2.2.0
```

Instalar y ejecutar automaticamente:

```bash
curl -fsSL https://raw.githubusercontent.com/JhonDavid930/SURICATAMAN/main/install.sh | sudo bash -s -- --run
```

## Metodo 3: Instalador Remoto con wget

Alternativa a `curl`.

```bash
wget -qO- https://raw.githubusercontent.com/JhonDavid930/SURICATAMAN/main/install.sh | sudo bash
sudo suricataman
```

Con version especifica:

```bash
wget -qO- https://raw.githubusercontent.com/JhonDavid930/SURICATAMAN/main/install.sh | sudo bash -s -- --ref v2.2.0
```

## Metodo 4: Instalador Local

Si ya tienes el repositorio o solo el archivo `install.sh`:

```bash
bash install.sh --help
sudo bash install.sh
sudo suricataman
```

Instalacion en ruta personalizada:

```bash
sudo bash install.sh --dir /opt/suricataman --bin /usr/local/bin/suricataman
```

Instalacion sin comando global:

```bash
sudo bash install.sh --no-symlink
sudo /opt/suricataman/suricataman.sh
```

Variables soportadas:

```bash
SURICATAMAN_REF=v2.2.0
SURICATAMAN_INSTALL_DIR=/opt/suricataman
SURICATAMAN_BIN_PATH=/usr/local/bin/suricataman
```

## Metodo 5: Copia Minima

Si solo puedes copiar pocos archivos, copia exactamente:

```text
suricataman.sh
src/suricataman.sh
```

La estructura minima debe quedar asi:

```text
SURICATAMAN/
├── suricataman.sh
└── src/
    └── suricataman.sh
```

Ejecucion:

```bash
chmod +x suricataman.sh src/suricataman.sh
sudo ./suricataman.sh
```

## Metodo 6: Standalone de un Solo Archivo

Recomendado cuando el servidor solo permite mover, pegar o descargar un archivo.

Archivo:

```text
dist/suricataman-standalone.sh
```

Ejecucion:

```bash
chmod +x suricataman-standalone.sh
sudo ./suricataman-standalone.sh
```

Instalacion no interactiva:

```bash
sudo ./suricataman-standalone.sh --install
```

## Metodo 7: ZIP o TAR.GZ

Desde GitHub puedes descargar el codigo fuente como ZIP o TAR.GZ, descomprimirlo y ejecutar:

```bash
chmod +x suricataman.sh src/suricataman.sh
sudo ./suricataman.sh
```

## Comandos Despues de Instalar

Ver version:

```bash
suricataman --version
```

Instalar Suricata:

```bash
sudo suricataman --install
```

Actualizar reglas:

```bash
sudo suricataman --update-rules
```

Ver rutas importantes:

```bash
sudo suricataman --show-paths
```

Simular sin cambios reales:

```bash
sudo suricataman --dry-run --install
```

## Validacion Realizada

Antes de publicar la version `2.2.0`, se probaron en Kali Linux los siguientes metodos:

- copia completa del proyecto;
- copia minima `suricataman.sh` + `src/suricataman.sh`;
- standalone de un solo archivo;
- `install.sh` local;
- instalador remoto via `curl`;
- instalador remoto via `wget`;
- extraccion TAR.GZ.

En todos los casos Suricata quedo instalado, habilitado y activo con configuracion validada.

## Advertencia

SURICATAMAN ejecuta operaciones reales con privilegios elevados: instala paquetes, modifica `/etc/suricata/suricata.yaml`, actualiza reglas y administra `suricata.service`. Pruebalo primero en una maquina virtual o entorno controlado.
