# AI Agent Workflow Guide for Chameleon Browser

This repository contains the source code for **Chameleon Browser** (an enhanced fingerprint spoofing fork of Lightpanda). 

**CRITICAL MANDATE FOR ALL AI AGENTS**: You must strictly adhere to the following workflow rules. Failure to do so will result in broken builds, lost context, or a corrupted main branch.

---

## 1. Branching & PR Strategy (DO NOT DEVELOP ON MAIN)

- **Never write code directly to the `main` branch.**
- Before writing any code, you must create a new branch:
  ```bash
  git checkout -b <type>/<short-description>
  ```
  *(e.g., `feat/canvas-fingerprint`, `fix/tls-hash-mismatch`, `docs/update-readme`)*
- When your work is complete, tested, and formatted:
  1. Add and commit your changes (`git commit -m "feat: your message"`).
  2. Push your branch to the remote (`git push origin <branch-name>`).
  3. Create a Pull Request using the `gh` CLI:
     ```bash
     gh pr create --title "feat: descriptive title" --body "Detailed explanation of changes."
     ```
- Let the CI (GitHub Actions) run. Do not merge your own PR unless explicitly requested by the user.

## 2. Core Project Structure

You are working with a hybrid codebase (Zig + C + Rust + Python):
- `src/`: Main Zig source code for the browser engine.
- `vendor/`: Git submodules (curl-impersonate, brotli, nghttp2, zlib). **Never modify vendored files directly unless you are patching them and committing to their respective submodule repositories.**
- `python/`: Python binding package. This provides a Playwright-compatible wrapper for the Chameleon executable.
- `build.zig`: The primary build system script.

## 3. Build & Test Procedures

Before committing code or submitting a PR, verify your changes compile and tests pass.

### Zig Core (Browser Engine)
- **Format Code:** `zig fmt src/ build.zig` (Must run before commit)
- **Debug Build:** `make build-dev` (Outputs to `./zig-out/bin/chameleon`)
- **Release Build:** `make build`
- **Unit Tests:** `make test`

### Python Binding
- The Python package resides in the `python/` directory.
- It uses `pyproject.toml`.
- Any changes to `python/chameleon/` should be tested. If the user hasn't specified tests, at least verify the package builds:
  ```bash
  cd python
  python3 -m venv venv
  source venv/bin/activate
  pip install build twine playwright
  python -m build
  twine check dist/*
  deactivate
  ```

## 4. GitHub Actions (CI/CD)

- **cloud-build.yml:** The primary source of truth for build validation. Triggered on push to `main` and PRs. It builds the `chameleon` binary.
- **pypi-publish.yml:** Automatically publishes the Python package in `python/` to PyPI when a GitHub Release is created. **Do not attempt to upload to PyPI manually.**

### Using `gh` CLI for CI Validation
Always verify the CI status of your PRs:
```bash
gh pr status
gh run list --branch <your-branch> --limit 3
```

## 5. Coding Conventions

- **Zig:** Use strictly Zig `0.15.2`. Adhere to idiomatic Zig error handling and memory allocation patterns.
- **Python:** Use Python 3.8+ typing. Follow PEP 8 (use `black` / `ruff` if available).
- **Fingerprinting Focus:** Any new feature must consider its impact on browser fingerprinting. Do not expose internal APIs or variables that leak the headless nature of the browser.

---

## 6. Basic Usage Reference

After building (`make build-dev` or `make build`), the binary is at `./zig-out/bin/chameleon`.

### General Syntax

```
chameleon <command> [options] [URL]
```

Available commands: `fetch`, `serve`, `help`, `version`.

If no command is given, the binary infers the mode from context:
- No arguments → defaults to `serve`
- A bare URL → defaults to `fetch`
- Presence of `--dump`, `--strip_mode`, etc. → infers `fetch`
- Presence of `--host`, `--port`, etc. → infers `serve`

---

### `fetch` — Single Page Fetch

Navigates to a URL, executes JavaScript, waits for the page to load, and optionally dumps the rendered DOM to stdout.

```bash
chameleon fetch [options] <URL>
```

**Fetch-specific options:**

| Flag | Description | Default |
|------|-------------|---------|
| `--dump` | Dumps the rendered document HTML to stdout | `false` |
| `--strip_mode <modes>` | Comma-separated tag groups to strip from dump: `js`, `ui`, `css`, `full` | none |
| `--with_base` | Adds a `<base>` tag in the dump output | `false` |
| `--noscript` | **Deprecated.** Equivalent to `--strip_mode js`. | `false` |

**Strip mode values:**
- `js` — removes `<script>` and `<link as=script rel=preload>` elements
- `css` — removes `<style>` and `<link rel=stylesheet>` elements
- `ui` — removes `<img>`, `<picture>`, `<video>`, css, and svg elements
- `full` — combines js + ui + css

**Examples:**

```bash
# Basic fetch with DOM dump
./zig-out/bin/chameleon fetch --dump https://example.com/

# Fetch and strip all JS/CSS/UI tags, add base tag
./zig-out/bin/chameleon fetch --dump --strip_mode full --with_base https://example.com

# Fetch with a specific browser fingerprint
./zig-out/bin/chameleon fetch --dump --browser chrome116 https://example.com
```

