import subprocess
from dataclasses import dataclass
from pathlib import Path

from .config import COMMAND_TIMEOUT_SECONDS, REPO_ROOT, SURICATAMAN_SCRIPT


class CommandError(RuntimeError):
    def __init__(self, command: list[str], returncode: int, stdout: str, stderr: str) -> None:
        self.command = command
        self.returncode = returncode
        self.stdout = stdout
        self.stderr = stderr
        super().__init__(f"Command failed ({returncode}): {' '.join(command)}")


@dataclass(frozen=True)
class CommandResult:
    command: list[str]
    stdout: str
    stderr: str
    returncode: int


def run_command(command: list[str], timeout: int = COMMAND_TIMEOUT_SECONDS) -> CommandResult:
    completed = subprocess.run(
        command,
        cwd=REPO_ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=timeout,
        check=False,
    )
    if completed.returncode != 0:
        raise CommandError(command, completed.returncode, completed.stdout, completed.stderr)
    return CommandResult(command, completed.stdout, completed.stderr, completed.returncode)


def run_suricataman(args: list[str], require_root: bool = True) -> CommandResult:
    command = ["bash", str(SURICATAMAN_SCRIPT), *args]
    if require_root:
        command = ["sudo", "-n", *command]
    return run_command(command)


def ensure_localhost(host: str) -> str:
    if host not in {"127.0.0.1", "localhost"}:
        raise ValueError("SURICATAMAN Console v0.1 solo debe escuchar en localhost.")
    return host


def path_exists(path: Path) -> bool:
    return path.exists()
