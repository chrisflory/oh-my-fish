# Fork notes

Personal distribution of [Oh My Fish](https://github.com/oh-my-fish/oh-my-fish).

## What differs from upstream

| Item | This fork | Upstream |
|------|-----------|----------|
| Installer default repo | `chrisflory/oh-my-fish` | `oh-my-fish/oh-my-fish` |
| Package index | `chrisflory/packages-main` | `oh-my-fish/packages-main` |
| Install URLs in README | `chrisflory/oh-my-fish` | `oh-my-fish/oh-my-fish` |

Additional fork-only changes:

- Windows/WSL install documentation and `omf doctor` WSL checks
- [`pkg-winfish`](https://github.com/chrisflory/pkg-winfish) plugin in the package index
- Weekly upstream sync GitHub Action (`.github/workflows/sync-upstream.yml`)

## Updating from this fork

After install, `git -C ~/.local/share/omf remote -v` should show:

- `origin` → `chrisflory/oh-my-fish`
- `upstream` → `oh-my-fish/oh-my-fish`

Run:

```fish
omf update omf
```

To pull the latest core from this fork. Use `omf update` to refresh all installed packages.

## Syncing upstream manually

```bash
git remote add upstream https://github.com/oh-my-fish/oh-my-fish.git  # once
git fetch upstream
git merge upstream/master
# Re-apply fork URLs in bin/install, repositories, README install links
shasum -a 256 bin/install | awk '{print $1 " install"}' > bin/install.sha256
```

Or wait for the automated sync PR from the GitHub Action.

## Reporting issues

- Bugs in core OMF behavior: [oh-my-fish/oh-my-fish issues](https://github.com/oh-my-fish/oh-my-fish/issues)
- Fork-specific install/index problems: [chrisflory/oh-my-fish issues](https://github.com/chrisflory/oh-my-fish/issues)
