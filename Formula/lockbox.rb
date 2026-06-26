class Lockbox < Formula
  desc "SOPS + 1Password secrets and document CLI"
  homepage "https://github.com/mergd/lockbox"
  license "MIT"
  head "https://github.com/mergd/lockbox.git", branch: "main"

  depends_on "age"
  depends_on "jq"
  depends_on "sops"
  depends_on cask: "1password-cli"

  def install
    libexec.install "bin", "lib"
    bin.install_symlink libexec/"bin/lockbox" => "lockbox"
  end

  def caveats
    <<~EOS
      Run `lockbox init` in a project to scaffold .lockbox/config.env
      Then: eval "$(op signin)" && lockbox setup
    EOS
  end

  test do
    assert_match "lockbox", shell_output("#{bin}/lockbox help")
  end
end
