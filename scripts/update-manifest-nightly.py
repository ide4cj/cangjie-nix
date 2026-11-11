#!/usr/bin/env python3
import argparse
import datetime
import logging
import os
import re
from datetime import date
from pathlib import Path

from util.github import *
from util.parser import *
from util.util import *
from util.writer import *

REPO_NAME = os.environ["UPSTREAM_REPO_NAME"]
REPO_OWNER = os.environ["UPSTREAM_REPO_OWNER"]
ONLY_LATEST_VERSION = True
REPO_LOCAL_PATH = Path(__file__).parent.parent.resolve()

TODAY = date.today()
LATEST_MANIFEST_LINK_NAME = "latest.nix"
MANIFESTS_SDK_NIGHTLY_PATH = Path(REPO_LOCAL_PATH, "manifests/sdk/nightly")
MANIFESTS_STDX_NIGHTLY_PATH = Path(REPO_LOCAL_PATH, "manifests/stdx/nightly")

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

def get_manifest_name(date: date) -> str:
    return date.strftime(DATE_FORMAT) + ".nix"

def get_latest_manifest_ref_date(manifest_ref_path: Path) -> date | None:
    if not manifest_ref_path.exists(): return None
    latest_ref_contents = manifest_ref_path.read_text()
    latest_ref_contents = re.compile(r'"(.*)"').match(latest_ref_contents)
    if latest_ref_contents is None:
        return None
    latest_ref_contents = latest_ref_contents.group(1)
    latest_date = datetime.datetime.strptime(latest_ref_contents, DATE_FORMAT).date()
    return latest_date

def has_latest_manifest(
    nightly_manifests_path: Path,
    latest_manifest_filename: str
) -> bool:
    today_manifest = Path(nightly_manifests_path, get_manifest_name(TODAY))
    if not today_manifest.exists():
        logger.debug(f"No {get_manifest_name(TODAY)} manifest was found locally at path {today_manifest}")
        return False

    latest_ref_manifest = Path(nightly_manifests_path, latest_manifest_filename)
    if not latest_ref_manifest.exists():
        logger.debug(f"No latest manifest reference was found locally at path {latest_ref_manifest}")
        return False

    latest_date_in_repo = get_latest_manifest_ref_date(latest_ref_manifest)
    if latest_date_in_repo is None:
        logger.debug(f"No date was parsed in latest manifest reference at path {latest_ref_manifest}")
        return False
    logger.debug(f"Latest manifest reference locally available is: {latest_date_in_repo.strftime(DATE_FORMAT)}")
    if latest_date_in_repo < TODAY:
        logger.debug("Latest date in manifest reference is outdated, upstream fetch is ongoning")
        return False
    return True


def need_sdk_update(gh: Gh) -> bool:
    if has_latest_manifest(MANIFESTS_SDK_NIGHTLY_PATH, LATEST_MANIFEST_LINK_NAME):
        return False

    latest_release = gh.release_latest_tag()
    latest_date_upstream = parse_tag_into_date(latest_release)
    
    if latest_date_upstream is None:
        logger.fatal("Cannot parse latest upstream sdk version")
        return False
    latest_date_locally = get_latest_manifest_ref_date(Path(MANIFESTS_SDK_NIGHTLY_PATH, LATEST_MANIFEST_LINK_NAME))
    if latest_date_locally is None:
        return True

    return latest_date_locally < latest_date_upstream

def need_stdx_update(gh: Gh) -> bool:
    if has_latest_manifest(MANIFESTS_STDX_NIGHTLY_PATH, LATEST_MANIFEST_LINK_NAME):
        return False

    latest_release = gh.release_latest_tag()
    latest_date_upstream = parse_tag_into_date(latest_release)
    
    if latest_date_upstream is None:
        logger.fatal("Cannot parse latest upstream stdx version")
        return False
    latest_date_locally = get_latest_manifest_ref_date(Path(MANIFESTS_STDX_NIGHTLY_PATH, LATEST_MANIFEST_LINK_NAME))
    if latest_date_locally is None:
        return True

    return latest_date_locally < latest_date_upstream

