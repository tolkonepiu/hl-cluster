#!/usr/bin/env python3
import argparse
import socket
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from urllib.parse import urlparse


@dataclass(frozen=True)
class Target:
    name: str
    url: str
    ok_statuses: set[int]
    required: bool = True


TARGETS = [
    # Main YouTube connectivity check.
    Target(
        name="youtube-generate-204",
        url="https://www.youtube.com/generate_204",
        ok_statuses={204},
        required=True,
    ),

    # Used by pyytlounge thumbnails.
    Target(
        name="youtube-thumbnail",
        url="https://img.youtube.com/vi/dQw4w9WgXcQ/0.jpg",
        ok_statuses={200},
        required=True,
    ),

    # Warms www.googleapis.com, used by pyytlounge captions API.
    Target(
        name="youtube-api-discovery",
        url="https://www.googleapis.com/discovery/v1/apis/youtube/v3/rest",
        ok_statuses={200},
        required=True,
    ),
]


def resolve_host(host: str) -> list[str]:
    """
    Forces normal system DNS resolution.
    """
    infos = socket.getaddrinfo(host, 443, proto=socket.IPPROTO_TCP)
    return sorted({str(info[4][0]) for info in infos})


def request_url(target: Target, timeout: int) -> tuple[bool, str]:
    request = urllib.request.Request(
        target.url,
        headers={
            "User-Agent": "Mozilla/5.0 youtube-warmup/1.0",
            "Cache-Control": "no-cache",
        },
        method="GET",
    )

    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            status = response.status

        if status in target.ok_statuses:
            return True, f"status {status}"

        return False, f"unexpected status {status}"

    except urllib.error.HTTPError as error:
        # HTTPError still means DNS + TCP + TLS + HTTP reached the host.
        # But for these chosen URLs we expect stable success statuses,
        # so treat unexpected HTTP errors as failed checks.
        if error.code in target.ok_statuses:
            return True, f"status {error.code}"

        return False, f"http error {error.code}"

    except Exception as error:
        return False, f"{type(error).__name__}: {error}"


def warmup_target(target: Target, timeout: int) -> bool:
    host = urlparse(target.url).hostname
    if not host:
        print(f"{target.name}: invalid URL: {target.url}")
        return False

    try:
        ips = resolve_host(host)
        print(f"{target.name}: resolved {host} -> {', '.join(ips) if ips else 'no addresses'}")
    except Exception as error:
        print(f"{target.name}: DNS failed for {host}: {type(error).__name__}: {error}")
        return False

    ok, message = request_url(target, timeout=timeout)
    print(f"{target.name}: {message}")

    return ok


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Strict YouTube connectivity check for iSponsorBlockTV.")
    parser.add_argument("--attempts", type=int, default=10)
    parser.add_argument("--sleep", type=int, default=10)
    parser.add_argument("--timeout", type=int, default=10)
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    for attempt in range(1, args.attempts + 1):
        print(f"Attempt {attempt}")

        results = []
        for target in TARGETS:
            ok = warmup_target(target, timeout=args.timeout)
            results.append((target, ok))

        required_failed = [
            target.name
            for target, ok in results
            if target.required and not ok
        ]

        if not required_failed:
            print(f"YouTube is ready on attempt {attempt}")
            return 0

        print(f"YouTube is not ready on attempt {attempt}; failed: {', '.join(required_failed)}")
        if attempt < args.attempts:
            time.sleep(args.sleep)

    raise SystemExit("YouTube did not become ready")


if __name__ == "__main__":
    raise SystemExit(main())
