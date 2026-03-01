"""Chameleon Browser - Python binding for headless browser with fingerprint spoofing."""

from chameleon.browser import ChameleonBrowser
from chameleon.cdp import CDPServer
from chameleon.exceptions import (
    ChameleonError,
    BinaryNotFoundError,
    FetchError,
    ServerError,
    TimeoutError,
)

__version__ = "0.1.0"
__all__ = [
    "ChameleonBrowser",
    "CDPServer",
    "ChameleonError",
    "BinaryNotFoundError",
    "FetchError",
    "ServerError",
    "TimeoutError",
]
