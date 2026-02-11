#!/usr/bin/env sh
# Install basecut CLI from the latest GitHub Release.
# Usage: curl -fsSL https://install.basecut.dev | sh
# Or: curl -fsSL https://install.basecut.dev | sh -s -- /usr/local/bin

set -e

REPO="basecuthq/cli"
INSTALL_DIR="${1:-${HOME}/.local/bin}"
VERSION="${2:-latest}"

download_file() {
  url="$1"
  out="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL -o "$out" "$url"
    return $?
  fi
  if command -v wget >/dev/null 2>&1; then
    wget -q -O "$out" "$url"
    return $?
  fi
  echo "curl or wget is required"
  return 1
}

sha256_file() {
  file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
    return 0
  fi
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
    return 0
  fi
  if command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$file" | awk '{print $NF}'
    return 0
  fi
  return 1
}

# Detect OS and arch (same names as release assets)
detect_platform() {
  os=""
  arch=""
  if command -v uname >/dev/null 2>&1; then
    case "$(uname -s)" in
      Darwin) os="darwin" ;;
      Linux)  os="linux" ;;
      MINGW*|MSYS*|CYGWIN*) os="windows" ;;
      *)      os="unknown" ;;
    esac
    case "$(uname -m)" in
      x86_64|amd64) arch="amd64" ;;
      arm64|aarch64) arch="arm64" ;;
      *) arch="unknown" ;;
    esac
  fi
  if [ -z "$os" ] || [ -z "$arch" ] || [ "$os" = "unknown" ] || [ "$arch" = "unknown" ]; then
    echo "Unsupported platform. Please install manually from https://github.com/${REPO}/releases"
    exit 1
  fi
}

# Resolve latest release tag
get_version() {
  if [ "$VERSION" = "latest" ]; then
    tmp_latest="$(mktemp)"
    if download_file "https://api.github.com/repos/${REPO}/releases/latest" "$tmp_latest"; then
      VERSION=$(grep '"tag_name":' "$tmp_latest" | sed -E 's/.*"([^"]+)".*/\1/')
    else
      rm -f "$tmp_latest"
      echo "Could not fetch latest version metadata from GitHub."
      exit 1
    fi
    rm -f "$tmp_latest"
  fi
  if [ -z "$VERSION" ]; then
    echo "Could not determine version. Try specifying a tag: install.sh [dir] v1.0.0"
    exit 1
  fi
  # Strip leading v if present — release assets are named basecut-1.0.0-os-arch (no v in filename)
  VERSION_STRIP="${VERSION#v}"
}

# Download and install
install_binary() {
  if [ "$os" = "windows" ]; then
    # Windows: only amd64 binary is built
    asset_name="basecut-${VERSION_STRIP}-windows-amd64.exe"
  else
    asset_name="basecut-${VERSION_STRIP}-${os}-${arch}"
  fi
  url="https://github.com/${REPO}/releases/download/${VERSION}/${asset_name}"
  checksums_url="https://github.com/${REPO}/releases/download/${VERSION}/checksums-sha256.txt"
  tmp_dir="$(mktemp -d 2>/dev/null || mktemp -d -t basecut-install)"
  trap 'rm -rf "$tmp_dir"' EXIT INT TERM
  tmp_asset="${tmp_dir}/${asset_name}"
  tmp_checksums="${tmp_dir}/checksums-sha256.txt"

  if ! download_file "$url" "$tmp_asset"; then
    echo "Download failed. Check https://github.com/${REPO}/releases for available versions."
    exit 1
  fi
  if ! download_file "$checksums_url" "$tmp_checksums"; then
    echo "Download failed for checksum file: ${checksums_url}"
    exit 1
  fi

  expected_hash="$(awk -v name="$asset_name" '$2 == name { print $1 }' "$tmp_checksums")"
  if [ -z "$expected_hash" ]; then
    echo "No checksum entry found for ${asset_name}."
    exit 1
  fi
  actual_hash="$(sha256_file "$tmp_asset" || true)"
  if [ -z "$actual_hash" ]; then
    echo "No SHA256 tool found (tried: sha256sum, shasum, openssl)."
    exit 1
  fi
  if [ "$actual_hash" != "$expected_hash" ]; then
    echo "Checksum verification failed for ${asset_name}."
    echo "Expected: ${expected_hash}"
    echo "Actual:   ${actual_hash}"
    exit 1
  fi

  mkdir -p "$INSTALL_DIR"
  out="${INSTALL_DIR}/basecut${os_ext}"
  mv "$tmp_asset" "$out"
  trap - EXIT INT TERM
  rm -rf "$tmp_dir"
  chmod +x "$out"
  echo "Installed basecut to $out"
  if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo "Add ${INSTALL_DIR} to your PATH to run basecut."
  fi
}

os_ext=""
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) os_ext=".exe" ;;
esac

detect_platform
get_version
install_binary
