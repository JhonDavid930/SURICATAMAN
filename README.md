# SURICATAMAN

SURICATAMAN es una herramienta Bash para instalar, configurar, actualizar y desinstalar Suricata de forma guiada en distribuciones Linux compatibles.

[![Video Tutorial](https://img.youtube.com/vi/mWlxgF9nbmk/maxresdefault.jpg)](https://www.youtube.com/watch?v=mWlxgF9nbmk&t=0s)

Video tutorial: [Instalacion automatica de Suricata](https://www.youtube.com/watch?v=mWlxgF9nbmk&t=0s)

## Para que sirve

Este proyecto simplifica tareas comunes de administracion de Suricata:

- Instalacion automatica de Suricata.
- Deteccion de la interfaz de red predeterminada.
- Configuracion basica de `suricata.yaml`.
- Descarga y actualizacion de reglas.
- Reinicio del servicio para aplicar cambios.
- Actualizacion y desinstalacion desde menu interactivo.

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

## Uso Rapido

```bash
chmod +x suricataman.sh src/suricataman.sh
sudo ./suricataman.sh
```

## Validacion para Desarrollo

```bash
bash tests/static-check.sh
```

## Documentacion

- [Analisis del proyecto](Docs/ANALISIS_PROYECTO.md)
- [Especificacion tecnica](Docs/TECH_SPECS.md)
- [Guia de instalacion y uso](Docs/DEPLOY_GUIDE.md)
- [Changelog](Docs/CHANGELOG.md)
- [Roadmap tecnico](Docs/TODO.md)

## Aviso

Este script ejecuta operaciones reales sobre el sistema: instala paquetes, edita configuracion y reinicia servicios. Se recomienda probar primero en una maquina virtual o entorno controlado.
