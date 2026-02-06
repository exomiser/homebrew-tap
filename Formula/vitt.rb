class Vitt < Formula
  desc "A moderately small and fast variant annotation utility"
  homepage "https://github.com/exomiser/vitt"
  version "0.1.0"
  url "https://repo1.maven.org/maven2/org/monarchinitiative/vitt/vitt-cli/#{version}/vitt-cli-#{version}.jar"
  sha256 "ee25886bc831b79d1b30922aaf41fbcda911ef7d712b10f892e37fca5f8a5fbd" # Get with: shasum -a 256 vitt-cli-#{version}.jar

  depends_on "openjdk"

  def install
    libexec.install "vitt-cli-#{version}.jar"
    bin.write_jar_script libexec/"vitt-cli-#{version}.jar", "vitt", "--sun-misc-unsafe-memory-access=allow"
  end

  test do
    system "#{bin}/vitt", "--version"
  end
end
