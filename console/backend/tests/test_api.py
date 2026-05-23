import json

from fastapi.testclient import TestClient

from suricataman_console import app as app_module
from suricataman_console.command import CommandError, CommandResult


client = TestClient(app_module.app)


def test_status_endpoint_uses_normalized_json(monkeypatch) -> None:
    monkeypatch.setattr(
        app_module,
        "api_command",
        lambda args, require_root=True: """
Estado rapido de SURICATAMAN
Suricata instalado: si
Version: This is Suricata version 8.0.5 RELEASE
Servicio activo: active
Servicio al arranque: enabled
Configuracion: valida
Interfaz configurada: ens33
Ultima actualizacion de reglas: 2026-05-22 16:39:22
Log SURICATAMAN: /var/log/suricataman/suricataman.log
""",
    )

    response = client.get("/api/status")

    assert response.status_code == 200
    assert response.json()["installed"] is True
    assert response.json()["interface"] == "ens33"


def test_events_endpoint_normalizes_event_rows(monkeypatch) -> None:
    monkeypatch.setattr(
        app_module,
        "api_command",
        lambda args, require_root=True: json.dumps(
            [
                {
                    "timestamp": "2026-05-22T10:00:00Z",
                    "event_type": "alert",
                    "src_ip": "10.0.0.10",
                    "dest_ip": "10.0.0.20",
                    "alert": {"signature": "Test alert", "severity": 2},
                }
            ]
        ),
    )

    response = client.get("/api/events?type=alert&limit=5")

    assert response.status_code == 200
    event = response.json()["events"][0]
    assert event["signature"] == "Test alert"
    assert event["severity"] == 2


def test_rules_endpoint_passes_filters(monkeypatch) -> None:
    captured = {}

    def fake_list_rules(**kwargs):
        captured.update(kwargs)
        return [{"sid": 1001, "message": "DNS test", "enabled": True}]

    monkeypatch.setattr(app_module, "list_rules", fake_list_rules)

    response = client.get("/api/rules?query=dns&severity=3&category=policy")

    assert response.status_code == 200
    assert response.json()["rules"][0]["sid"] == 1001
    assert captured["query"] == "dns"
    assert captured["severity"] == 3
    assert captured["category"] == "policy"


def test_restart_endpoint_returns_json_when_validation_fails(monkeypatch) -> None:
    def fake_run_suricataman(args):
        raise CommandError(args, 1, "Configuracion invalida", "")

    monkeypatch.setattr(app_module, "run_suricataman", fake_run_suricataman)

    response = client.post("/api/restart")

    assert response.status_code == 200
    assert response.json()["ok"] is False
    assert "reiniciar" in response.json()["detail"]


def test_health_check_endpoint_returns_ok(monkeypatch) -> None:
    monkeypatch.setattr(
        app_module,
        "run_suricataman",
        lambda args: CommandResult(args, "Health-check OK", "", 0),
    )

    response = client.post("/api/health-check")

    assert response.status_code == 200
    assert response.json()["ok"] is True
