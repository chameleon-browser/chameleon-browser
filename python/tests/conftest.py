"""Shared test fixtures for chameleon tests."""

import os
import sys

import pytest


@pytest.fixture
def fake_binary(tmp_path):
    """Create a fake chameleon binary for testing."""
    binary = tmp_path / "chameleon"
    binary.write_text("#!/bin/sh\necho 'fake chameleon'\n")
    binary.chmod(0o755)
    return str(binary)
