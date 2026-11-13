import json
import logging
import subprocess
from functools import cache
from pathlib import Path

logger = logging.getLogger(__name__)


class Gh:
    def __init__(self, repo_owner: str, repo_name: str, repo_local_path: Path):
        self.repo_owner = repo_owner
        self.repo_name = repo_name

    def release_latest_tag(self) -> str:
        rel_str = self.call(
            "release",
            "view",
            "--json",
            "tagName",
            "--repo",
            self.repo_owner + "/" + self.repo_name,
        )
        tag = json.loads(rel_str)["tagName"]
        logger.debug("Downloaded latest release from github with tag '%s'", tag)
        return tag

    def release_assets(self, tag: str):
        rel_str = self.call(
            "release",
            "view",
            "--json",
            "assets",
            "--repo",
            self.repo_owner + "/" + self.repo_name,
        )
        assets = json.loads(rel_str)["assets"]
        logger.debug("Downloaded %d assets for '%s' from github", len(assets), tag)
        return assets

    def release_list_tags(self, count: int):
        response = self.call(
            "release",
            "list",
            "--limit",
            str(count),
            "--json",
            "tagName",
            "--repo",
            self.repo_owner + "/" + self.repo_name,
        )
        values = json.loads(response)
        tags = [ obj["tagName"] for obj in values ]
        return tags

    def call(self, *args: str) -> str:
        return subprocess.run(
            ["gh", *args], check=True, stdout=subprocess.PIPE, text=True
        ).stdout
        
class GhCached(Gh):
    def __init__(self, repo_owner: str, repo_name: str, repo_local_path: Path):
        super().__init__(repo_owner, repo_name, repo_local_path)
        self.release_latest_tag = cache(self._release_latest_tag)
        self._release_assets = cache(self._release_assets)
        self._release_list_tags = cache(self._release_list_tags)

    def _release_latest_tag(self) -> str:
        return super().release_latest_tag()

    def _release_assets(self, tag: str):
        return super().release_assets(tag)
        
    def _release_list_tags(self, count: int):
        return super().release_list_tags(count)
