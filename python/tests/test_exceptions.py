"""Tests for chameleon exception classes."""

import pytest
from chameleon.exceptions import (
    ChameleonError,
    BinaryNotFoundError,
    FetchError,
    ServerError,
    TimeoutError,
)


class TestExceptionHierarchy:
    """All custom exceptions should inherit from ChameleonError."""

    def test_binary_not_found_is_chameleon_error(self):
        assert issubclass(BinaryNotFoundError, ChameleonError)

    def test_fetch_error_is_chameleon_error(self):
        assert issubclass(FetchError, ChameleonError)

    def test_server_error_is_chameleon_error(self):
        assert issubclass(ServerError, ChameleonError)

    def test_timeout_error_is_chameleon_error(self):
        assert issubclass(TimeoutError, ChameleonError)

    def test_chameleon_error_is_exception(self):
        assert issubclass(ChameleonError, Exception)


class TestFetchError:
    """FetchError should carry returncode and stderr attributes."""

    def test_default_attributes(self):
        err = FetchError("something failed")
        assert str(err) == "something failed"
        assert err.returncode is None
        assert err.stderr == ""

    def test_custom_attributes(self):
        err = FetchError("curl failed", returncode=7, stderr="connection refused")
        assert err.returncode == 7
        assert err.stderr == "connection refused"

    def test_catchable_as_chameleon_error(self):
        with pytest.raises(ChameleonError):
            raise FetchError("test", returncode=1)


class TestExceptionMessages:
    """All exceptions should preserve their message."""

    def test_binary_not_found(self):
        err = BinaryNotFoundError("not found")
        assert str(err) == "not found"

    def test_server_error(self):
        err = ServerError("port in use")
        assert str(err) == "port in use"

    def test_timeout_error(self):
        err = TimeoutError("timed out after 10s")
        assert str(err) == "timed out after 10s"
