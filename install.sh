#!/usr/bin/env sh
# Install basecut CLI from the latest GitHub Release.
# Usage: curl -fsSL https://install.basecut.dev | sh
# Or: curl -fsSL https://install.basecut.dev | sh -s -- /usr/local/bin

set -e

REPO="basecuthq/cli"
INSTALL_DIR="${1:-${HOME}/.local/bin}"
VERSION="${2:-latest}"
SCRIPT_NAME="basecut-install"

is_tty() {
  [ -t 1 ]
}

if is_tty && [ -z "${NO_COLOR:-}" ]; then
  C_BOLD="$(printf '\033[1m')"
  C_DIM="$(printf '\033[2m')"
  C_GREEN="$(printf '\033[32m')"
  C_YELLOW="$(printf '\033[33m')"
  C_RED="$(printf '\033[31m')"
  C_BLUE="$(printf '\033[34m')"
  C_RESET="$(printf '\033[0m')"
else
  C_BOLD=""
  C_DIM=""
  C_GREEN=""
  C_YELLOW=""
  C_RED=""
  C_BLUE=""
  C_RESET=""
fi

print_info() {
  printf '%s[%s]%s %s\n' "$C_BLUE" "$SCRIPT_NAME" "$C_RESET" "$1"
}

print_success() {
  printf '%s[%s]%s %s%s%s\n' "$C_GREEN" "$SCRIPT_NAME" "$C_RESET" "$C_GREEN" "$1" "$C_RESET"
}

print_warn() {
  printf '%s[%s]%s %s%s%s\n' "$C_YELLOW" "$SCRIPT_NAME" "$C_RESET" "$C_YELLOW" "$1" "$C_RESET"
}

print_error() {
  printf '%s[%s]%s %s%s%s\n' "$C_RED" "$SCRIPT_NAME" "$C_RESET" "$C_RED" "$1" "$C_RESET" >&2
}

die() {
  print_error "$1"
  exit 1
}

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
  print_error "curl or wget is required to download releases."
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
    die "Unsupported platform. Install manually from https://github.com/${REPO}/releases"
  fi
}

# Resolve latest release tag
get_version() {
  if [ "$VERSION" = "latest" ]; then
    print_info "Resolving latest release version..."
    tmp_latest="$(mktemp)"
    if download_file "https://api.github.com/repos/${REPO}/releases/latest" "$tmp_latest"; then
      VERSION=$(grep '"tag_name":' "$tmp_latest" | sed -E 's/.*"([^"]+)".*/\1/')
    else
      rm -f "$tmp_latest"
      die "Could not fetch latest version metadata from GitHub."
    fi
    rm -f "$tmp_latest"
  fi
  if [ -z "$VERSION" ]; then
    die "Could not determine version. Try: install.sh [dir] v1.0.0"
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

  print_info "Downloading ${asset_name}..."
  if ! download_file "$url" "$tmp_asset"; then
    die "Download failed. Check https://github.com/${REPO}/releases for available versions."
  fi
  print_info "Downloading checksums..."
  if ! download_file "$checksums_url" "$tmp_checksums"; then
    die "Download failed for checksum file: ${checksums_url}"
  fi

  print_info "Verifying checksum..."
  expected_hash="$(awk -v name="$asset_name" '$2 == name { print $1 }' "$tmp_checksums")"
  if [ -z "$expected_hash" ]; then
    die "No checksum entry found for ${asset_name}."
  fi
  actual_hash="$(sha256_file "$tmp_asset" || true)"
  if [ -z "$actual_hash" ]; then
    die "No SHA256 tool found (tried: sha256sum, shasum, openssl)."
  fi
  if [ "$actual_hash" != "$expected_hash" ]; then
    print_error "Checksum verification failed for ${asset_name}."
    print_error "Expected: ${expected_hash}"
    print_error "Actual:   ${actual_hash}"
    exit 1
  fi

  print_info "Installing to ${INSTALL_DIR}..."
  mkdir -p "$INSTALL_DIR"
  out="${INSTALL_DIR}/basecut${os_ext}"
  mv "$tmp_asset" "$out"
  trap - EXIT INT TERM
  rm -rf "$tmp_dir"
  chmod +x "$out"
  print_success "Installed basecut to ${out}"
  if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    print_warn "${INSTALL_DIR} is not in your PATH."
    printf '%s\n' "Add this line to your shell profile:"
    printf '%s\n' "  export PATH=\"${INSTALL_DIR}:\$PATH\""
  fi

  printf '\n%sNext steps%s\n' "$C_BOLD" "$C_RESET"
  printf '%s\n' "  1. basecut --help"
  printf '%s\n' "  2. basecut login"
}

os_ext=""
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) os_ext=".exe" ;;
esac

printf '%sBasecut CLI Installer%s\n' "$C_BOLD" "$C_RESET"
printf '%sRepository:%s %s\n' "$C_DIM" "$C_RESET" "$REPO"

detect_platform
get_version
print_info "Preparing install for ${os}/${arch} (${VERSION})"
install_binary
