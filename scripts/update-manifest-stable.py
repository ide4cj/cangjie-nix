#!/usr/bin/env python3
import argparse
import itertools
import logging
import urllib.request
from pathlib import Path

from util.github import *
from util.parser import *
from util.util import *
from util.writer import *

REPO_LOCAL_PATH = Path(__file__).parent.parent.resolve()

LATEST_MANIFEST_LINK_NAME = "latest.nix"
MANIFESTS_SDK_STABLE_PATH = Path(REPO_LOCAL_PATH, "manifests/sdk/stable")

SUPPORTED_PLATFORMS = {"linux": ["x64", "aarch64"], "mac": ["aarch64"]}

logger = logging.getLogger(__name__)


def setup_log():
    class LogFormatter(logging.Formatter):
        def formatMessage(self, record):
            record.levelname = f"[{record.levelname}]"
            return super().formatMessage(record)

    handler = logging.StreamHandler()
    handler.setFormatter(LogFormatter())
    logger.addHandler(handler)
    logging.basicConfig(
        filename="scripts/update-manifest-nightly.log",
        format="%(asctime)s %(levelname)-8s %(name)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        level=logging.DEBUG,  # TODO: change to INFO
    )

def is_asset_supported(system: str, arch: str) -> bool:
    if not system in SUPPORTED_PLATFORMS:
        return False
    return arch in SUPPORTED_PLATFORMS[system]

def get_manifest_name(version: str) -> str:
    return version + ".nix"

def create_sdk_manifest(assets, version) -> Path | None:
    assets = [ asset for asset in assets if is_asset_supported(system=asset["system"], arch=asset["arch"]) ]
    for asset in assets:
        logger.debug(
            "Fetching asset %s under '%s' version",
            f"sdk-{asset["system"]}-{asset["arch"]}",
            version["value"],
        )
    return write_manifest(assets, version)

def commit_manifest(manifest: Path | None, filename: str, dir: Path, dry_run: bool = False) -> Path | None:
    if manifest is None: return
    new_path = Path(dir, filename)
    if dry_run:
        print(new_path)
        print(manifest.read_text())
        return manifest

    manifest.move(new_path)
    return new_path

parser = argparse.ArgumentParser(
    prog="update-manifest-nightly",
    description="fetches latest releases from upstream and updates manifests",
)
parser.add_argument("--dry-run", action="store_true", help="do not create manifests in local repo")
parser.add_argument("--url", type=str, help="URL to js file where assets are located at cangjie-lang")
        
def main():
    setup_log()
    args = parser.parse_args()
    if args.dry_run:
        logger.info("Runing in dry-run mode")

    file = urllib.request.urlopen(args.url)
    sdk_assets = parse_sdk_stable_assets(file.read().decode())
    print("SDK assets!")
    print(sdk_assets)
    sdk_assets = itertools.groupby(sdk_assets, lambda asset: asset["version"])

    for version, assets in sdk_assets:
        sdk_manifest = create_sdk_manifest(assets=assets, version=parse_stable_version(version))
        sdk_manifest = commit_manifest(sdk_manifest, get_manifest_name(version), MANIFESTS_SDK_STABLE_PATH, dry_run=args.dry_run)

if __name__ == "__main__":
    main()
