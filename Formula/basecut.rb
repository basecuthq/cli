# typed: false
# frozen_string_literal: true

# Basecut CLI - Database subsetting and sanitization for realistic dev environments.
# Tap: brew tap basecuthq/cli
# Install: brew install basecut
# This file is automatically updated by the release workflow.

class Basecut < Formula
  desc "Database subsetting and sanitization for realistic dev environments"
  homepage "https://docs.basecut.dev"
  version "0.1.1"
  license :cannot_represent

  on_macos do
    on_intel do
      url "https://github.com/basecuthq/cli/releases/download/v#{version}/basecut-#{version}-darwin-amd64"
      sha256 "dfc7d3ed1cc88abdb96e61e8d83d79e7550ef5bfdecab37f01ab6ae2c92125da"
    end
    on_arm do
      url "https://github.com/basecuthq/cli/releases/download/v#{version}/basecut-#{version}-darwin-arm64"
      sha256 "283c041cd0427518d9b94ce4bc8c2bf5814f55387719b69a11089994dd8369b1"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/basecuthq/cli/releases/download/v#{version}/basecut-#{version}-linux-amd64"
      sha256 "8c4005bcce9623a8bf5790ae7cad0c039a3c3d6c7e812510fe141dc348bb98d8"
    end
    on_arm do
      url "https://github.com/basecuthq/cli/releases/download/v#{version}/basecut-#{version}-linux-arm64"
      sha256 "826467b514a8f70b41888b1518df808c848f582fc894b441f368ec089ad31bd7"
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
