class Exomiser < Formula
  desc "Phenotype-driven prioritisation of rare disease causing variants from whole-exome and whole-genome sequencing data"
  homepage "https://github.com/exomiser/Exomiser/"
  version "14.1.0"

  # Distribution zip from the Monarch Initiative data repository.
  # Update the URL and sha256 checksum when a new version is released.
  url "https://github.com/exomiser/Exomiser/releases/download/#{version}/exomiser-cli-#{version}-distribution.zip"
  sha256 "fb9705017000b448b1331cfd5e1b17c8941713b8c29e4ac30524e96869224db6"

  license "AGPL-3.0"

  # Exomiser requires Java 21 or above.
  depends_on "openjdk@25"

  # No compiled code — Exomiser ships as a pre-built JAR.
  def install
    # Install the JAR and bundled configuration/example files.
    libexec.install Dir["*"]
    # Create a wrapper script using Homebrew's idiomatic method.
        # --sun-misc-unsafe-memory-access=allow suppresses JVM warnings from
        # bioinformatics libraries that use internal Java APIs.
        bin.write_jar_script libexec/"exomiser-cli-#{version}.jar", "exomiser",
                             "--sun-misc-unsafe-memory-access=allow -Dspring.config.location=#{libexec}/application.properties"
  end

  def caveats
    <<~EOS
      Exomiser has been installed, but it requires large data files to run.

      ─────────────────────────────────────────────────────────────────────
      NEXT STEPS: Download the Exomiser data files
      ─────────────────────────────────────────────────────────────────────

      1. Create a directory to hold the data (80+ GB required):

           mkdir -p ~/exomiser-data

      2. Download the data files (this will take a while):

           https://github.com/exomiser/Exomiser/discussions/categories/data-release

           cd ~/exomiser-data
           curl -O https://data.monarchinitiative.org/exomiser/latest/2402_phenotype.zip

           # Download one or both genome assemblies depending on your VCF:
           curl -O https://data.monarchinitiative.org/exomiser/latest/2402_hg38.zip
           curl -O https://data.monarchinitiative.org/exomiser/latest/2402_hg19.zip

      3. Unzip the data files:

           unzip '2402_*.zip' -d ~/exomiser-data

      4. Configure Exomiser to find the data. Open:

           #{libexec}/application.properties

         and set the data directory and version, for example:

           exomiser.data-directory=#{Dir.home}/exomiser-data
           exomiser.hg38.data-version=2402
           exomiser.phenotype.data-version=2402

      5. Run a test analysis to confirm everything is working:

           exomiser analyse --analysis #{libexec}/examples/test-analysis-exome.yml

      ─────────────────────────────────────────────────────────────────────
      MEMORY
      ─────────────────────────────────────────────────────────────────────

      By default the JVM allocates a fraction of available system RAM.
      For genome-scale analyses you may need more. Set JAVA_TOOL_OPTIONS
      before running exomiser to override this, for example:

        export JAVA_TOOL_OPTIONS="-Xmx12g"

      ─────────────────────────────────────────────────────────────────────
      FURTHER INFORMATION
      ─────────────────────────────────────────────────────────────────────

      Full documentation:
        https://exomiser.readthedocs.io

      Data releases and discussions:
        https://github.com/exomiser/Exomiser/discussions/categories/data-release
    EOS
  end

  test do
    # Verify the wrapper script invokes Java and prints the Exomiser version.
    # This does not require data files to be present.
    output = shell_output("#{bin}/exomiser --version 2>&1", 0)
    assert_match version.to_s, output
  end
end
