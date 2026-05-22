# Guia de Publicacion de Releases

Esta guia define un flujo profesional para publicar nuevas versiones de SURICATAMAN en GitHub.

## Antes de Publicar

1. Confirmar que `VERSION` y `PROJECT_VERSION` tienen la misma version.
2. Regenerar el standalone:

```bash
bash scripts/build-standalone.sh
```

3. Ejecutar validaciones:

```bash
bash tests/static-check.sh
git diff --check
```

4. Probar en Linux:

```bash
sudo ./suricataman.sh --status
sudo ./suricataman.sh --doctor
sudo ./suricataman.sh --report
sudo ./suricataman.sh --report-json
```

## Checklist de Release

- `README.md` actualizado.
- `Docs/CHANGELOG.md` actualizado.
- `Docs/TECH_SPECS.md` actualizado.
- `Docs/INSTALLATION_GUIDE.md` actualizado.
- `dist/suricataman-standalone.sh` regenerado.
- Tests locales completados.
- Prueba en VM o entorno Linux controlado completada.

## Plantilla de Notas

```text
## SURICATAMAN vX.Y.Z

### Novedades

- ...

### Instalacion Rapida

curl -fsSL https://raw.githubusercontent.com/JhonDavid930/SURICATAMAN/main/install.sh | sudo bash -s -- --ref vX.Y.Z
sudo suricataman --status

### Verificacion

sudo suricataman --doctor
sudo suricataman --report

### Advertencia

SURICATAMAN ejecuta operaciones reales con privilegios elevados. Se recomienda probar primero en una maquina virtual o entorno controlado.
```

## Publicacion

No crear commit, push ni tag hasta que el propietario del repositorio lo confirme expresamente.

Cuando se autorice:

```bash
git add .
git commit -m "feat: describe la mejora"
git push origin main
git checkout Developer
git merge --ff-only main
git push origin Developer
git tag -a vX.Y.Z -m "SURICATAMAN vX.Y.Z"
git push origin vX.Y.Z
```
