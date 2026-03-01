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
