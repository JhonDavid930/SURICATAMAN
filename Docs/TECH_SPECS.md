# Especificacion Tecnica

## Tipo de Proyecto

Herramienta CLI interactiva escrita en Bash para administracion local de Suricata.

## Arquitectura

```text
SURICATAMAN
├── suricataman.sh              # Entrada compatible
├── src/
│   └── suricataman.sh          # Logica principal
├── tests/
│   └── static-check.sh         # Validaciones estaticas
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

## Componentes del Script

- `log`: crea directorio y archivo de log, y escribe eventos.
- `show_progress`: muestra una barra de progreso temporal.
- `check_root`: exige ejecucion como root.
- `detect_os`: carga datos de `/etc/os-release`.
- `install_bc`: instala `bc` segun distribucion.
- `install_dependencies`: instala dependencias base (`curl`, `gnupg`, `jq`).
- `install_suricata`: instala Suricata.
- `uninstall_suricata`: elimina Suricata y archivos relacionados.
- `update_suricata`: actualiza el paquete Suricata.
- `configure_suricata`: detecta interfaz por defecto y actualiza `suricata.yaml`.
- `update_rules`: ejecuta `suricata-update`.
- `restart_suricata`: reinicia `suricata.service`.
- `show_menu`: controla la experiencia interactiva.
- `main`: punto de entrada del script principal.

## Dependencias

### Requeridas por el sistema

- Bash.
- `sudo`.
- Gestor de paquetes de la distribucion.
- `systemctl`.
- `ip`.
- `sed`, `awk`, `grep`.

### Instaladas por el script

- `bc`.
- `curl`.
- `gnupg`.
- `jq`.
- `suricata`.

## Seguridad Operativa

Este proyecto debe ejecutarse con privilegios elevados. Por eso, cualquier cambio futuro debe tratar estas zonas como criticas:

- Eliminacion de rutas en `uninstall_suricata`.
- Edicion de `/etc/suricata/suricata.yaml`.
- Uso de repositorios externos para instalacion.
- Reinicio de servicios.

## Politica de Compatibilidad

El archivo de raiz `suricataman.sh` debe seguir existiendo para no romper instrucciones publicas o tutoriales existentes. La logica principal puede evolucionar dentro de `src/`.
