class SolSign < Formula
  desc "Command-line tool for signing messages with Solana keypairs"
  homepage "https://github.com/Aryamanraj/go-sol-sign"
  url "https://github.com/Aryamanraj/go-sol-sign/archive/v1.0.0.tar.gz"
  sha256 "YOUR_SHA256_HERE"  # Update this with actual SHA256
  license "MIT"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-w -s"), "-o", bin/"sol-sign"
    man1.install "packaging/rpm/sol-sign.1"
  end

  test do
    # Test version output
    assert_match "sol-sign v1.0.0", shell_output("#{bin}/sol-sign -version")
    
    # Test help output
    output = shell_output("#{bin}/sol-sign 2>&1", 1)
    assert_match "Usage:", output
    assert_match "keypair", output
    assert_match "message", output
  end
end