def create_sdk_manifest(raw_assets, version) -> Path | None:
    assets = [ parse_sdk_asset(raw_asset) for raw_asset in raw_assets ]
    assets = [ asset for asset in assets if asset is not None ]
    assets = [ asset for asset in assets if is_asset_supported(system=asset["system"], arch=asset["arch"]) ]
    for asset in assets:
        logger.debug(
            "Fetching asset %s under '%s' version",
            f"sdk-{asset["system"]}-{asset["arch"]}",
            version["value"],
        )
    return write_manifest(assets, version)
    
def create_stdx_manifest(raw_assets, version) -> Path | None:
    assets = [ parse_stdx_asset(raw_asset) for raw_asset in raw_assets ]
    assets = [ asset for asset in assets if asset is not None ]
    assets = [ asset for asset in assets if is_asset_supported(system=asset["system"], arch=asset["arch"]) ]
    for asset in assets:
        logger.debug(
            "Fetching asset %s under '%s' version",
            f"stdx-{asset["system"]}-{asset["arch"]}",
            version["value"],
        )
    return write_manifest(assets, version)

def commit_manifest(manifest: Path | None, filename: str, dir: Path, dry_run: bool = False) -> Path | None:
    if manifest is None: return
    if dry_run:
        print(filename)
        print(manifest.read_text())
        return manifest

    new_path = Path(dir, filename)
    manifest.move(new_path)
    return new_path

def commit_latest_manifest_link(latest_version: Path | None, dir: Path, dry_run: bool = False) -> Path | None:
    if latest_version is None: return
    if dry_run:
        print(LATEST_MANIFEST_LINK_NAME)
        print(latest_version.read_text())
        return latest_version

    link_path = Path(dir, LATEST_MANIFEST_LINK_NAME)
    link_path.symlink_to(latest_version)
    return link_path

parser = argparse.ArgumentParser(
    prog="update-manifest-nightly",
    description="fetches latest releases from upstream and updates manifests",
)
parser.add_argument("--dry-run", action="store_true", help="do not create manifests in local repo")

def main():
    setup_log()
    args = parser.parse_args()
    if args.dry_run:
        logger.info("Runing in dry-run mode")
    
    gh = GhCached(REPO_OWNER, REPO_NAME, REPO_LOCAL_PATH)

    need_update = False

    if need_sdk_update(gh):
        logger.info("sdk manifest is going to be updated")
        need_update = True
    else:
        logger.info("Latest sdk aready installed")

    if need_stdx_update(gh):
        logger.info("stdx manifest is going to be updated")
        need_update = True
    else:
        logger.info("Latest stdx aready installed")

    if not need_update:
        return

    version = parse_nightly_version(gh.release_latest_tag())
    sdk_manifest = create_sdk_manifest(raw_assets=gh.release_assets(gh.release_latest_tag()), version=version)
    sdk_manifest = commit_manifest(sdk_manifest, get_manifest_name(TODAY), MANIFESTS_SDK_NIGHTLY_PATH, dry_run=args.dry_run)
    commit_latest_manifest_link(sdk_manifest, MANIFESTS_SDK_NIGHTLY_PATH, dry_run=args.dry_run)
    
    stdx_manifest = create_stdx_manifest(raw_assets=gh.release_assets(gh.release_latest_tag()), version=version)
    stdx_manifest = commit_manifest(stdx_manifest, get_manifest_name(TODAY), MANIFESTS_STDX_NIGHTLY_PATH, dry_run=args.dry_run)
    commit_latest_manifest_link(stdx_manifest, MANIFESTS_STDX_NIGHTLY_PATH, dry_run=args.dry_run)

if __name__ == "__main__":
    main()
