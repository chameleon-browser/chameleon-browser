"""Chameleon Browser - Python binding for headless browser with fingerprint spoofing."""

from .browser import ChameleonBrowser, AsyncChameleonBrowser
from .exceptions import (
    ChameleonError,
    BinaryNotFoundError,
    FetchError,
    ServerError,
    TimeoutError,
)

__version__ = "0.1.0"
__all__ = [
    "ChameleonBrowser",
    "AsyncChameleonBrowser",
    "ChameleonError",
    "BinaryNotFoundError",
    "FetchError",
    "ServerError",
    "TimeoutError",
]
