"""Turn paginated GitHub release JSON on stdin into a stable-version matrix."""

import json
import re
import sys
import tomllib
from pathlib import Path


def select_versions(pages, minimum):
    versions = set()
    for releases in pages:
        for release in releases:
            if release.get("draft") or release.get("prerelease"):
                continue
            match = re.fullmatch(r"v?(\d+)\.(\d+)\.(\d+)", release["tag_name"])
            if match:
                version = tuple(map(int, match.groups()))
                if version >= minimum:
                    versions.add(version)
    if not versions:
        raise ValueError("No stable Typst releases meet the package compiler requirement")
    return [".".join(map(str, version)) for version in sorted(versions)]


def main():
    root = Path(__file__).resolve().parents[2]
    manifest = tomllib.loads((root / "typst.toml").read_text())
    minimum = tuple(map(int, manifest["package"]["compiler"].split(".")))
    versions = select_versions(json.load(sys.stdin), minimum)
    print("matrix=" + json.dumps({"typst": versions}, separators=(",", ":")))


if __name__ == "__main__":
    main()
