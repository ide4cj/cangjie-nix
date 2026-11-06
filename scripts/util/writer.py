import logging
import tempfile
from datetime import date
from pathlib import Path

from .util import *

logger = logging.getLogger(__name__)


def write_manifest(assets, version) -> Path:
    manifest = tempfile.NamedTemporaryFile(
        prefix=f"manifest-{version['year']}-{version['month']}-{version['day']}.nix",
        delete=False,
    )

    def write_version(f, version: str):
        f.write(b'  version = "%b";\n' % version.encode())

    def write_asset(f, asset):
        str = f'''    {{
    system = "{asset["system"]}";
      arch = "{asset["arch"]}";
      hash = "sha256-{asset["sha256"]}";
    }}
'''
        f.write(str.encode())

    def write_assets(f, assets):
        for asset in assets:
            write_asset(f, asset)

    with manifest as f:
        f.write(b"{\n")
        write_version(f, version["value"])
        f.write(b"  assets = [\n")
        write_assets(f, assets)
        f.write(b"  ];\n")
        f.write(b"}")

    return Path(manifest.name).resolve()


def write_latest_manifest_ref(version) -> Path:
    latest_date = date(
        year=int(version["year"]),
        month=int(version["month"]),
        day=int(version["day"]),
    )

    manifest_ref = tempfile.NamedTemporaryFile(prefix="latest.nix", delete=False)
    with manifest_ref as f:
        f.write(b'"')
        f.write(latest_date.strftime(DATE_FORMAT).encode())
        f.write(b'"')
    return Path(manifest_ref.name).resolve()
