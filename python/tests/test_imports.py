"""Tests for chameleon package imports and version."""

import chameleon
from chameleon import (
    ChameleonBrowser,
    AsyncChameleonBrowser,
    ChameleonError,
    BinaryNotFoundError,
    FetchError,
    ServerError,
    TimeoutError,
)


def test_version():
    """Package version should be a valid semver string."""
    assert chameleon.__version__ == "0.1.0"


def test_all_exports():
    """__all__ should list all public names."""
    expected = {
        "ChameleonBrowser",
        "AsyncChameleonBrowser",
        "ChameleonError",
        "BinaryNotFoundError",
        "FetchError",
        "ServerError",
        "TimeoutError",
    }
    assert set(chameleon.__all__) == expected


def test_browser_classes_exist():
    """Browser classes should be importable and callable."""
    assert callable(ChameleonBrowser)
    assert callable(AsyncChameleonBrowser)
