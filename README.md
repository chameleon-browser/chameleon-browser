<h1 align="center">Chameleon Browser</h1>

<p align="center">
  <strong>The open-source headless browser designed for advanced fingerprint spoofing and anti-detection.</strong>
</p>

<p align="center">
  <a href="https://github.com/chameleon-browser/chameleon-browser/blob/main/LICENSE"><img src="https://img.shields.io/github/license/chameleon-browser/chameleon-browser" alt="License"></a>
</p>

> **Fork Note:** This project is a specialized fork of [lightpanda-io/browser](https://github.com/lightpanda-io/browser). While the original Lightpanda provides an incredibly fast and lightweight Zig-based headless browser, Chameleon Browser specifically focuses on **bypassing modern anti-bot systems** (Cloudflare, Akamai, PerimeterX, etc.) by simulating deeply realistic browser fingerprints.

---

## Why Chameleon Browser?

Standard headless browsers (like Chrome Headless or Puppeteer defaults) leak their automated nature through hundreds of subtle signals. Modern WAFs and anti-bot systems inspect far more than just your `User-Agent`. 

Chameleon Browser modifies the browser engine at the lowest levels to spoof:

- **TLS Fingerprints (JA3/JA4):** Replaces BoringSSL/OpenSSL defaults with [curl-impersonate](https://github.com/lwthiker/curl-impersonate) to match exact Chrome TLS signatures.
- **HTTP/2 Settings:** Matches Chrome's exact `SETTINGS` frames, `WINDOW_UPDATE` behavior, and pseudo-header ordering.
- **JavaScript Global Objects:** Simulates `window.chrome` (including `runtime`, `app`, `csi`, `loadTimes`).
- **Canvas & AudioContext:** Spoofs media device rendering and DSP pipelines to bypass fingerprint hashing.
- **Navigator APIs:** Injects realistic `plugins`, `mimeTypes`, `permissions`, and `languages` arrays.
- **Client Hints:** Fully implements `navigator.userAgentData` with high-entropy values.

## ⚠️ Important Note: Rendering and Screenshots

**Chameleon Browser does not actually render visual pixels to a screen or buffer.** 

Because it is designed purely for high-performance scraping, DOM manipulation, and script execution, the engine deliberately omits the heavy graphics rendering pipeline. 

As a result, **features like screenshots (`page.screenshot()`) or PDF generation are not supported.** Any attempt to use visual commands will either be ignored or return an error. You should use DOM extraction methods (like `page.content()`, `page.evaluate()`, or `page.locator()`) to interact with the page instead.

## Quick Start (Python)

The easiest way to use Chameleon Browser is via our official Python binding, which seamlessly integrates with **Playwright**. It automatically manages the CDP server lifecycle and returns a native Playwright `Browser` instance.

### Installation

```bash
# Only install the python packages. 
# There is NO NEED to run `playwright install chromium` because Chameleon is its own browser engine!
pip install chameleon-browser playwright
```

### Usage

```python
from chameleon import ChameleonBrowser

# Initialize Chameleon with a specific fingerprint profile
browser = ChameleonBrowser(profile="chrome131-macos")

# It automatically starts a CDP server on a random port and connects Playwright
with browser.connect() as pw_browser:
    # pw_browser is a standard Playwright Browser instance!
    context = pw_browser.contexts[0]
    page = context.pages[0]
    
    # Navigate to a test page
    page.goto("https://bot.sannysoft.com")
    
    print(f"Title: {page.title()}")
```

<details>
<summary><strong>Async Example</strong></summary>

```python
import asyncio
from chameleon import AsyncChameleonBrowser

async def main():
    browser = AsyncChameleonBrowser(profile="chrome131-macos")
    async with browser.connect() as pw_browser:
        context = pw_browser.contexts[0]
        page = context.pages[0]
        await page.goto("https://bot.sannysoft.com")
        print(await page.title())

asyncio.run(main())
```

</details>

## Available Profiles

Browser profiles ensure consistency across all fingerprint vectors (TLS, HTTP/2, User-Agent, Screen dimensions, WebGL vendor, etc.).

| Profile ID | Target Browser | Platform | Notes |
|------------|----------------|----------|-------|
| `chrome116` | Chrome 116 | Default | Widest compatibility |
| `chrome131-macos` | Chrome 131 | macOS | Realistic Mac simulation |
| `chrome131-windows` | Chrome 131 | Windows | Realistic Windows simulation |
| `chrome131-linux` | Chrome 131 | Linux | Realistic Linux simulation |

## Standalone Binary Usage

If you prefer not to use Python, you can download the standalone binary and connect to it with any CDP client (Node.js Puppeteer, Go chromedp, etc.).

**1. Start the Server:**
```console
./chameleon serve --browser chrome131-macos --host 127.0.0.1 --port 9222
```

**2. Connect with Puppeteer (Node.js):**
```js
import puppeteer from 'puppeteer-core';

// Connect Playwright/Puppeteer directly to Chameleon's WebSocket endpoint
const browser = await puppeteer.connect({
  browserWSEndpoint: "ws://127.0.0.1:9222",
});

const context = await browser.createBrowserContext();
const page = await context.newPage();
await page.goto('https://bot.sannysoft.com');

const title = await page.title();
console.log(`Page title: ${title}`);
```

## Build from Source

### Prerequisites

- [Zig](https://ziglang.org/) 0.15.2
- [Rust](https://rust-lang.org/tools/install/) (for HTML parsing)
- System dependencies: `cmake`, `pkg-config`, `libglib2.0-dev` (Linux only)

### Build Instructions

```bash
# 1. Initialize submodules (curl-impersonate, v8, etc.)
make install-submodule

# 2. Build the browser (Release mode)
make build

# The executable will be available at ./zig-out/bin/chameleon
```

## Detection Status & Benchmark

Chameleon is continuously tested against major fingerprinting services. See our [Fingerprint Audit Report](docs/fingerprint-audit-report.md) for detailed metrics.

To run the local benchmark against curl:
```bash
python3 chameleon_benchmark.py --browser chrome116 --tls-runs 5
```

## License

This project is licensed under the **AGPL-3.0** License. See the [LICENSE](LICENSE) file for details.

*Original base project by [Lightpanda (Selecy SAS)](https://lightpanda.io).*
