#!/usr/bin/env python3
import argparse
import datetime
import logging
import os
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
    if not Path(manifest_ref_path.parent, manifest_ref_path.readlink()).exists(): return None
    latest_file_version = manifest_ref_path.readlink().name.removesuffix(".nix")
    latest_date = datetime.datetime.strptime(latest_file_version, DATE_FORMAT).date()
    return latest_date
    
def has_manifest(nightly_manifests_path: Path, date: date = TODAY) -> bool:
    manifest = Path(nightly_manifests_path, get_manifest_name(date))
    if not manifest.exists():
        logger.debug(f"No {get_manifest_name(date)} manifest was found locally at {nightly_manifests_path}")
        return False

    return not need_update_latest_ref(date, nightly_manifests_path)

def need_update(nightly_manifests_path: Path, gh: Gh) -> bool:
    if has_manifest(nightly_manifests_path):
        return False

    latest_release = gh.release_latest_tag()
    latest_date_upstream = parse_tag_into_date(latest_release)
    
    if latest_date_upstream is None:
        logger.fatal("Cannot parse latest upstream sdk version")
        return False
    latest_date_locally = get_latest_manifest_ref_date(Path(nightly_manifests_path, LATEST_MANIFEST_LINK_NAME))
    if latest_date_locally is None:
        return True

    return latest_date_locally < latest_date_upstream

def need_update_latest_ref(new_date: date, nightly_manifests_path: Path) -> bool:
    latest_ref_manifest = Path(nightly_manifests_path, LATEST_MANIFEST_LINK_NAME)
    if not latest_ref_manifest.exists():
        logger.debug(f"No latest manifest link was found locally at path {latest_ref_manifest}")
        return False

    latest_date_in_repo = get_latest_manifest_ref_date(latest_ref_manifest)
    if latest_date_in_repo is None:
        logger.debug(f"Latest manifest link does not point to any valid manifest; link at: {latest_ref_manifest}")
        return False

    return latest_date_in_repo < new_date

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
    new_path = Path(dir, filename)
    if dry_run:
        print(new_path)
        print(manifest.read_text())
        return manifest

    manifest.move(new_path)
    return new_path

def commit_latest_manifest_link(latest_version: Path | None, dir: Path, dry_run: bool = False) -> Path | None:
    if latest_version is None: return
    link_path = Path(dir, LATEST_MANIFEST_LINK_NAME)
    if dry_run:
        print(link_path, '|', link_path.relative_to(Path(REPO_LOCAL_PATH)))
        print(latest_version.read_text())
        return latest_version

    logger.debug("old location: %s", link_path)
    if link_path.exists(): 
        logger.debug("removing old manifest link")
        link_path.unlink()
    link_path.relative_to(REPO_LOCAL_PATH).symlink_to(latest_version.relative_to(link_path.parent))
    logger.debug("Commiting %s into %s", link_path.name, link_path.relative_to(REPO_LOCAL_PATH))
    return link_path

parser = argparse.ArgumentParser(
    prog="update-manifest-nightly",
    description="fetches latest releases from upstream and updates manifests",
)
parser.add_argument("--dry-run", action="store_true", help="do not create manifests in local repo")
parser.add_argument("--last", type=int, help="update manifest for dates since specified up to today")

def update_last(entries: int, gh: Gh, dry_run: bool = True):
    if entries < 1:
        logger.warning("Nothing to update")
        return
    tags = gh.release_list_tags(entries)

    for tag in tags:
        version = parse_nightly_version(tag)
        date = version_to_date(version)
        if has_manifest(MANIFESTS_SDK_NIGHTLY_PATH, date) and has_manifest(MANIFESTS_STDX_NIGHTLY_PATH, date):
            continue

        sdk_manifest = create_sdk_manifest(raw_assets=gh.release_assets(tag), version=version)
        sdk_manifest = commit_manifest(sdk_manifest, get_manifest_name(date), MANIFESTS_SDK_NIGHTLY_PATH, dry_run=dry_run)
        if need_update_latest_ref(date, MANIFESTS_SDK_NIGHTLY_PATH):
            commit_latest_manifest_link(sdk_manifest, MANIFESTS_SDK_NIGHTLY_PATH, dry_run=dry_run)
        
        stdx_manifest = create_stdx_manifest(raw_assets=gh.release_assets(tag), version=version)
        stdx_manifest = commit_manifest(stdx_manifest, get_manifest_name(date), MANIFESTS_STDX_NIGHTLY_PATH, dry_run=dry_run)
        if need_update_latest_ref(date, MANIFESTS_STDX_NIGHTLY_PATH):
            commit_latest_manifest_link(stdx_manifest, MANIFESTS_STDX_NIGHTLY_PATH, dry_run=dry_run)
        
def main():
    setup_log()
    args = parser.parse_args()
    if args.dry_run:
        logger.info("Runing in dry-run mode")
    if args.last:
        logger.info("Running update manifests for last %s nightly versions", args.last)
    else:
        logger.info("Running latest manifest update")
    
    gh = GhCached(REPO_OWNER, REPO_NAME, REPO_LOCAL_PATH)

    if (args.last):
        update_last(args.last, gh, dry_run=args.dry_run)
        return

    _need_update = False

    if need_update(MANIFESTS_SDK_NIGHTLY_PATH, gh):
        logger.info("sdk manifest is going to be updated")
        _need_update = True
    else:
        logger.info("Latest sdk aready installed")

    if need_update(MANIFESTS_STDX_NIGHTLY_PATH, gh):
        logger.info("stdx manifest is going to be updated")
        _need_update = True
    else:
        logger.info("Latest stdx aready installed")

    if not _need_update:
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
