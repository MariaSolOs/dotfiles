#!/usr/bin/env python3
"""Fetch failing/erroring tests for a CircleCI job URL via API v2."""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.parse
import urllib.request
import urllib.error
from typing import Any

FAIL_RESULTS = {"failure", "failed", "error", "errored"}


def parse_tests_url(url: str) -> dict[str, str]:
    parsed = urllib.parse.urlparse(url)
    parts = [urllib.parse.unquote(p) for p in parsed.path.split("/") if p]

    # Expected app URL:
    # /pipelines/{vcs}/{org}/{repo}/{pipeline}/workflows/{workflow}/jobs/{job}/tests
    try:
        pipelines_idx = parts.index("pipelines")
        vcs = parts[pipelines_idx + 1]
        org = parts[pipelines_idx + 2]
        repo = parts[pipelines_idx + 3]
        jobs_idx = parts.index("jobs")
        job_number = parts[jobs_idx + 1]
    except (ValueError, IndexError) as exc:
        raise SystemExit(f"Could not parse CircleCI tests URL: {url}") from exc

    if not job_number.isdigit():
        raise SystemExit(f"Could not parse numeric CircleCI job number from URL: {url}")

    return {
        "scheme": parsed.scheme or "https",
        "host": parsed.netloc,
        "vcs": vcs,
        "org": org,
        "repo": repo,
        "job_number": job_number,
    }


def infer_api_base(info: dict[str, str]) -> str:
    env_base = os.environ.get("CIRCLECI_API_BASE")
    if env_base:
        return env_base.rstrip("/")

    host = info["host"]
    if host in {"app.circleci.com", "circleci.com"}:
        return "https://circleci.com/api/v2"

    # CircleCI Server/Enterprise commonly serves the UI at app.<domain> and
    # the API at <domain>/api/v2. For example, app.circle.example.com maps to
    # https://circle.example.com/api/v2.
    api_host = host[4:] if host.startswith("app.") else host
    return f"{info['scheme']}://{api_host}/api/v2"


def project_slug(info: dict[str, str], cloud_short_slug: bool = False) -> str:
    vcs = info["vcs"]
    if cloud_short_slug and vcs == "github":
        vcs = "gh"
    elif cloud_short_slug and vcs == "bitbucket":
        vcs = "bb"
    return f"{vcs}/{info['org']}/{info['repo']}"


def api_get_json(url: str, token: str) -> dict[str, Any]:
    req = urllib.request.Request(
        url,
        headers={
            "Circle-Token": token,
            "Accept": "application/json",
            "User-Agent": "pi-circleci-errors-skill/1.0",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"CircleCI API request failed: HTTP {exc.code} {exc.reason}\n{body}") from exc
    except urllib.error.URLError as exc:
        raise SystemExit(f"CircleCI API request failed: {exc.reason}") from exc


def fetch_tests(api_base: str, slug: str, job_number: str, token: str) -> list[dict[str, Any]]:
    tests: list[dict[str, Any]] = []
    page_token: str | None = None

    while True:
        # CircleCI v2 expects project slugs as path segments, e.g.
        # /project/github/org/repo/{job}/tests. Encode special characters but
        # keep slashes as separators.
        encoded_slug = urllib.parse.quote(slug, safe="/")
        query = {"page-token": page_token} if page_token else {}
        url = f"{api_base}/project/{encoded_slug}/{job_number}/tests"
        if query:
            url += "?" + urllib.parse.urlencode(query)

        payload = api_get_json(url, token)
        tests.extend(payload.get("items", []))
        page_token = payload.get("next_page_token")
        if not page_token:
            return tests


def is_bad_test(test: dict[str, Any]) -> bool:
    return str(test.get("result", "")).lower() in FAIL_RESULTS


def compact_test(test: dict[str, Any]) -> dict[str, Any]:
    keys = [
        "result",
        "name",
        "classname",
        "file",
        "source",
        "message",
        "run_time",
    ]
    return {k: test.get(k) for k in keys if test.get(k) not in (None, "")}


def print_text(tests: list[dict[str, Any]], shown: list[dict[str, Any]], info: dict[str, str], slug: str) -> None:
    print(f"Project: {slug}")
    print(f"Job: {info['job_number']}")
    print(f"Tests: {len(tests)} total, {len([t for t in tests if is_bad_test(t)])} failed/error")
    print()

    if not shown:
        print("No failed or errored tests found.")
        return

    for idx, test in enumerate(shown, 1):
        name = test.get("name") or "<unnamed test>"
        classname = test.get("classname")
        result = test.get("result") or "unknown"
        print(f"{idx}. [{result}] {classname + '.' if classname else ''}{name}")
        if test.get("file"):
            print(f"   file: {test['file']}")
        if test.get("source"):
            print(f"   source: {test['source']}")
        if test.get("message"):
            msg = str(test["message"]).rstrip()
            print("   message:")
            for line in msg.splitlines():
                print(f"     {line}")
        if test.get("run_time") is not None:
            print(f"   run_time: {test['run_time']}")
        print()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("url", help="CircleCI web tests URL")
    parser.add_argument("--base-url", help="Override API base URL, e.g. https://circle.example.com/api/v2")
    parser.add_argument("--token", help="CircleCI token; defaults to CIRCLE_TOKEN/CIRCLECI_TOKEN env vars")
    parser.add_argument("--all", action="store_true", help="Show all tests instead of only failures/errors")
    parser.add_argument("--json", action="store_true", help="Emit normalized JSON")
    parser.add_argument("--cloud-short-slug", action="store_true", help="Use gh/org/repo or bb/org/repo project slugs")
    args = parser.parse_args()

    token = args.token or os.environ.get("CIRCLE_TOKEN") or os.environ.get("CIRCLECI_TOKEN")
    if not token:
        raise SystemExit("Missing CircleCI token. Set CIRCLE_TOKEN or CIRCLECI_TOKEN.")

    info = parse_tests_url(args.url)
    api_base = (args.base_url or infer_api_base(info)).rstrip("/")
    slug = project_slug(info, args.cloud_short_slug)
    tests = fetch_tests(api_base, slug, info["job_number"], token)
    shown = tests if args.all else [t for t in tests if is_bad_test(t)]
    normalized = [compact_test(t) for t in shown]

    if args.json:
        print(json.dumps({"project": slug, "job_number": info["job_number"], "total": len(tests), "shown": normalized}, indent=2))
    else:
        print_text(tests, normalized, info, slug)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
