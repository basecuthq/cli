# typed: false
# frozen_string_literal: true

# Basecut CLI - Database subsetting and sanitization for realistic dev environments.
# Tap: brew tap basecuthq/cli
# Install: brew install basecut
# Source of truth is the public distribution repo (`basecuthq/cli`), where
# this formula is updated automatically by the release workflow.

class Basecut < Formula
  desc "Database subsetting and sanitization for realistic dev environments"
  homepage "https://docs.basecut.dev"
  version "0.1.0"
  # Commercial/proprietary distribution (not an SPDX OSS identifier).
  license :cannot_represent

  # Release asset filenames use version without 'v' (e.g. basecut-0.1.0-darwin-amd64), same as install.sh and release-cli workflow
  on_macos do
    on_intel do
      url "https://github.com/basecuthq/cli/releases/download/v#{version}/basecut-#{version}-darwin-amd64"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
    on_arm do
      url "https://github.com/basecuthq/cli/releases/download/v#{version}/basecut-#{version}-darwin-arm64"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/basecuthq/cli/releases/download/v#{version}/basecut-#{version}-linux-amd64"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
    on_arm do
      url "https://github.com/basecuthq/cli/releases/download/v#{version}/basecut-#{version}-linux-arm64"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
  end

  def install
    binary = Dir["basecut-*"].first
    bin.install binary => "basecut"
  end

  test do
    assert_match "Database subsetting", shell_output("#{bin}/basecut --help", 0)
  end
end
