# AGENTS.md - Dotfiles Repository Guide

This repository uses [Toml Bombadil](https://oknozor.github.io/toml-bombadil/) to manage dotfiles.

## How Bombadil Works

1. **Source files** are stored directly in the repo root (e.g., `bash/bashrc`, `git/gitconfig`)
2. **Bombadil renders** these to the `.dots/` directory with any template variables injected
3. **Symlinks** are created from `$HOME` (e.g., `~/.bashrc`) to `.dots/` (e.g., `~/dotfiles/.dots/bash/bashrc`)

This differs from pure symlink approaches by allowing:
- Template variables (`__[VAR_NAME]__`)
- Multiple profiles/themes
- GPG-encrypted secrets

## Key Commands

| Command | Description |
|---------|-------------|
| `bombadil link` | Create/update symlinks from home directory to `.dots/` |
| `bombadil get dots` | List all configured dotfiles |
| `bombadil install` | Full install (links + hooks) |

## Configuration Files

### Main: `bombadil.toml`
- Sets `dotfiles_dir = "dotfiles"` (not used - source files are in repo root)
- Imports modular configs via `import` array

### Modular configs (imported by main):
- `code/code.toml` - VS Code settings
- `easyeffects/easyeffects.toml` - PipeWire effects
- `bin/bin.toml` - Scripts and systemd units
- `backup/backup.toml` - Backup scripts
- `katarl/katarl.toml` - Katarl terminal
- `podman/podman.toml` - Podman containers
- `opencode/opencode.toml` - Opencode AI config

### Dotfile format:
```toml
[settings.dots]
name = { source = "relative/path", target = "~/.relative/path" }
```

## Directory Layout

| Directory | Purpose |
|-----------|---------|
| `/` | Source dotfiles (committed to git) |
| `/.dots/` | Rendered dotfiles (symlink targets) |
| `/.git/` | Git repository |

## Adding New Dotfiles

1. Create source file in appropriate subdirectory
2. Add entry to relevant `.toml` config (e.g., `code/code.toml`)
3. Run `bombadil link` to create symlinks

## Notes

- The `.dots/` directory should NOT be committed to git (already in `.gitignore`)
- Changes to source files require running `bombadil link` again
- Use `bombadil get path` to see where dotfiles are stored
