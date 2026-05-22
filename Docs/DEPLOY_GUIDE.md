# Guia de Instalacion y Uso

## Requisitos

- Sistema Linux compatible.
- Usuario con permisos `sudo`.
- Conexion a internet.
- Bash disponible.

Para una explicacion completa de todos los metodos soportados, revisa [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md).

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

## Instalacion Remota sin Copiar Carpetas

Si el servidor no permite pegar una carpeta completa, usa el instalador remoto:

```bash
curl -fsSL https://raw.githubusercontent.com/JhonDavid930/SURICATAMAN/main/install.sh | sudo bash
sudo suricataman
```

Con `wget`:

```bash
wget -qO- https://raw.githubusercontent.com/JhonDavid930/SURICATAMAN/main/install.sh | sudo bash
sudo suricataman
```

Instalar una version concreta:

```bash
curl -fsSL https://raw.githubusercontent.com/JhonDavid930/SURICATAMAN/main/install.sh | sudo bash -s -- --ref v2.5.0
```

Instalar en una ruta personalizada:

```bash
curl -fsSL https://raw.githubusercontent.com/JhonDavid930/SURICATAMAN/main/install.sh | sudo bash -s -- --dir /opt/suricataman --bin /usr/local/bin/suricataman
```

## Instalacion Standalone

Para servidores donde solo se puede subir o pegar un archivo:

```bash
chmod +x suricataman-standalone.sh
sudo ./suricataman-standalone.sh
```

El artefacto se encuentra en:

```text
dist/suricataman-standalone.sh
```

## Copia Minima

Si solo puedes copiar dos archivos al servidor, conserva esta estructura:

```text
SURICATAMAN/
├── suricataman.sh
└── src/
    └── suricataman.sh
```

Y ejecuta:

```bash
chmod +x suricataman.sh src/suricataman.sh
sudo ./suricataman.sh
```

## Validacion de Metodos de Instalacion

Antes de publicar `v2.2.0`, se validaron en Kali Linux:

- copia completa;
- copia minima;
- standalone;
- instalador local;
- instalador remoto con `curl`;
- instalador remoto con `wget`;
- extraccion TAR.GZ.

Todos dejaron Suricata instalado, habilitado, activo y con configuracion validada.

## Uso Automatizado

```bash
sudo ./suricataman.sh --install
sudo ./suricataman.sh --version
sudo ./suricataman.sh --update
sudo ./suricataman.sh --update-rules
sudo ./suricataman.sh --restart
sudo ./suricataman.sh --show-paths
sudo ./suricataman.sh --status
sudo ./suricataman.sh --doctor
sudo ./suricataman.sh --report
sudo ./suricataman.sh --report-json
sudo ./suricataman.sh --events
sudo ./suricataman.sh --events --alerts --limit 50
sudo ./suricataman.sh --events-json --ssh
sudo ./suricataman.sh --upgrade-all
sudo ./suricataman.sh --health-check
sudo ./suricataman.sh --support-bundle
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
- `--status` muestra una vista rapida de operacion.
- `--doctor` revisa el estado operativo sin cambiar configuracion.
- `--doctor` muestra recomendaciones cuando detecta problemas.
- `--report` guarda un informe en `/var/log/suricataman/reports`.
- `--report-json` guarda un informe estructurado para automatizacion.
- `--events` permite revisar ultimas alertas y eventos de Suricata.
- `--events-json` exporta eventos filtrados para automatizacion.
- `--upgrade-all` ejecuta actualizacion completa con diagnostico final.
- `--health-check` permite comprobaciones desde cron o monitorizacion.
- `--support-bundle` empaqueta informacion util para soporte.
- Se recomienda probar primero en una maquina virtual o entorno controlado.
