import asyncio
import os
import shutil
import socket
import subprocess
import time
from typing import Optional, Any
from contextlib import asynccontextmanager, contextmanager

from playwright.async_api import async_playwright
from playwright.sync_api import sync_playwright

from .exceptions import BinaryNotFoundError, ServerError


def find_binary(custom_path: Optional[str] = None) -> str:
    if custom_path and os.path.isfile(custom_path) and os.access(custom_path, os.X_OK):
        return custom_path
        
    env_path = os.environ.get("CHAMELEON_BIN")
    if env_path and os.path.isfile(env_path) and os.access(env_path, os.X_OK):
        return env_path
        
    path_bin = shutil.which("chameleon")
    if path_bin:
        return path_bin
        
    # Check development path
    dev_path = os.path.join(os.getcwd(), "zig-out", "bin", "chameleon")
    if os.path.isfile(dev_path) and os.access(dev_path, os.X_OK):
        return dev_path
        
    raise BinaryNotFoundError("Could not find the 'chameleon' executable. Please install it or set CHAMELEON_BIN.")


def get_free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("", 0))
        return s.getsockname()[1]


class _ServerProcess:
    def __init__(self, binary_path: str, profile: Optional[str], port: int):
        self.port = port
        cmd = [binary_path, "serve", "--host", "127.0.0.1", "--port", str(port)]
        if profile:
            cmd.extend(["--browser", profile])
            
        self.process = subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        
        # Wait for port to open
        start_time = time.time()
        while time.time() - start_time < 10:
            try:
                with socket.create_connection(("127.0.0.1", port), timeout=0.5):
                    return
            except (ConnectionRefusedError, socket.timeout, OSError):
                time.sleep(0.1)
                
        self.process.kill()
        raise ServerError(f"Failed to start Chameleon CDP server on port {port}")

    def stop(self):
        if self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.process.kill()


class AsyncChameleonBrowser:
    """Async wrapper that manages the CDP server and Playwright integration."""
    def __init__(self, binary_path: Optional[str] = None, profile: Optional[str] = None):
        self.binary_path = find_binary(binary_path)
        self.profile = profile
        self._server = None
        self._playwright = None
        
    @asynccontextmanager
    async def connect(self):
        """Starts the Chameleon CDP server and connects via Playwright async API."""
        port = get_free_port()
        self._server = _ServerProcess(self.binary_path, self.profile, port)
        
        self._playwright = await async_playwright().start()
        try:
            ws_endpoint = f"ws://127.0.0.1:{port}"
            browser = await self._playwright.chromium.connect_over_cdp(ws_endpoint)
            yield browser
            await browser.close()
        finally:
            await self._playwright.stop()
            self._server.stop()


class ChameleonBrowser:
    """Sync wrapper that manages the CDP server and Playwright integration."""
    def __init__(self, binary_path: Optional[str] = None, profile: Optional[str] = None):
        self.binary_path = find_binary(binary_path)
        self.profile = profile
        self._server = None
        self._playwright = None
        
    @contextmanager
    def connect(self):
        """Starts the Chameleon CDP server and connects via Playwright sync API."""
        port = get_free_port()
        self._server = _ServerProcess(self.binary_path, self.profile, port)
        
        self._playwright = sync_playwright().start()
        try:
            ws_endpoint = f"ws://127.0.0.1:{port}"
            browser = self._playwright.chromium.connect_over_cdp(ws_endpoint)
            yield browser
            browser.close()
        finally:
            self._playwright.stop()
            self._server.stop()
