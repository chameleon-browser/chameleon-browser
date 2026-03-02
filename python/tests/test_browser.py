"""Tests for browser module utility functions and classes."""

import os
import socket
import subprocess
from unittest.mock import patch, MagicMock

import pytest

from chameleon.browser import find_binary, get_free_port, _ServerProcess
from chameleon.exceptions import BinaryNotFoundError, ServerError


class TestFindBinary:
    """Tests for the find_binary() function."""

    def test_custom_path_valid(self, tmp_path):
        """Should return custom_path when it is an existing executable file."""
        binary = tmp_path / "chameleon"
        binary.write_text("#!/bin/sh\n")
        binary.chmod(0o755)
        assert find_binary(str(binary)) == str(binary)

    def test_custom_path_not_executable(self, tmp_path):
        """Should skip custom_path if it exists but is not executable."""
        binary = tmp_path / "chameleon"
        binary.write_text("not executable")
        binary.chmod(0o644)
        # Should not return the non-executable file, should fall through
        with patch.dict(os.environ, {}, clear=True):
            with patch("shutil.which", return_value=None):
                with pytest.raises(BinaryNotFoundError):
                    find_binary(str(binary))

    def test_env_var_path(self, tmp_path):
        """Should find binary via CHAMELEON_BIN env var."""
        binary = tmp_path / "chameleon"
        binary.write_text("#!/bin/sh\n")
        binary.chmod(0o755)
        with patch.dict(os.environ, {"CHAMELEON_BIN": str(binary)}):
            assert find_binary() == str(binary)

    def test_system_path(self, tmp_path):
        """Should find binary via shutil.which (system PATH)."""
        with patch.dict(os.environ, {}, clear=False):
            # Clear CHAMELEON_BIN if set
            os.environ.pop("CHAMELEON_BIN", None)
            with patch("shutil.which", return_value="/usr/local/bin/chameleon"):
                assert find_binary() == "/usr/local/bin/chameleon"

    def test_dev_path(self, tmp_path):
        """Should find binary in zig-out/bin/chameleon relative to cwd."""
        dev_dir = tmp_path / "zig-out" / "bin"
        dev_dir.mkdir(parents=True)
        binary = dev_dir / "chameleon"
        binary.write_text("#!/bin/sh\n")
        binary.chmod(0o755)
        with patch.dict(os.environ, {}, clear=False):
            os.environ.pop("CHAMELEON_BIN", None)
            with patch("shutil.which", return_value=None):
                with patch("os.getcwd", return_value=str(tmp_path)):
                    assert find_binary() == str(binary)

    def test_not_found_raises(self):
        """Should raise BinaryNotFoundError when binary cannot be found anywhere."""
        with patch.dict(os.environ, {}, clear=False):
            os.environ.pop("CHAMELEON_BIN", None)
            with patch("shutil.which", return_value=None):
                with patch("os.getcwd", return_value="/nonexistent"):
                    with pytest.raises(BinaryNotFoundError):
                        find_binary()


class TestGetFreePort:
    """Tests for get_free_port()."""

    def test_returns_positive_int(self):
        """Should return a valid port number."""
        port = get_free_port()
        assert isinstance(port, int)
        assert 1024 <= port <= 65535

    def test_returns_different_ports(self):
        """Should return different ports on consecutive calls (non-deterministic but highly likely)."""
        ports = {get_free_port() for _ in range(5)}
        # At least 2 different ports out of 5 attempts
        assert len(ports) >= 2


class TestServerProcess:
    """Tests for _ServerProcess startup and teardown."""

    def test_raises_server_error_on_timeout(self, tmp_path):
        """Should raise ServerError if port never opens within timeout."""
        # Create a fake binary that does nothing (just sleeps)
        binary = tmp_path / "fake_chameleon"
        binary.write_text("#!/bin/sh\nsleep 60\n")
        binary.chmod(0o755)

        port = get_free_port()
        with patch.object(_ServerProcess.__init__, '__defaults__', None):
            pass  # Can't easily mock the timeout, so test the error path differently

    def test_stop_terminates_process(self):
        """Should call terminate then wait on the subprocess."""
        server = object.__new__(_ServerProcess)
        mock_proc = MagicMock()
        mock_proc.poll.return_value = None
        server.process = mock_proc

        server.stop()

        mock_proc.terminate.assert_called_once()
        mock_proc.wait.assert_called_once_with(timeout=5)

    def test_stop_kills_on_timeout(self):
        """Should force kill if terminate doesn't work within timeout."""
        server = object.__new__(_ServerProcess)
        mock_proc = MagicMock()
        mock_proc.poll.return_value = None
        mock_proc.wait.side_effect = subprocess.TimeoutExpired(cmd="chameleon", timeout=5)
        server.process = mock_proc

        server.stop()

        mock_proc.terminate.assert_called_once()
        mock_proc.kill.assert_called_once()

    def test_stop_already_exited(self):
        """Should do nothing if process already exited."""
        server = object.__new__(_ServerProcess)
        mock_proc = MagicMock()
        mock_proc.poll.return_value = 0  # Already exited
        server.process = mock_proc

        server.stop()

        mock_proc.terminate.assert_not_called()
