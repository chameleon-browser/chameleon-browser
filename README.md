# Lightpanda Browser (Enhanced Fingerprint Fork)

> **This project is forked from [lightpanda-io/browser](https://github.com/lightpanda-io/browser).**
> The original Lightpanda is an excellent open-source headless browser written in Zig. This fork aims to **significantly enhance browser fingerprint spoofing capabilities**, making it harder for anti-bot systems to detect headless usage.

---

## Why This Fork?

The original Lightpanda browser is fast, lightweight, and supports CDP (Chrome DevTools Protocol). However, modern anti-bot systems (Cloudflare, Akamai, PerimeterX, DataDome, etc.) go far beyond simple User-Agent checks. They inspect:

- **TLS fingerprints** (JA3/JA4, cipher suite ordering)
- **HTTP/2 settings** (SETTINGS frame, WINDOW_UPDATE, pseudo-header order)
- **Canvas / WebGL fingerprints** (pixel-level rendering output)
- **AudioContext fingerprints** (oscillator + compressor DSP pipeline)
- **Navigator API consistency** (plugins, mimeTypes, permissions, languages)
- **CSS feature detection** (matchMedia queries)
- **Network header ordering** (Sec-CH-UA, Sec-Fetch-* headers)

This fork integrates [curl-impersonate](https://github.com/lwthiker/curl-impersonate) and adds profile-driven fingerprint spoofing across all these layers, with a clear roadmap to reach production-grade anti-detection.

## Key Enhancements Over Upstream

| Feature | Upstream | This Fork |
|---------|----------|-----------|
| TLS Fingerprint (JA3/JA4) | Default curl/BoringSSL | curl-impersonate with Chrome TLS profiles |
| HTTP/2 Settings | Partial | Full Chrome-matching SETTINGS/WINDOW_UPDATE/pseudo-headers |
| Browser Profiles | None | Configurable profiles (chrome116, chrome131-macos, etc.) |
| `window.chrome` object | Not present | Full runtime/app/csi/loadTimes implementation |
| `navigator.webdriver` | `true` | `false` (passes WebDriver detection) |
| Client Hints API | Not present | Full userAgentData with brands/platform/highEntropyValues |
| Canvas Fingerprint | Not implemented | Seed-based generation (WIP: realistic rendering) |
| AudioContext Fingerprint | Not implemented | Seed-based generation (WIP: DSP simulation) |
| Screen/Display properties | Defaults | Profile-driven (resolution, colorDepth, DPR) |
| V8 Heap Limits | Unlimited | Configurable memory limits + navigation loop protection |
| Python Binding | None | `pip install lightpanda` for easy integration |

## Detection Test Results

Tested against real-world anti-bot detection services:

| Detection Service | Result |
|-------------------|--------|
| [bot.sannysoft.com](https://bot.sannysoft.com) | 50% pass (basic checks all pass) |
| [AreYouHeadless](https://arh.antoinevastel.com/bots/areyouheadless) | **PASS** |
| [tls.peet.ws](https://tls.peet.ws/api/all) | HTTP/2 match, TLS profile match |
| [BrowserLeaks Canvas](https://browserleaks.com/canvas) | Canvas API present (fingerprint WIP) |

See the full [Fingerprint Audit Report](docs/fingerprint-audit-report.md) for details.

## Quick Start

### Option 1: Python Binding (Recommended)

The easiest way to use this project is through the Python binding:

```bash
pip install chameleon-browser
```

```python
from lightpanda import LightpandaBrowser

# Basic usage - fetch a page
browser = LightpandaBrowser()
html = browser.fetch("https://example.com")
print(html)

# With fingerprint profile
browser = LightpandaBrowser(profile="chrome131-macos")
html = browser.fetch("https://bot.sannysoft.com")

# Start a CDP server for Puppeteer/Playwright
server = browser.serve(host="127.0.0.1", port=9222)
# Then connect with Puppeteer:
#   puppeteer.connect({ browserWSEndpoint: "ws://127.0.0.1:9222" })
server.stop()
```

See [python/README.md](python/README.md) for full Python API documentation.

### Option 2: Binary

Download pre-built binaries or build from source.

**Fetch a URL:**
```console
./chameleon fetch --browser chrome131-macos --dump https://example.com
```

**Start CDP server:**
```console
./chameleon serve --browser chrome131-macos --host 127.0.0.1 --port 9222
```

Then connect with Puppeteer:
```js
import puppeteer from 'puppeteer-core';

const browser = await puppeteer.connect({
  browserWSEndpoint: "ws://127.0.0.1:9222",
});

const context = await browser.createBrowserContext();
const page = await context.newPage();
await page.goto('https://example.com', { waitUntil: "networkidle0" });

const html = await page.content();
console.log(html);

await page.close();
await context.close();
await browser.disconnect();
```

### Option 3: Docker

```console
docker run -d --name lightpanda -p 9222:9222 chameleon-browser/chameleon-browser:nightly
```

## Available Browser Profiles

| Profile | UA Version | TLS Target | Use Case |
|---------|-----------|------------|----------|
| `chrome116` | Chrome/116 | chrome116 | Default, widest compatibility |
| `chrome131-macos` | Chrome/131 | chrome116* | macOS simulation |
| `chrome131-windows` | Chrome/131 | chrome116* | Windows simulation |
| `chrome131-linux` | Chrome/131 | chrome116* | Linux simulation |

*\* TLS target upgrade to chrome131 is on the roadmap (see [C-08 in audit report](docs/fingerprint-audit-report.md)).*

## Build from Source

### Prerequisites

- [Zig](https://ziglang.org/) 0.15.2
- [Rust](https://rust-lang.org/tools/install/) (for html5ever)
- System dependencies:

**Debian/Ubuntu:**
```bash
sudo apt install xz-utils ca-certificates pkg-config libglib2.0-dev clang make curl git
```

**macOS:**
```bash
brew install cmake
```

**Nix:**
```bash
nix develop
```

### Build

```bash
# Initialize submodules (includes curl-impersonate)
make install-submodule

# Release build
make build

# Debug build
make build-dev

# Run tests
make test
```

### V8 Snapshot (optional, improves startup)

```bash
zig build snapshot_creator -- src/snapshot.bin
zig build -Dsnapshot_path=../../snapshot.bin
```

## Project Status

This fork is in active development. The fingerprint spoofing layer is functional for basic anti-bot bypass but improvements are ongoing.

### Implemented

- [x] HTTP loader with curl-impersonate (TLS fingerprint spoofing)
- [x] HTML parser (html5ever from Servo)
- [x] DOM tree + JavaScript support (V8)
- [x] DOM APIs + Ajax (XHR/Fetch)
- [x] CDP/WebSocket server (Puppeteer/Playwright compatible)
- [x] Browser profile system (UA, screen, navigator properties)
- [x] `window.chrome` object (runtime/app/csi/loadTimes)
- [x] `navigator.webdriver = false`
- [x] Client Hints API (userAgentData)
- [x] Configurable screen/display properties
- [x] Canvas/AudioContext/WebGL stub APIs with seed-based fingerprints
- [x] RTCPeerConnection (blocks WebRTC IP leak)
- [x] BatteryManager, Permissions API
- [x] Cookies, custom HTTP headers, proxy support
- [x] Network interception
- [x] `robots.txt` support (`--obey_robots`)
- [x] V8 heap memory limits + navigation loop protection
- [x] Python binding (`pip install chameleon-browser`)

### Roadmap

- [ ] Canvas 2D: realistic pixel rendering (not just seed-based)
- [ ] AudioContext: DSP pipeline simulation
- [ ] WebGL: actual draw call → readPixels pipeline
- [ ] matchMedia(): CSS media query evaluation
- [ ] PluginArray.item() returning real Plugin objects
- [ ] Notification API stub
- [ ] fetch()/XHR standard headers (Sec-Fetch-*, Sec-CH-UA)
- [ ] HTTP header ordering matching Chrome
- [ ] Upgrade TLS target to chrome131/132
- [ ] navigator.bluetooth/usb stubs
- [ ] WebSocket Web API
- [ ] CreepJS / FingerprintJS test suite pass

## Fingerprint Benchmark Tool

Included benchmark tool to compare fingerprint quality:

```bash
python3 chameleon_benchmark.py --browser chrome116 --tls-runs 5
```

This compares curl vs. Lightpanda across multiple sites and validates TLS fingerprint stability. See [chameleon_benchmark.py](chameleon_benchmark.py) for details.

## Architecture

```
lightpanda-browser/
├── src/                    # Zig source code
│   ├── browser/            # Browser engine core
│   │   ├── Browser.zig     # Browser implementation
│   │   ├── Page.zig        # Page + HTTP header management
│   │   ├── js/             # JavaScript runtime bindings
│   │   └── webapi/         # Web API implementations (Canvas, Audio, WebGL, etc.)
│   ├── cdp/                # Chrome DevTools Protocol
│   ├── http/               # HTTP client (curl-impersonate integration)
│   └── main.zig            # Entry point
├── python/                 # Python binding package
│   ├── lightpanda/         # Python source
│   └── pyproject.toml      # pip install configuration
├── vendor/                 # Vendored dependencies
│   ├── curl/               # curl (forked with fingerprint patches)
│   ├── curl-impersonate/   # TLS fingerprint impersonation
│   ├── nghttp2/            # HTTP/2
│   ├── brotli/             # Brotli compression
│   └── zlib/               # zlib compression
├── docs/                   # Documentation
│   └── fingerprint-audit-report.md
└── tests/                  # Test suites (WPT, unit tests)
```

## Contributing

Contributions are welcome. This project is independently maintained.

For issues specific to the fingerprint enhancement features, please open an issue on [this repository](https://github.com/chameleon-browser/chameleon-browser/issues).

For issues with the core browser engine, consider also checking the [upstream project](https://github.com/lightpanda-io/browser/issues).

## License

This project inherits the [AGPL-3.0](LICENSE) license from the upstream project.

Original project: [lightpanda-io/browser](https://github.com/lightpanda-io/browser) by [Lightpanda (Selecy SAS)](https://lightpanda.io).

## Acknowledgments

- [Lightpanda](https://lightpanda.io) — the original headless browser project
- [curl-impersonate](https://github.com/lwthiker/curl-impersonate) — TLS fingerprint impersonation
- [V8](https://v8.dev/) — JavaScript engine
- [html5ever](https://github.com/servo/html5ever) — HTML parser from Servo
