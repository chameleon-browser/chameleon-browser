"""Lightpanda Browser - Python binding for headless browser with fingerprint spoofing."""

from lightpanda.browser import LightpandaBrowser
from lightpanda.cdp import CDPServer
from lightpanda.exceptions import (
    LightpandaError,
    BinaryNotFoundError,
    FetchError,
    ServerError,
    TimeoutError,
)

__version__ = "0.1.0"
__all__ = [
    "LightpandaBrowser",
    "CDPServer",
    "LightpandaError",
    "BinaryNotFoundError",
    "FetchError",
    "ServerError",
    "TimeoutError",
]
