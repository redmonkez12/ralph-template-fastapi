"""Shared utilities for Linear API interaction."""

import json
import os
import sys
import urllib.error
import urllib.request

LINEAR_API_URL = "https://api.linear.app/graphql"


def get_api_key() -> str:
    key = os.environ.get("LINEAR_API_KEY", "").strip()
    if not key:
        print("ERROR: LINEAR_API_KEY environment variable is not set.", file=sys.stderr)
        sys.exit(1)
    return key


def get_project_name() -> str:
    name = os.environ.get("LINEAR_PROJECT_NAME", "").strip()
    if not name:
        print("ERROR: LINEAR_PROJECT_NAME environment variable is not set.", file=sys.stderr)
        sys.exit(1)
    return name


def graphql(query: str, variables: dict | None = None) -> dict:
    """Execute a GraphQL query against Linear API. Returns parsed JSON response."""
    api_key = get_api_key()
    payload = {"query": query}
    if variables:
        payload["variables"] = variables

    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        LINEAR_API_URL,
        data=data,
        headers={
            "Content-Type": "application/json",
            "Authorization": api_key,
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req) as resp:
            body = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8") if e.fp else ""
        print(f"ERROR: Linear API returned {e.code}: {error_body}", file=sys.stderr)
        sys.exit(1)

    if "errors" in body:
        errors_str = json.dumps(body["errors"], indent=2)
        print(f"ERROR: Linear GraphQL errors: {errors_str}", file=sys.stderr)
        sys.exit(1)

    return body.get("data", {})
