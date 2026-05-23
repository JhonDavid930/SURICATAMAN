import re
import shutil
import subprocess
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

from .config import SURICATA_CONFIG, SURICATA_DISABLE_FILE, SURICATA_RULES_FILE


RULE_RE = re.compile(
    r"^(?P<disabled>#\s*)?(?P<action>alert|drop|reject|pass)\s+"
    r"(?P<proto>\S+)\s+.*?\(msg:\"(?P<msg>[^\"]*)\";(?P<body>.*)\)\s*$"
)
SID_RE = re.compile(r"\bsid:(?P<sid>\d+);")
CLASSTYPE_RE = re.compile(r"\bclasstype:(?P<class>[^;]+);")
PRIORITY_RE = re.compile(r"\bpriority:(?P<priority>\d+);")


@dataclass(frozen=True)
class Rule:
    sid: int
    action: str
    proto: str
    message: str
    classtype: str
    priority: int | None
    enabled: bool
    line: str

    def as_dict(self) -> dict[str, object]:
        return {
            "sid": self.sid,
            "action": self.action,
            "proto": self.proto,
            "message": self.message,
            "classtype": self.classtype,
            "priority": self.priority,
            "enabled": self.enabled,
            "line": self.line,
        }


def parse_rule_line(line: str, disabled_sids: set[int] | None = None) -> Rule | None:
    match = RULE_RE.match(line.strip())
    if not match:
        return None
    body = match.group("body")
    sid_match = SID_RE.search(body)
    if not sid_match:
        return None
    sid = int(sid_match.group("sid"))
    class_match = CLASSTYPE_RE.search(body)
    priority_match = PRIORITY_RE.search(body)
    disabled_by_file = disabled_sids is not None and sid in disabled_sids
    disabled_inline = bool(match.group("disabled"))
    return Rule(
        sid=sid,
        action=match.group("action"),
        proto=match.group("proto"),
        message=match.group("msg"),
        classtype=class_match.group("class") if class_match else "",
        priority=int(priority_match.group("priority")) if priority_match else None,
        enabled=not disabled_inline and not disabled_by_file,
        line=line.rstrip("\n"),
    )


def read_disabled_sids(path: Path = SURICATA_DISABLE_FILE) -> set[int]:
    if not path.exists():
        return set()
    sids: set[int] = set()
    for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.isdigit():
            sids.add(int(line))
    return sids


def list_rules(
    query: str = "",
    sid: int | None = None,
    severity: int | None = None,
    category: str = "",
    limit: int = 500,
    rules_file: Path = SURICATA_RULES_FILE,
) -> list[dict[str, object]]:
    if not rules_file.exists():
        return []
    disabled_sids = read_disabled_sids()
    query_lower = query.lower()
    category_lower = category.lower()
    results = []
    for line in rules_file.read_text(encoding="utf-8", errors="ignore").splitlines():
        rule = parse_rule_line(line, disabled_sids)
        if not rule:
            continue
        if sid is not None and rule.sid != sid:
            continue
        if severity is not None and rule.priority != severity:
            continue
        if category_lower and category_lower not in rule.classtype.lower():
            continue
        haystack = f"{rule.sid} {rule.action} {rule.proto} {rule.message} {rule.classtype} {rule.line}".lower()
        if query_lower and query_lower not in haystack:
            continue
        results.append(rule.as_dict())
        if len(results) >= limit:
            break
    return results


def backup_file(path: Path) -> Path:
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup = path.with_name(f"{path.name}.bak.{timestamp}")
    if path.exists():
        shutil.copy2(path, backup)
    else:
        path.parent.mkdir(parents=True, exist_ok=True)
        backup.write_text("", encoding="utf-8")
    return backup


def write_disabled_sids(sids: set[int], path: Path = SURICATA_DISABLE_FILE) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = ["# Managed by SURICATAMAN Console", *[str(sid) for sid in sorted(sids)]]
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def run_checked(command: list[str]) -> None:
    subprocess.run(command, text=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def set_rule_enabled(sid: int, enabled: bool) -> dict[str, object]:
    backup = backup_file(SURICATA_DISABLE_FILE)
    disabled = read_disabled_sids()
    if enabled:
        disabled.discard(sid)
    else:
        disabled.add(sid)
    write_disabled_sids(disabled)
    try:
        run_checked(["sudo", "-n", "suricata-update"])
        run_checked(["sudo", "-n", "suricata", "-T", "-c", str(SURICATA_CONFIG)])
        run_checked(["sudo", "-n", "systemctl", "restart", "suricata.service"])
    except subprocess.CalledProcessError:
        shutil.copy2(backup, SURICATA_DISABLE_FILE)
        raise
    return {"sid": sid, "enabled": enabled, "backup": str(backup)}
