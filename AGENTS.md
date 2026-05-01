# Guia de Trabajo para Agentes

Este repositorio contiene una herramienta Bash para instalar, configurar, actualizar y desinstalar Suricata en distribuciones Linux compatibles.

## Convenciones

- Responder y documentar en espanol.
- Mantener variables, funciones y nombres tecnicos en ingles cuando se escriba codigo nuevo.
- No ejecutar comandos destructivos contra el sistema anfitrion durante pruebas locales.
- Mantener `suricataman.sh` en la raiz como entrada compatible para usuarios existentes.
- Colocar la logica principal en `src/suricataman.sh`.
- Documentar cambios relevantes en `Docs/CHANGELOG.md`.

## Verificacion Minima

Antes de entregar cambios sobre el script:

```bash
bash -n src/suricataman.sh
bash tests/static-check.sh
```

Si `shellcheck` esta disponible, `tests/static-check.sh` tambien lo ejecuta.
