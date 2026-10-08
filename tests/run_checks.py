#!/usr/bin/env python3
"""Run Godot checks in a staged project with disposable, isolated player data.

This never exports an Android artifact and never changes the source checkout.
"""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import uuid

ROOT = Path(__file__).resolve().parents[1]
SUITES = {
    "smoke": ("story_smoke.gd", "Rendered 59 scenes; failures=0"),
    "regressions": ("game_regressions.gd", "Game regression checks="),
    "screenshots": ("screenshots.gd", "Screenshot checks; failures=0"),
}


def stage_project(source: Path, destination: Path, name: str) -> None:
    if re.fullmatch(r"ike-quest-qa-[0-9a-f]{32}", name) is None:
        raise ValueError("Invalid disposable QA directory name")
    shutil.copytree(source, destination, ignore=shutil.ignore_patterns(
        ".git", ".godot", "exports", "override.cfg", "__pycache__", ".qa-user-data-path",
        "*.apk", "*.aab", "*.keystore", "*.jks",
    ))
    (destination / "override.cfg").write_text(
        '[application]\nconfig/use_custom_user_dir=true\n'
        f'config/custom_user_dir_name="{name}"\n', encoding="utf-8",
    )


def cleanup_data(stage: Path, name: str) -> None:
    receipt = stage / ".qa-user-data-path"
    if not receipt.exists():
        return  # Godot may have failed before running the guard.
    data = Path(receipt.read_text(encoding="utf-8").strip())
    if not data.is_absolute() or data.name != name or data.is_symlink():
        raise RuntimeError("Refusing unsafe QA data cleanup path")
    marker = data / ".ike-quest-qa"
    if not marker.is_file() or marker.is_symlink() or marker.read_text(encoding="utf-8") != name:
        raise RuntimeError("Refusing QA cleanup without the matching marker")
    shutil.rmtree(data)


def run_logged(command: list[str], env: dict[str, str], log: Path, expected: str = "") -> None:
    result = subprocess.run(command, env=env, text=True, encoding="utf-8", errors="replace",
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=240, check=False)
    log.write_text(result.stdout, encoding="utf-8")
    print(result.stdout, end="", flush=True)
    error = re.search(r"SCRIPT ERROR:|Parse Error:|^ERROR:|^FAIL:", result.stdout, re.MULTILINE)
    if result.returncode or error or (expected and expected not in result.stdout):
        raise RuntimeError(f"Godot check failed; see {log}")
    if expected == "Game regression checks=" and not re.search(r"Game regression checks=\d+; failures=0", result.stdout):
        raise RuntimeError(f"Regression summary did not report zero failures; see {log}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.environ.get("GODOT_BIN", "godot4"))
    parser.add_argument("--suite", choices=[*SUITES, "all"], default="all")
    parser.add_argument("--output", type=Path, default=ROOT / "exports" / "qa")
    args = parser.parse_args(argv)
    binary = shutil.which(args.godot)
    if binary is None:
        parser.error(f"Godot executable not found: {args.godot}. Pass --godot /path/to/Godot.")
    output = args.output.resolve()
    # Do not allow log output to overwrite a tracked source directory.
    if output == ROOT or (ROOT in output.parents and (ROOT / "exports") not in (output, *output.parents)):
        parser.error("Output inside the checkout must be under exports/.")
    output.mkdir(parents=True, exist_ok=True)
    names = list(SUITES) if args.suite == "all" else [args.suite]
    name = "ike-quest-qa-" + uuid.uuid4().hex
    with tempfile.TemporaryDirectory(prefix="ike-quest-checks-") as temporary:
        stage = Path(temporary) / "project"
        stage_project(ROOT, stage, name)
        env = dict(os.environ, IKE_QUEST_QA_DIR_NAME=name, GODOT_SILENCE_ROOT_WARNING="1")
        # Ignore any environment-selected external override from the parent shell.
        env.pop("GODOT_OVERRIDE", None)
        try:
            base = [binary, "--path", str(stage), "--rendering-method", "gl_compatibility"]
            run_logged(base + ["--headless", "--editor", "--import"], env, output / "import.log")
            for suite in names:
                script, expected = SUITES[suite]
                command = base + ["--script", "res://tests/" + script]
                if suite == "screenshots":
                    shots = output / "shots"
                    shots.mkdir(exist_ok=True)
                    env["IKE_SHOTS_DIR"] = str(shots)
                    env["LIBGL_ALWAYS_SOFTWARE"] = "1"
                    command += ["--rendering-driver", "opengl3", "--resolution", "540x960"]
                    if sys.platform.startswith("linux") and not env.get("DISPLAY"):
                        xvfb = shutil.which("xvfb-run")
                        if not xvfb:
                            raise RuntimeError("Screenshots need a display or xvfb-run.")
                        command = [xvfb, "-a", "-s", "-screen 0 540x960x24", *command]
                else:
                    command.append("--headless")
                run_logged(command, env, output / (suite + ".log"), expected)
        finally:
            cleanup_data(stage, name)
    print("All requested checks passed. No release artifacts were built.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as exc:
        print(f"QA failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
