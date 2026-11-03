# Auto-update scripts for manifests

## How to run?

### Nightly update

```sh
./scripts/update-manifest-nightly.py
```

### Options

- `--dry-run` to check updates available without overriding file-system.

### Required environment variables

- `UPSTREAM_REPO_NAME` for repo with nightly releases (`nightly_build`).
- `UPSTREAM_REPO_OWNER` for repo with nightly releases (`cangjie-bot`).
- `GH_TOKEN` for github cli requests.
