"""Exception classes for the Lightpanda Python binding."""


class LightpandaError(Exception):
    """Base exception for all Lightpanda errors."""


class BinaryNotFoundError(LightpandaError):
    """Raised when the lightpanda binary cannot be found."""


class FetchError(LightpandaError):
    """Raised when a fetch operation fails."""

    def __init__(self, message: str, returncode: int | None = None, stderr: str = ""):
        super().__init__(message)
        self.returncode = returncode
        self.stderr = stderr


class ServerError(LightpandaError):
    """Raised when the CDP server fails to start or encounters an error."""


class TimeoutError(LightpandaError):
    """Raised when an operation times out."""
