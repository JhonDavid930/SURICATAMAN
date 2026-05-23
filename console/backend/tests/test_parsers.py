from pathlib import Path

from suricataman_console.parsers import parse_doctor, parse_status
from suricataman_console.rules import list_rules, parse_rule_line


def test_parse_status() -> None:
    parsed = parse_status(
        """
Estado rapido de SURICATAMAN
Suricata instalado: si
Version: This is Suricata version 8.0.5 RELEASE
Servicio activo: active
Servicio al arranque: enabled
Configuracion: valida
Interfaz configurada: ens33
Ultima actualizacion de reglas: 2026-05-22 16:39:22
Log SURICATAMAN: /var/log/suricataman/suricataman.log
"""
    )
    assert parsed["installed"] is True
    assert parsed["service_active"] == "active"
    assert parsed["interface"] == "ens33"


def test_parse_doctor() -> None:
    parsed = parse_doctor(
        """
[OK] Binario de Suricata encontrado - This is Suricata version 8.0.5 RELEASE
[WARN] Servicio no habilitado al arranque - disabled
Resumen: 0 fallo(s), 1 advertencia(s).
"""
    )
    assert parsed["failures"] == 0
    assert parsed["warnings"] == 1
    assert len(parsed["checks"]) == 2


def test_parse_rule_line() -> None:
    rule = parse_rule_line(
        'alert http any any -> any any (msg:"ET TEST Rule"; classtype:trojan-activity; sid:2027397; rev:1; priority:3;)'
    )
    assert rule is not None
    assert rule.sid == 2027397
    assert rule.priority == 3
    assert rule.enabled is True


def test_list_rules_filters(tmp_path: Path) -> None:
    rules_file = tmp_path / "suricata.rules"
    rules_file.write_text(
        "\n".join(
            [
                'alert http any any -> any any (msg:"ET TEST One"; classtype:trojan-activity; sid:1; rev:1; priority:1;)',
                'alert dns any any -> any any (msg:"ET TEST Two"; classtype:not-suspicious; sid:2; rev:1; priority:3;)',
            ]
        ),
        encoding="utf-8",
    )
    results = list_rules(query="dns", rules_file=rules_file)
    assert len(results) == 1
    assert results[0]["sid"] == 2
