import json
from typing import Literal

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from .command import CommandError, run_suricataman
from .parsers import normalize_event, parse_doctor, parse_status
from .rules import list_rules, set_rule_enabled


app = FastAPI(title="SURICATAMAN Console API", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://127.0.0.1:5173", "http://localhost:5173"],
    allow_origin_regex=r"^http://(127\.0\.0\.1|localhost):\d+$",
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


class ActionResult(BaseModel):
    ok: bool
    stdout: str = ""
    stderr: str = ""
    detail: str = ""


def api_command(args: list[str], require_root: bool = True) -> str:
    try:
        return run_suricataman(args, require_root=require_root).stdout
    except CommandError as exc:
        raise HTTPException(
            status_code=500,
            detail={"command": exc.command, "stdout": exc.stdout, "stderr": exc.stderr, "returncode": exc.returncode},
        ) from exc


def action_command(args: list[str], detail: str) -> ActionResult:
    try:
        result = run_suricataman(args)
        return ActionResult(ok=True, stdout=result.stdout, stderr=result.stderr)
    except CommandError as exc:
        return ActionResult(ok=False, stdout=exc.stdout, stderr=exc.stderr, detail=detail)


@app.get("/api/status")
def status() -> dict[str, object]:
    return parse_status(api_command(["--status"]))


@app.get("/api/doctor")
def doctor() -> dict[str, object]:
    try:
        output = run_suricataman(["--doctor"]).stdout
    except CommandError as exc:
        output = exc.stdout
    return parse_doctor(output)


@app.get("/api/events")
def events(
    type: Literal["", "alert", "ssh", "dns"] = "",
    src: str = "",
    dst: str = "",
    limit: int = Query(50, ge=1, le=500),
) -> dict[str, object]:
    args = ["--events-json", "--limit", str(limit)]
    if type:
        args.append({"alert": "--alerts", "ssh": "--ssh", "dns": "--dns"}[type])
    if src:
        args.extend(["--src", src])
    if dst:
        args.extend(["--dst", dst])
    output = api_command(args)
    try:
        data = json.loads(output or "[]")
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=500, detail=f"No se pudo parsear events-json: {exc}") from exc
    return {"events": [normalize_event(event) for event in data]}


@app.get("/api/rules")
def rules(
    query: str = "",
    sid: int | None = None,
    severity: int | None = Query(None, ge=1),
    category: str = "",
    limit: int = Query(250, ge=1, le=1000),
) -> dict[str, object]:
    return {"rules": list_rules(query=query, sid=sid, severity=severity, category=category, limit=limit)}


@app.post("/api/rules/{sid}/enable")
def enable_rule(sid: int) -> dict[str, object]:
    try:
        return set_rule_enabled(sid, enabled=True)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/api/rules/{sid}/disable")
def disable_rule(sid: int) -> dict[str, object]:
    try:
        return set_rule_enabled(sid, enabled=False)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/api/update-rules")
def update_rules() -> ActionResult:
    return action_command(["--update-rules"], "No se pudieron actualizar las reglas.")


@app.post("/api/restart")
def restart() -> ActionResult:
    return action_command(["--restart"], "No se pudo validar o reiniciar Suricata.")


@app.post("/api/support-bundle")
def support_bundle() -> ActionResult:
    return action_command(["--support-bundle"], "No se pudo generar el bundle de soporte.")


@app.post("/api/health-check")
def health_check() -> ActionResult:
    try:
        result = run_suricataman(["--health-check"])
        return ActionResult(ok=True, stdout=result.stdout, stderr=result.stderr)
    except CommandError as exc:
        return ActionResult(ok=False, stdout=exc.stdout, stderr=exc.stderr, detail="Health-check detecto problemas.")
