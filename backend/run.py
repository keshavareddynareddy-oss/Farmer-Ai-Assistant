if __name__ == "__main__":
    import subprocess
    from pathlib import Path

    project_root = Path(__file__).resolve().parent.parent
    python_candidates = (
        Path(__file__).resolve().parent / ".venv-py311" / "Scripts" / "python.exe",
        project_root / ".venv" / "Scripts" / "python.exe",
    )
    python_executable = next(
        (str(candidate) for candidate in python_candidates if candidate.exists()),
        "python",
    )

    subprocess.run(
        [
            python_executable,
            "-m",
            "uvicorn",
            "--app-dir",
            ".",
            "app.main:app",
            "--reload",
            "--host",
            "0.0.0.0",
            "--port",
            "8000",
        ],
        cwd=str(Path(__file__).resolve().parent),
        check=True,
    )
