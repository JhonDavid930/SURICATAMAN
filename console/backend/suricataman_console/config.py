from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parents[1]
CONSOLE_DIR = BACKEND_DIR.parent
REPO_ROOT = CONSOLE_DIR.parent

SURICATAMAN_SCRIPT = REPO_ROOT / "suricataman.sh"
SURICATA_RULES_FILE = Path("/var/lib/suricata/rules/suricata.rules")
SURICATA_DISABLE_FILE = Path("/etc/suricata/disable.conf")
SURICATA_CONFIG = Path("/etc/suricata/suricata.yaml")

COMMAND_TIMEOUT_SECONDS = 180
RULES_QUERY_LIMIT = 500
