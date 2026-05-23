# SURICATAMAN Console v0.1

Primera interfaz grafica local para operar SURICATAMAN y Suricata desde navegador.

## Alcance

- Uso local en `127.0.0.1`.
- Backend FastAPI.
- Frontend React + Vite.
- Sin multi-host en esta version.
- Sin ejecucion libre de comandos: solo acciones predefinidas.

## Backend

Instalar dependencias:

```bash
cd console/backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Ejecutar API local:

```bash
sudo .venv/bin/uvicorn suricataman_console.app:app --host 127.0.0.1 --port 8000
```

Endpoints principales:

- `GET /api/status`
- `GET /api/doctor`
- `GET /api/events`
- `GET /api/rules`
- `POST /api/rules/{sid}/enable`
- `POST /api/rules/{sid}/disable`
- `POST /api/update-rules`
- `POST /api/restart`
- `POST /api/support-bundle`
- `POST /api/health-check`

## Frontend

Instalar dependencias:

```bash
cd console/frontend
npm install
```

Ejecutar interfaz:

```bash
npm run dev
```

Abrir:

```text
http://127.0.0.1:5173
```

Para servir la version compilada:

```bash
npm run build
npm run preview -- --port 4173
```

Abrir `http://127.0.0.1:4173`.

Si la API usa otro puerto:

```bash
VITE_API_BASE=http://127.0.0.1:8000 npm run dev
```

## Prueba con una VM Linux por SSH

La consola v0.1 no se expone a red remota. Para usar una VM Kali/Ubuntu desde el equipo anfitrion, levanta el backend dentro de la VM y crea un tunel SSH:

```bash
ssh -N -L 8000:127.0.0.1:8000 usuario@IP_DE_LA_VM
```

Despues abre el frontend local en el anfitrion. El navegador consumira `http://127.0.0.1:8000/api/...`, pero las acciones se ejecutaran dentro de la VM.

Validacion recomendada:

```bash
curl http://127.0.0.1:8000/api/status
curl http://127.0.0.1:8000/api/doctor
curl "http://127.0.0.1:8000/api/events?limit=1"
curl "http://127.0.0.1:8000/api/rules?limit=1"
```

Para probar la gestion de reglas de forma reversible, selecciona un SID, deshabilitalo y vuelvelo a habilitar. Deben crearse backups en `/etc/suricata/disable.conf.bak.*`, validarse Suricata y quedar `suricata.service` activo.

## Seguridad

- La consola solo debe escucharse en localhost.
- Las acciones destructivas requieren confirmacion visual.
- La modificacion de reglas usa backups y validacion antes de reiniciar.
- El backend debe ejecutarse con privilegios suficientes para leer reglas, validar configuracion y reiniciar Suricata.
- Para produccion remota, crear una version futura con autenticacion y agentes.
