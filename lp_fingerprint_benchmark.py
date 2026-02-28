#!/usr/bin/env python3
"""Benchmark curl vs Lightpanda and fingerprint stability.

Usage example:
  python3 lp_fingerprint_benchmark.py --browser chrome116 --tls-runs 5
"""

from __future__ import annotations

import argparse
import html
import json
import re
import subprocess
import time
from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Tuple


DEFAULT_SITES: List[Tuple[str, str]] = [
    ("Product Hunt", "https://www.producthunt.com/"),
    ("npm Home", "https://www.npmjs.com/"),
    ("npm react", "https://www.npmjs.com/package/react"),
    ("Canva", "https://www.canva.com/"),
    ("Upwork", "https://www.upwork.com/"),
    ("Reddit", "https://www.reddit.com/"),
    ("YouTube", "https://www.youtube.com/"),
    ("Quora", "https://www.quora.com/"),
]


CHALLENGE_PATTERNS: List[Tuple[str, str]] = [
    ("cf_js_challenge", r"enable javascript and cookies to continue"),
    ("just_a_moment", r"just a moment"),
    ("captcha", r"captcha|recaptcha|hcaptcha"),
    ("blocked", r"you\'ve been blocked|access denied|forbidden|are you a robot"),
    ("security_verification", r"security verification|checking your browser"),
]


@dataclass
class FetchResult:
    engine: str
    returncode: Optional[int]
    title: str
    text_len: int
    html_len: int
    classification: str
    challenge_hit: Optional[str]
    preview: str
    error: Optional[str]
    elapsed_ms: int


def run_command(command: List[str], timeout_sec: int) -> Tuple[Optional[int], str, str, Optional[str], int]:
    start = time.time()
    try:
        proc = subprocess.run(command, capture_output=True, text=True, timeout=timeout_sec)
        elapsed_ms = int((time.time() - start) * 1000)
        return proc.returncode, proc.stdout or "", proc.stderr or "", None, elapsed_ms
    except subprocess.TimeoutExpired:
        elapsed_ms = int((time.time() - start) * 1000)
        return None, "", "", f"timeout after {timeout_sec}s", elapsed_ms
    except Exception as exc:  # noqa: BLE001
        elapsed_ms = int((time.time() - start) * 1000)
        return None, "", "", str(exc), elapsed_ms


def extract_title(html_text: str) -> str:
    match = re.search(r"<title[^>]*>(.*?)</title>", html_text, flags=re.IGNORECASE | re.DOTALL)
    if not match:
        return ""
    return re.sub(r"\s+", " ", match.group(1)).strip()


def visible_text(html_text: str) -> str:
    text = re.sub(r"(?is)<script.*?>.*?</script>", " ", html_text)
    text = re.sub(r"(?is)<style.*?>.*?</style>", " ", text)
    text = re.sub(r"(?is)<[^>]+>", " ", text)
    text = html.unescape(text)
    return re.sub(r"\s+", " ", text).strip()


def classify_content(text: str, title: str) -> Tuple[str, Optional[str]]:
    low = f"{title} {text}".lower()
    for name, pattern in CHALLENGE_PATTERNS:
        if re.search(pattern, low, flags=re.IGNORECASE):
            return "blocked_or_challenge", name
    if len(text) == 0:
        return "empty", None
    if len(text) < 80:
        return "thin_content", None
    return "content", None


def fetch_with_curl(url: str, timeout_sec: int) -> FetchResult:
    command = ["curl", "-L", "-sS", "--max-time", str(timeout_sec), url]
    returncode, stdout, _stderr, error, elapsed_ms = run_command(command, timeout_sec + 5)

    if error:
        return FetchResult("curl", returncode, "", 0, 0, "error", None, "", error, elapsed_ms)

    title = extract_title(stdout)
    text = visible_text(stdout)
    classification, challenge = classify_content(text, title)
    return FetchResult(
        "curl",
        returncode,
        title,
        len(text),
        len(stdout),
        classification,
        challenge,
        text[:160],
        None,
        elapsed_ms,
    )


