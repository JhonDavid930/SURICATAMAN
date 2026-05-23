import re
from typing import Any


ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")


def strip_ansi(value: str) -> str:
    return ANSI_RE.sub("", value)


def parse_key_value_lines(output: str) -> dict[str, str]:
    parsed: dict[str, str] = {}
    for line in strip_ansi(output).splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        parsed[key.strip().lower()] = value.strip()
    return parsed


def parse_status(output: str) -> dict[str, Any]:
    data = parse_key_value_lines(output)
    return {
        "installed": data.get("suricata instalado") == "si",
        "version": data.get("version", "No disponible"),
        "service_active": data.get("servicio activo", "desconocido"),
        "service_enabled": data.get("servicio al arranque", "desconocido"),
        "config_status": data.get("configuracion", "desconocida"),
        "interface": data.get("interfaz configurada", "No detectada"),
        "rules_last_update": data.get("ultima actualizacion de reglas", "No disponible"),
        "log_file": data.get("log suricataman", ""),
        "raw": strip_ansi(output),
    }


def parse_doctor(output: str) -> dict[str, Any]:
    clean = strip_ansi(output)
    checks = []
    failures = 0
    warnings = 0
    for line in clean.splitlines():
        if line.startswith("[OK]") or line.startswith("[WARN]") or line.startswith("[FAIL]") or line.startswith("[INFO]"):
            status, _, text = line.partition("]")
            checks.append({"status": status.replace("[", ""), "message": text.strip()})
        match = re.search(r"Resumen:\s+(\d+)\s+fallo\(s\),\s+(\d+)\s+advertencia\(s\)", line)
        if match:
            failures = int(match.group(1))
            warnings = int(match.group(2))
    return {"failures": failures, "warnings": warnings, "checks": checks, "raw": clean}


def normalize_event(event: dict[str, Any]) -> dict[str, Any]:
    alert = event.get("alert") or {}
    return {
        "timestamp": event.get("timestamp", ""),
        "event_type": event.get("event_type", ""),
        "src_ip": event.get("src_ip", ""),
        "src_port": event.get("src_port"),
        "dest_ip": event.get("dest_ip", ""),
        "dest_port": event.get("dest_port"),
        "proto": event.get("proto", ""),
        "signature": alert.get("signature", ""),
        "severity": alert.get("severity"),
        "category": alert.get("category", ""),
        "sid": alert.get("signature_id"),
        "raw": event,
    }
