class Searchfs < Formula
  desc "Fast filename search on HFS+ and APFS volumes using filesystem catalog search"
  homepage "https://github.com/sveinbjornt/searchfs"
  url "https://github.com/sveinbjornt/searchfs/archive/refs/tags/0.4.0.tar.gz"
  sha256 "9bb00135181ba684c9548541aca912632dbf9533f1f9db7ca95595701930b2d9"
  license "BSD-3-Clause"

  depends_on :macos

  def install
    system "make"
    bin.install "searchfs"
    man1.install "searchfs.1"
  end

  test do
    # Test basic functionality
    system "#{bin}/searchfs", "--version"
    # Test list volumes
    system "#{bin}/searchfs", "--list"
    # Test search with limit (should complete quickly)
    system "#{bin}/searchfs", "-v", "/", "s", "-m", "5"
  end
end
