# Chameleon Browser Python Binding

Python wrapper for the [Chameleon headless browser](https://github.com/chameleon-browser/chameleon-browser), designed for advanced fingerprint spoofing.

## Features

- **Playwright Native:** Automatically starts a CDP server and yields a standard Playwright `Browser` instance.
- **Anti-Detection Profiles:** Pass a single profile string (`chrome131-macos`) and get TLS, HTTP/2, Canvas, and User-Agent signatures aligned automatically.
- **Sync & Async Support:** Native support for both blocking and asyncio Playwright code.

## Installation

```bash
pip install chameleon-browser playwright
playwright install chromium
```

## Quick Start (Sync)

```python
from chameleon import ChameleonBrowser

# Initialize Chameleon with a fingerprint profile
browser = ChameleonBrowser(profile="chrome131-macos")

# It automatically manages the background CDP server and connects Playwright
with browser.connect() as pw_browser:
    # pw_browser is a standard Playwright Browser instance
    context = pw_browser.contexts[0]
    page = context.pages[0]
    
    page.goto("https://bot.sannysoft.com")
    page.screenshot(path="sannysoft.png")
    print(f"Loaded: {page.title()}")
```

## Quick Start (Async)

```python
import asyncio
from chameleon import AsyncChameleonBrowser

async def main():
    browser = AsyncChameleonBrowser(profile="chrome131-windows")
    
    async with browser.connect() as pw_browser:
        context = pw_browser.contexts[0]
        page = context.pages[0]
        
        await page.goto("https://arh.antoinevastel.com/bots/areyouheadless")
        element = await page.wait_for_selector("body")
        print(await element.inner_text())

asyncio.run(main())
```

## API Reference

### `ChameleonBrowser(binary_path=None, profile=None)`

- `binary_path`: Explicit path to the Chameleon executable. If `None`, it automatically searches your `PATH`, the `CHAMELEON_BIN` environment variable, or a local `zig-out` development directory.
- `profile`: A fingerprint string that configures TLS, headers, and Navigator APIs (e.g., `chrome116`, `chrome131-macos`).

### `with browser.connect()` / `async with browser.connect()`

Context managers that:
1. Find an available system port.
2. Launch the Chameleon background executable bound to that port.
3. Wait for the port to open.
4. Launch the local Playwright engine.
5. Call `connect_over_cdp` pointing to the spawned Chameleon instance.
6. Yield the Playwright `Browser` object.
7. Automatically tear down Playwright and terminate the Chameleon process when the block exits.