def fetch_with_lightpanda(url: str, lightpanda_bin: str, browser: Optional[str], timeout_sec: int) -> FetchResult:
    command = [
        lightpanda_bin,
        "fetch",
        "--dump",
        "--log_level",
        "error",
        "--http_timeout",
        str(timeout_sec * 1000),
    ]
    if browser:
        command += ["--browser", browser]
    command.append(url)

    returncode, stdout, _stderr, error, elapsed_ms = run_command(command, timeout_sec + 30)
    if error:
        return FetchResult("lightpanda", returncode, "", 0, 0, "error", None, "", error, elapsed_ms)

    title = extract_title(stdout)
    text = visible_text(stdout)
    classification, challenge = classify_content(text, title)
    return FetchResult(
        "lightpanda",
        returncode,
        title,
        len(text),
        len(stdout),
        classification,
        challenge,
        text[:160],
        None,
        elapsed_ms,
    )


def parse_tls_api_payload(raw: str) -> Dict[str, Any]:
    pre_match = re.search(r"<pre>(.*?)</pre>", raw, flags=re.DOTALL | re.IGNORECASE)
    payload = pre_match.group(1) if pre_match else raw
    payload = payload.strip()

    try:
        data = json.loads(payload)
    except json.JSONDecodeError:
        return {
            "ip": None,
            "user_agent": None,
            "ja3_hash": None,
            "ja4": None,
            "akamai_fingerprint_hash": None,
            "parse_error": "failed to parse tls.peet.ws response",
        }

    tls_data = data.get("tls", {}) if isinstance(data, dict) else {}
    http2_data = data.get("http2", {}) if isinstance(data, dict) else {}
    return {
        "ip": data.get("ip"),
        "user_agent": data.get("user_agent"),
        "ja3_hash": tls_data.get("ja3_hash"),
        "ja4": tls_data.get("ja4"),
        "akamai_fingerprint_hash": http2_data.get("akamai_fingerprint_hash"),
        "parse_error": None,
    }


def run_tls_probe(lightpanda_bin: str, browser: Optional[str], runs: int, timeout_sec: int) -> Dict[str, Any]:
    records: List[Dict[str, Any]] = []
    errors: List[str] = []

    for _ in range(runs):
        command = [
            lightpanda_bin,
            "fetch",
            "--dump",
            "--log_level",
            "error",
            "--http_timeout",
            str(timeout_sec * 1000),
        ]
        if browser:
            command += ["--browser", browser]
        command.append("https://tls.peet.ws/api/all")

        returncode, stdout, stderr, error, _elapsed_ms = run_command(command, timeout_sec + 30)
        if error:
            errors.append(error)
            continue
        if returncode is None or returncode != 0:
            errors.append(f"non-zero returncode: {returncode}, stderr: {stderr[:200]}")
            continue

        parsed = parse_tls_api_payload(stdout)
        if parsed.get("parse_error"):
            errors.append(str(parsed.get("parse_error")))
            continue
        records.append(parsed)

    uas = [v for r in records if isinstance(r.get("user_agent"), str) for v in [r["user_agent"]]]
    ips = [v for r in records if isinstance(r.get("ip"), str) for v in [r["ip"]]]
    ja3s = [v for r in records if isinstance(r.get("ja3_hash"), str) for v in [r["ja3_hash"]]]
    ja4s = [v for r in records if isinstance(r.get("ja4"), str) for v in [r["ja4"]]]
    aks = [v for r in records if isinstance(r.get("akamai_fingerprint_hash"), str) for v in [r["akamai_fingerprint_hash"]]]

    return {
        "requested_runs": runs,
        "successful_runs": len(records),
        "errors": errors,
        "unique_ip": sorted(set(ips)),
        "unique_user_agent": sorted(set(uas)),
        "unique_ja3_hash": sorted(set(ja3s)),
        "unique_ja4": sorted(set(ja4s)),
        "unique_akamai_hash": sorted(set(aks)),
        "records": records,
    }


