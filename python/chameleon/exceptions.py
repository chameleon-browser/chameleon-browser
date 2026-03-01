"""Exception classes for the Chameleon Python binding."""


class ChameleonError(Exception):
    """Base exception for all Chameleon errors."""


class BinaryNotFoundError(ChameleonError):
    """Raised when the chameleon binary cannot be found."""


class FetchError(ChameleonError):
    """Raised when a fetch operation fails."""

    def __init__(self, message: str, returncode: int | None = None, stderr: str = ""):
        super().__init__(message)
        self.returncode = returncode
        self.stderr = stderr


class ServerError(ChameleonError):
    """Raised when the CDP server fails to start or encounters an error."""


class TimeoutError(ChameleonError):
    """Raised when an operation times out."""
