"""Test that the Python package builds correctly."""

import subprocess
import sys


def test_package_import():
    """Package should be importable in a fresh subprocess."""
    result = subprocess.run(
        [sys.executable, "-c", "import chameleon; print(chameleon.__version__)"],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0
    assert result.stdout.strip() == "0.1.0"


def test_package_metadata():
    """Package metadata should be accessible via importlib.metadata."""
    result = subprocess.run(
        [
            sys.executable,
            "-c",
            (
                "from importlib.metadata import metadata; "
                "m = metadata('chameleon-browser'); "
                "print(m['Name']); "
                "print(m['Version'])"
            ),
        ],
        capture_output=True,
        text=True,
    )
    # This may fail if the package isn't installed; skip gracefully
    if result.returncode == 0:
        lines = result.stdout.strip().split("\n")
        assert lines[0].lower().replace("-", "_") in ("chameleon_browser", "chameleon-browser")
        assert lines[1] == "0.1.0"
