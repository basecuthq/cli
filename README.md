## Installation Methods

### Recommended: Homebrew (macOS / Linux)

```bash
brew tap basecuthq/cli
brew install basecut
```

### Install Script (macOS / Linux / Windows)

Downloads the latest public release and verifies SHA256 checksums:

```bash
curl -fsSL https://install.basecut.dev | sh
```

Optional: install to a specific directory (default `~/.local/bin`) or pin a version:

```bash
curl -fsSL https://install.basecut.dev | sh -s -- /usr/local/bin
curl -fsSL https://install.basecut.dev | sh -s -- ~/.local/bin v1.0.0
```

### GitHub Releases

Download the binary for your platform from the public release repository:

- https://github.com/basecuthq/cli/releases

## Verification

To verify the installation, run:

```bash
basecut --version
```
