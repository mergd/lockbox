class Lockbox < Formula
  desc "SOPS + 1Password secrets and document CLI"
  homepage "https://github.com/mergd/lockbox"
  license "MIT"
  head "https://github.com/mergd/lockbox.git", branch: "main"

  depends_on "age"
  depends_on "jq"
  depends_on "sops"

  def install
    libexec.install "bin", "lib", "skills"
    bin.install_symlink libexec/"bin/lockbox" => "lockbox"
  end

  def caveats
    <<~EOS
      Also requires 1Password CLI: brew install --cask 1password-cli

      Run `lockbox init` in a project to scaffold .lockbox/config.env
      Then: eval "$(op signin)" && lockbox setup
    EOS
  end

  test do
    assert_match "lockbox", shell_output("#{bin}/lockbox help")
  end
end
