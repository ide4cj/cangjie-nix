import re
from base64 import b64encode
from datetime import date

from .util import *

NIGHTLY_VERSION_REGEX = r"(?P<major>\d+)\.(?P<minor>\d+)\.(?P<patch>\d+)(.*)\.(?P<year>\d{4})(?P<month>\d{2})(?P<day>\d{2})(?P<hour>\d{2})(?P<minute>\d{2})(?P<second>\d{2})"
STABLE_VERSION_REGEX = r"(?P<major>\d+)\.(?P<minor>\d+)\.(?P<patch>\d+)(.*)"

def _digify_version_dict(version: dict) -> dict:
    def digify_key(key: str):
        if key in version:
            version[key] = int(version[key])

    keys = [ "major", "minor", "patch", "year", "month", "day", "hour", "minute", "second"]
    for key in keys:
        digify_key(key)
    return version

def _parse_version(version: str, regex) -> dict[str, str | int | bool] | None:
    pat = re.compile(regex)
    parsed = pat.match(version)
    if parsed is None:
        return None
    res = parsed.groupdict()
    _digify_version_dict(res)

    res["is_alpha"] = "alpha" in version
    res["is_beta"] = "beta" in version
    res["value"] = version

    return res

def parse_stable_version(tag: str) -> dict[str, str | int | bool ] | None :
    return _parse_version(tag, STABLE_VERSION_REGEX)

def parse_nightly_version(tag: str) -> dict[str, str | int | bool ] | None :
    return _parse_version(tag, NIGHTLY_VERSION_REGEX)

def parse_tag_into_date(tag: str) -> date | None:
    version = parse_nightly_version(tag)
    if version is None:
        return None
    return version_to_date(version)

def strbytes_to_sha256(strbytes: str) -> str:
    return b64encode(bytes.fromhex(strbytes)).decode()

def github_digest_to_manifest_sha256(digest: str) -> str | None:
    matched = re.compile("sha256:(.+)").match(digest)
    if matched is None:
        return None
    hex_sha256 = matched.group(1)
    return strbytes_to_sha256(hex_sha256)

def _parse_asset(asset, regex, to_sha256):
    res = {}
    parsed = regex.match(asset["name"])

    if parsed is None:
        return None
    res = parsed.groupdict()
    _digify_version_dict(res)

    res["sha256"] = to_sha256(asset) 

    return res

def parse_sdk_nightly_asset(asset):
    regex = re.compile(
        r"cangjie-sdk-(?P<system>\w+)-(?P<arch>.+)-"
        + NIGHTLY_VERSION_REGEX
        + r"\.[(tar\.gz)(zip)]"
    )
    return _parse_asset(asset, regex, lambda asset: github_digest_to_manifest_sha256(asset["digest"]))
    
def parse_sdk_stable_asset(asset):
    regex = re.compile(
        r"cangjie-sdk-(?P<system>\w+)-(?P<arch>.+)-"
        + STABLE_VERSION_REGEX
        + r"\.[(tar\.gz)(zip)]"
    )
    return _parse_asset(asset, regex, lambda asset: strbytes_to_sha256(asset["sha"]))


def parse_stdx_asset(asset):
    regex = re.compile(
        r"cangjie-stdx-(?P<system>\w+)-(?P<arch>.+)-"
        + NIGHTLY_VERSION_REGEX
        + r"\.1\."
        + r"zip"
    )
    return _parse_asset(asset, regex, lambda asset: github_digest_to_manifest_sha256(asset["digest"]))

def parse_sdk_stable_assets(raw: str):
    def RE_ENUMERATE(of: list):
        return rf"({r",\s*".join(of)}(,)?)"
    RE_VERSION = r"(?P<version>[\d\w]+\.[\d\w]+\.[\d\w]+)"
    RE_TIME = r"\d{4}-\d{1,2}-\d{1,2}"
    def RE_JS_FIELD(key: str, value: str) -> str:
        return rf'({key}\s*:\s*{value})'

    RE_ASSET_FIELDS = [
        RE_JS_FIELD("name", r'"(?P<name>[^"]+)"'),
        RE_JS_FIELD("url", r'"[^"]+&objectKey=(?P<objectkey>[\d\w]+)"'),
        RE_JS_FIELD("version", rf'"{RE_VERSION}"'),
        RE_JS_FIELD("time", rf'"{RE_TIME}"'),
        RE_JS_FIELD("sha", r'"(?P<sha>[\d\w]+)"'),
        RE_JS_FIELD("docurl", r'"[^"]*"'),
        RE_JS_FIELD("endocurl", r'"[^"]*"'),
        RE_JS_FIELD("size", r'"[^"]+"'),
    ]

    RE_ASSET_OBJ = rf'{{{RE_ENUMERATE(RE_ASSET_FIELDS)}}}';

    # RE_ASSETS_FIELDS = [
    #     r'(name:".*")',
    #     rf'(list:\[[({RE_ASSET_OBJ}),\s*]+\])',
    # ]
    # RE_ASSETS_OBJ = rf'\{{{RE_ENUMERATE(RE_ASSETS_FIELDS)}\}}'

    # RE_FIELDS = [
    #     rf'(time:"{RE_TIME}")',
    #     rf'(name:".*")',
    #     rf'(version:"{RE_VERSION}")',
    #     rf'(versiontype:".*")',
    #     rf'(docurl:".*")',
    #     rf'(endocurl:".*")',
    #     rf'(explainurl:".*")',
    #     rf'(list:\[[({RE_ASSETS_OBJ}),\s*]+\])',
    # ]
 
    regex = re.compile(RE_ASSET_OBJ)

    raw_assets = regex.finditer(raw)
    assets = []
    for raw_asset in raw_assets:
        asset = raw_asset.groupdict()
        _digify_version_dict(asset)
        res = parse_sdk_stable_asset(asset)
        if res is None:
            continue
        res["version"] = asset["version"]
        res["objectkey"] = asset["objectkey"]
        assets.append(res)

    return assets
