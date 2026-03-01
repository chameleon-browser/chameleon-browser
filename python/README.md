# Lightpanda Python Binding

Python wrapper for the [Lightpanda headless browser](https://github.com/chameleon-browser/chameleon-browser) with enhanced fingerprint spoofing capabilities.

## Installation

```bash
pip install chameleon-browser
```

## Quick Start

### Fetch a Page

```python
from lightpanda import LightpandaBrowser

browser = LightpandaBrowser()
html = browser.fetch("https://example.com")
print(html)
```

### With Fingerprint Profile

```python
browser = LightpandaBrowser(profile="chrome131-macos")
html = browser.fetch("https://bot.sannysoft.com")
```

### Start CDP Server (for Puppeteer/Playwright)

```python
from lightpanda import LightpandaBrowser

browser = LightpandaBrowser(profile="chrome131-macos")

# Start CDP server (blocks until stop() or context manager exit)
with browser.cdp_server(host="127.0.0.1", port=9222) as server:
    print(f"CDP server running at ws://{server.host}:{server.port}")
    # Connect with Puppeteer/Playwright from another process
    server.wait()  # or do other work
```

### Async Support

```python
import asyncio
from lightpanda import LightpandaBrowser

async def main():
    browser = LightpandaBrowser(profile="chrome131-macos")
    html = await browser.async_fetch("https://example.com")
    print(html)

asyncio.run(main())
```

## API Reference

### `LightpandaBrowser`

Main class for interacting with the Lightpanda browser.

#### Constructor

```python
LightpandaBrowser(
    binary_path=None,     # Path to lightpanda binary (auto-detected if None)
    profile=None,         # Browser fingerprint profile (e.g., "chrome131-macos")
    log_level="error",    # Log level: "error", "warn", "info", "debug"
    log_format="pretty",  # Log format: "pretty", "json"
    obey_robots=False,    # Respect robots.txt
    http_timeout=30000,   # HTTP timeout in milliseconds
    proxy=None,           # HTTP proxy URL
)
```

#### Methods

| Method | Description |
|--------|-------------|
| `fetch(url)` | Fetch a URL and return the rendered HTML |
| `async_fetch(url)` | Async version of fetch |
| `cdp_server(host, port)` | Start a CDP WebSocket server |
| `version()` | Get the Lightpanda binary version |

### `CDPServer`

Returned by `browser.cdp_server()`. Use as a context manager.

| Method | Description |
|--------|-------------|
| `start()` | Start the server |
| `stop()` | Stop the server |
| `wait()` | Block until the server exits |
| `ws_endpoint` | WebSocket endpoint URL |

## Available Profiles

| Profile | Description |
|---------|-------------|
| `chrome116` | Chrome 116 on default platform |
| `chrome131-macos` | Chrome 131 on macOS |
| `chrome131-windows` | Chrome 131 on Windows |
| `chrome131-linux` | Chrome 131 on Linux |

## Binary Resolution

The Python binding looks for the `lightpanda` binary in this order:

1. `binary_path` argument passed to constructor
2. `LIGHTPANDA_BIN` environment variable
3. `lightpanda` on system `PATH`
4. `./zig-out/bin/lightpanda` (development build)
5. Bundled binary in the package (if installed with binary distribution)

## License

AGPL-3.0 — see [LICENSE](../LICENSE).
