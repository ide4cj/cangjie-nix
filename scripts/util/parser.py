import re
from base64 import b64encode
from datetime import date

from .util import *

NIGHTLY_VERSION_REGEX = r"(?P<major>\d+)\.(?P<minor>\d+)\.(?P<patch>\d+)(.*)\.(?P<year>\d{4})(?P<month>\d{2})(?P<day>\d{2})(?P<hour>\d{2})(?P<minute>\d{2})(?P<second>\d{2})"

def _digify_version_dict(version: dict) -> dict:
    def digify_key(key: str):
        if key in version:
            version[key] = int(version[key])

    keys = [ "major", "minor", "patch", "year", "month", "day", "hour", "minute", "second"]
    for key in keys:
        digify_key(key)
    return version

def parse_nightly_version(tag: str) -> dict[str, str | int | bool ] | None :
    pat = re.compile(NIGHTLY_VERSION_REGEX)
    parsed = pat.match(tag)
    if parsed is None:
        return None
    res = parsed.groupdict()
    _digify_version_dict(res)

    res["is_alpha"] = "alpha" in tag
    res["is_beta"] = "beta" in tag
    res["value"] = tag

    return res

def parse_tag_into_date(tag: str) -> date | None:
    version = parse_nightly_version(tag)
    if version is None:
        return None
    return version_to_date(version)

def github_digest_to_manifest_sha256(digest: str) -> str | None:
    matched = re.compile("sha256:(.+)").match(digest)
    if matched is None:
        return None
    hex_sha256 = matched.group(1)
    return b64encode(bytes.fromhex(hex_sha256)).decode()

def _parse_asset(asset, regex):
    res = {}
    parsed = regex.match(asset["name"])

    if parsed is None:
        return None
    res = parsed.groupdict()
    _digify_version_dict(res)

    res["sha256"] = github_digest_to_manifest_sha256(asset["digest"])

    return res

def parse_sdk_asset(asset):
    regex = re.compile(
        r"cangjie-sdk-(?P<system>\w+)-(?P<arch>.+)-"
        + NIGHTLY_VERSION_REGEX
        + r"\.[(tar\.gz)(zip)]"
    )
    return _parse_asset(asset, regex)


def parse_stdx_asset(asset):
    regex = re.compile(
        r"cangjie-stdx-(?P<system>\w+)-(?P<arch>.+)-"
        + NIGHTLY_VERSION_REGEX
        + r"\.1\."
        + r"zip"
    )
    return _parse_asset(asset, regex)