def compare_value(curl_result: FetchResult, lp_result: FetchResult) -> str:
    curl_is_blocked = curl_result.classification == "blocked_or_challenge"
    lp_is_blocked = lp_result.classification == "blocked_or_challenge"

    if curl_is_blocked and lp_result.classification == "content":
        return "lp_advantage"
    if curl_result.classification == "content" and lp_is_blocked:
        return "curl_advantage"
    if curl_is_blocked and lp_is_blocked:
        return "both_blocked"
    if curl_result.classification == "content" and lp_result.classification == "content":
        return "both_content"
    return "mixed"


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="curl vs Lightpanda benchmark + fingerprint stability probe")
    parser.add_argument("--lightpanda", default="./zig-out/bin/lightpanda", help="path to lightpanda binary")
    parser.add_argument("--browser", default="chrome116", help="fixed browser profile for Lightpanda")
    parser.add_argument("--timeout", type=int, default=35, help="request timeout in seconds")
    parser.add_argument("--tls-runs", type=int, default=5, help="number of tls.peet.ws probe runs")
    parser.add_argument("--skip-random-probe", action="store_true", help="skip probe without fixed --browser")
    parser.add_argument("--json-out", default="", help="write full report to json file")
    return parser


def main() -> int:
    args = build_argument_parser().parse_args()

    site_rows: List[Dict[str, Any]] = []
    score = {
        "lp_advantage": 0,
        "curl_advantage": 0,
        "both_blocked": 0,
        "both_content": 0,
        "mixed": 0,
    }

    for site_name, url in DEFAULT_SITES:
        curl_result = fetch_with_curl(url, timeout_sec=args.timeout)
        lp_result = fetch_with_lightpanda(url, lightpanda_bin=args.lightpanda, browser=args.browser, timeout_sec=args.timeout)
        value = compare_value(curl_result, lp_result)
        score[value] += 1

        site_rows.append(
            {
                "site": site_name,
                "url": url,
                "value": value,
                "curl": curl_result.__dict__,
                "lightpanda": lp_result.__dict__,
            }
        )

    fixed_probe = run_tls_probe(args.lightpanda, args.browser, args.tls_runs, timeout_sec=args.timeout)
    random_probe = None
    if not args.skip_random_probe:
        random_probe = run_tls_probe(args.lightpanda, None, args.tls_runs, timeout_sec=args.timeout)

    report = {
        "config": {
            "lightpanda": args.lightpanda,
            "browser": args.browser,
            "timeout": args.timeout,
            "tls_runs": args.tls_runs,
            "sites": len(DEFAULT_SITES),
        },
        "score": score,
        "sites": site_rows,
        "tls_probe_fixed": fixed_probe,
        "tls_probe_random": random_probe,
    }

    if args.json_out:
        with open(args.json_out, "w", encoding="utf-8") as f:
            json.dump(report, f, ensure_ascii=False, indent=2)

    print("=== Value Score ===")
    print(json.dumps(score, ensure_ascii=False, indent=2))

    print("\n=== Site Verdicts ===")
    for row in site_rows:
        curl_cls = row["curl"]["classification"]
        lp_cls = row["lightpanda"]["classification"]
        print(f"- {row['site']}: {row['value']} | curl={curl_cls} | lp={lp_cls}")

    print("\n=== TLS Probe (fixed browser) ===")
    print(
        json.dumps(
            {
                "successful_runs": fixed_probe["successful_runs"],
                "unique_ip": len(fixed_probe["unique_ip"]),
                "unique_user_agent": len(fixed_probe["unique_user_agent"]),
                "unique_ja4": len(fixed_probe["unique_ja4"]),
                "unique_akamai_hash": len(fixed_probe["unique_akamai_hash"]),
                "errors": fixed_probe["errors"],
            },
            ensure_ascii=False,
            indent=2,
        )
    )

    if random_probe is not None:
        print("\n=== TLS Probe (random profile, no --browser) ===")
        print(
            json.dumps(
                {
                    "successful_runs": random_probe["successful_runs"],
                    "unique_ip": len(random_probe["unique_ip"]),
                    "unique_user_agent": len(random_probe["unique_user_agent"]),
                    "unique_ja4": len(random_probe["unique_ja4"]),
                    "unique_akamai_hash": len(random_probe["unique_akamai_hash"]),
                    "errors": random_probe["errors"],
                },
                ensure_ascii=False,
                indent=2,
            )
        )

    if args.json_out:
        print(f"\nFull report written to: {args.json_out}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
