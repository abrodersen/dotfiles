# Dotfiles

Managed with [Toml Bombadil](https://github.com/oknozor/toml-bombadil), a Rust-based dotfile manager with templating support.

## Structure

```
.
├── bombadil.toml          # Main bombadil configuration
├── atuin/                 # Atuin shell history config
├── backup/                # Backup scripts and systemd units
├── bash/                  # Bashrc configuration
├── bin/                   # Custom scripts
├── blesh/                 # BLE shell extensions
├── chromium/              # Chromium flags
├── code/                  # VS Code / Code OSS settings
├── easyeffects/           # PipeWire effects presets
├── electron/              # Electron flags
├── firefox/               # Firefox user.js
├── git/                   # Git configuration
├── htop/                  # htop config
├── kanidm/                # Kanidm client config
├── katarl/                # Katarl terminal config
├── opencode/              # Opencode AI assistant config
├── podman/                # Podman containers
├── s3fs/                  # S3FS mount service
└── .dots/                 # Rendered dotfiles (symlinked from $HOME)
```

## Installation

### Prerequisites

Install bombadil:

```bash
# Arch Linux
pacman -S toml-bombadil

# Via cargo
cargo install toml-bombadil
```

### Setup

1. Clone this repository to `~/dotfiles`:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
   ```

2. Link the bombadil config:
   ```bash
   cd ~/dotfiles
   bombadil link
   ```

   This creates symlinks from your home directory to the `.dots` directory.

## Usage

### Link dotfiles
```bash
bombadil link
```

### Check configuration
```bash
bombadil get dots
bombadil get hooks
bombadil get path
```

### Update dotfiles

After modifying source files in this repo, re-link:
```bash
bombadil link
```

## Configuration

The main `bombadil.toml` imports modular configs from subdirectories:
- `code/code.toml` - Editor settings
- `easyeffects/easyeffects.toml` - Audio processing
- `bin/bin.toml` - Scripts
- `backup/backup.toml` - Backup configuration
- `katarl/katarl.toml` - Terminal emulator
- `podman/podman.toml` - Container definitions
- `opencode/opencode.toml` - AI assistant config

Each dotfile is defined with a `source` (relative to this repo) and `target` (relative to `$HOME`).

## Customization

Add new dotfiles by editing the appropriate TOML file:

```toml
[settings.dots]
my_config = { source = "path/to/source", target = ".config/target" }
```

Then run `bombadil link` to create the symlinks.
