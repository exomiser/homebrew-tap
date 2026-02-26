class Exomiser < Formula
  desc "Phenotype-driven prioritisation of rare disease causing variants from whole-exome and whole-genome sequencing data"
  homepage "https://github.com/exomiser/Exomiser/"
  version "14.1.0"

  # Data release version is independent of the application version.
  # Update both constants when releasing a new version.
  DATA_VERSION = "2512"
  #DATA_BASE_URL = "https://data.monarchinitiative.org/exomiser/latest"
  DATA_BASE_URL = "https://g-879a9f.f5dc97.75bc.dn.glob.us/data"

  # Distribution zip from GitHub
  # Update the URL and sha256 checksum when a new version is released.
  url "https://github.com/exomiser/Exomiser/releases/download/#{version}/exomiser-cli-#{version}-distribution.zip"
  sha256 "fb9705017000b448b1331cfd5e1b17c8941713b8c29e4ac30524e96869224db6"

  license "AGPL-3.0"

  # Exomiser requires Java 21 or above.
  depends_on "openjdk"

  # No compiled code — Exomiser ships as a pre-built JAR.
  def install
      libexec.install Dir["*"]

      # Set up ~/.exomiser/data and seed application.properties at install time.
      exomiser_home = Pathname.new(Dir.home)/".exomiser"
      exomiser_data = exomiser_home/"data"
      exomiser_config = exomiser_home/"application.properties"

      exomiser_home.mkpath
      exomiser_data.mkpath

      unless exomiser_config.exist?
        config = (libexec/"application.properties").read
        config = config.sub(/^exomiser\.data-directory=.*$/,               "exomiser.data-directory=#{exomiser_data}")
        config = config.sub(/^#?\s*exomiser\.hg19\.data-version=.*$/,      "exomiser.hg19.data-version=#{DATA_VERSION}")
        config = config.sub(/^#?\s*exomiser\.hg38\.data-version=.*$/,      "exomiser.hg38.data-version=#{DATA_VERSION}")
        config = config.sub(/^#?\s*exomiser\.phenotype\.data-version=.*$/, "exomiser.phenotype.data-version=#{DATA_VERSION}")
        exomiser_config.write config
      end

      bin.write_jar_script libexec/"exomiser-cli-#{version}.jar", "exomiser",
                           "--sun-misc-unsafe-memory-access=allow -Dspring.config.location=#{exomiser_home}/application.properties"
    end

    def caveats
      <<~EOS
        Exomiser has been installed. ~/.exomiser/application.properties and
        ~/.exomiser/data have been created and pre-configured for you.

        ─────────────────────────────────────────────────────────────────────
        NEXT STEPS: Download the Exomiser data files (~80 GB)
        ─────────────────────────────────────────────────────────────────────

        Download the phenotype data (required for all analyses):

          wget #{DATA_BASE_URL}/#{DATA_VERSION}_phenotype.zip -P ~/.exomiser/data
          unzip ~/.exomiser/data/#{DATA_VERSION}_phenotype.zip -d ~/.exomiser/data

        Download the genome assembly data for your VCF file.
        If unsure, download both (each ~35 GB):

          # hg38 (GRCh38)
          wget #{DATA_BASE_URL}/#{DATA_VERSION}_hg38.zip -P ~/.exomiser/data
          unzip ~/.exomiser/data/#{DATA_VERSION}_hg38.zip -d ~/.exomiser/data

          # hg19 (GRCh37)
          wget #{DATA_BASE_URL}/#{DATA_VERSION}_hg19.zip -P ~/.exomiser/data
          unzip ~/.exomiser/data/#{DATA_VERSION}_hg19.zip -d ~/.exomiser/data

        Your data directory should then look like this:

          ~/.exomiser/data/
          ├── #{DATA_VERSION}_phenotype
          ├── #{DATA_VERSION}_hg38
          └── #{DATA_VERSION}_hg19

        ─────────────────────────────────────────────────────────────────────
        CONFIGURATION
        ─────────────────────────────────────────────────────────────────────

        ~/.exomiser/application.properties is pre-configured to point at
        ~/.exomiser/data with data version #{DATA_VERSION}. You only need to
        edit it if you store data elsewhere or use a different data release.

        ─────────────────────────────────────────────────────────────────────
        TEST YOUR INSTALLATION
        ─────────────────────────────────────────────────────────────────────

        Once the data is downloaded, confirm everything is working:

          exomiser analyse --analysis #{libexec}/examples/test-analysis-exome.yml

        ─────────────────────────────────────────────────────────────────────
        MEMORY
        ─────────────────────────────────────────────────────────────────────

        For genome-scale analyses you may need to increase JVM memory.
        Set JAVA_TOOL_OPTIONS before running, for example:

          export JAVA_TOOL_OPTIONS="-Xmx12g"

        ─────────────────────────────────────────────────────────────────────
        FURTHER INFORMATION
        ─────────────────────────────────────────────────────────────────────

        Full documentation : https://exomiser.readthedocs.io
        Data releases      : https://github.com/exomiser/Exomiser/discussions/categories/data-release
      EOS
    end

    test do
      output = shell_output("#{bin}/exomiser --version 2>&1", 0)
      assert_match version.to_s, output
    end
  end