---

### `serve` — CDP WebSocket Server

Starts a persistent WebSocket server speaking the Chrome DevTools Protocol (CDP). Clients like Puppeteer, Playwright, or chromedp can connect to it.

```bash
chameleon serve [options]
```

**Serve-specific options:**

| Flag | Description | Default |
|------|-------------|---------|
| `--host <addr>` | IP address to bind to | `127.0.0.1` |
| `--port <port>` | TCP port for the CDP server | `9222` |
| `--timeout <seconds>` | Inactivity timeout for clients | `10` |
| `--max_connections <n>` | Max simultaneous CDP connections | `16` |
| `--max_tabs <n>` | Max tabs per CDP connection | `8` |
| `--max_tab_memory <bytes>` | Max memory per tab | `536870912` (512 MB) |
| `--max_pending_connections <n>` | Max pending connections in accept queue | `128` |

**Examples:**

```bash
# Start on default address (127.0.0.1:9222)
./zig-out/bin/chameleon serve

# Custom fingerprint and port
./zig-out/bin/chameleon serve --browser chrome116 --host 0.0.0.0 --port 8080

# With tuned limits and longer timeout
./zig-out/bin/chameleon serve --timeout 60 --max_connections 32 --max_tabs 4
```

---

### `help` / `version`

```bash
chameleon help       # Print full usage text
chameleon version    # Print build git commit hash
```

---

### Common Options (Shared by `fetch` and `serve`)

| Flag | Description | Default |
|------|-------------|---------|
| `--browser <fingerprint>` | Browser fingerprint for TLS/HTTP emulation | Random chrome/edge |
| `--insecure_disable_tls_host_verification` | Disables TLS host verification | `false` |
| `--obey_robots` | Fetches and obeys robots.txt | `false` |
| `--http_proxy <url>` | HTTP proxy (supports `user:pass` basic auth) | none |
| `--proxy_bearer_token <token>` | Bearer token for proxy auth | none |
| `--http_max_concurrent <n>` | Max concurrent HTTP requests | `10` |
| `--http_max_host_open <n>` | Max open connections per host:port | `4` |
| `--http_connect_timeout <ms>` | Connection establishment timeout (0 = none) | `0` |
| `--http_timeout <ms>` | Max transfer time (0 = none) | `10000` |
| `--http_max_response_size <bytes>` | Max response size per request | no limit |
| `--log_level <level>` | `debug`, `info`, `warn`, `error`, `fatal` | Debug: `info`; Release: `warn` |
| `--log_format <fmt>` | `pretty` or `logfmt` | Debug: `pretty`; Release: `logfmt` |
| `--log_filter_scopes <scopes>` | Comma-separated scope filters (debug builds only) | none |
| `--user_agent_suffix <suffix>` | Appended to the User-Agent string | none |

---

### Supported Browser Fingerprints

| ID | Browser Emulated |
|----|-----------------|
| `chrome99` | Chrome 99.0 (Windows) |
| `chrome100` | Chrome 100.0 (Windows) |
| `chrome101` | Chrome 101.0 (Windows) |
| `chrome104` | Chrome 104.0 (Windows) |
| `chrome107` | Chrome 107.0 (Windows) |
| `chrome110` | Chrome 110.0 (Windows) |
| `chrome116` | Chrome 116.0 (Windows) |
| `chrome99_android` | Chrome 99.0 (Android Pixel 6) |
| `edge99` | Edge 99.0 (Windows) |
| `edge101` | Edge 101.0 (Windows) |
| `safari15_3` | Safari 15.3 (macOS) |
| `safari15_5` | Safari 15.5 (macOS) |

If `--browser` is omitted, a random fingerprint is selected at startup from the chrome/edge set (excluding safari).

---

### Environment Variables

| Variable | Description |
|----------|-------------|
| `LIGHTPANDA_DISABLE_TELEMETRY=true` | Disables telemetry reporting |
| `CHAMELEON_BIN` | Override path to the chameleon binary (used by Python wrapper) |

---

### Quick Reference: Common Workflows

```bash
# 1. Build the binary
make build-dev

# 2. Fetch a page and dump DOM to stdout
./zig-out/bin/chameleon fetch --dump https://example.com/

# 3. Fetch a page, strip JS, dump clean HTML
./zig-out/bin/chameleon fetch --dump --strip_mode js https://example.com/

# 4. Start CDP server for Playwright/Puppeteer
./zig-out/bin/chameleon serve --host 127.0.0.1 --port 9222

# 5. Start with proxy and verbose logging
./zig-out/bin/chameleon serve --http_proxy http://user:pass@proxy:8080 --log_level debug

# 6. Run unit tests
make test

# 7. Run end-to-end tests
make end2end

# 8. Use from Python
#    pip install chameleon-browser
from chameleon import ChameleonBrowser
browser = ChameleonBrowser(profile="chrome116")
with browser.connect() as pw_browser:
    page = pw_browser.new_context().new_page()
    page.goto("https://example.com")
```
