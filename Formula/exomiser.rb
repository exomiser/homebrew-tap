class Exomiser < Formula
  desc "Phenotype-driven prioritisation of rare disease causing variants from whole-exome and whole-genome sequencing data"
  homepage "https://github.com/exomiser/Exomiser/"
  version "15.0.0"

  # Data release version is independent of the application version.
  # Update both constants when releasing a new version.
  DATA_VERSION = "2512"
  # DATA_BASE_URL = "https://data.monarchinitiative.org/exomiser/latest"
  DATA_BASE_URL = "https://g-879a9f.f5dc97.75bc.dn.glob.us/data"

  # Distribution zip from GitHub
  # Update the URL and sha256 checksum when a new version is released.
  url "https://github.com/exomiser/Exomiser/releases/download/#{version}/exomiser-cli-#{version}-distribution.zip"
  sha256 "33892fa8297be98d8594ef4bdc22735bd9e3a47f00310aef8ffe54f97c66bbe5"

  license "AGPL-3.0"

  # Exomiser requires Java 21 or above.
  depends_on "openjdk"

  # No compiled code — Exomiser ships as a pre-built JAR.
  def install
    libexec.install Dir["*"]

    # Hand-rolled wrapper script so we can bootstrap ~/.exomiser on first run.
    # write_jar_script cannot be used here as it doesn't support this logic,
    # and post_install is also sandboxed from writing to $HOME.
    # The wrapper runs as the user at invocation time, outside any sandbox.
    (bin/"exomiser").write <<~SHELL
      #!/bin/bash
      set -euo pipefail

      EXOMISER_HOME="${HOME}/.exomiser"
      CONFIG_FILE="${EXOMISER_HOME}/application.properties"
      TEMPLATE="#{libexec}/application.properties"

      # Bootstrap ~/.exomiser on first run.
      if [[ ! -f "${CONFIG_FILE}" ]]; then
        mkdir -p "${EXOMISER_HOME}/data"

        # Seed application.properties with correct data directory and versions.
        sed \
          -e "s|^#\\?\\s*exomiser\\.data-directory=.*|exomiser.data-directory=${EXOMISER_HOME}/data|" \
          -e "s|^#\\?\\s*exomiser\\.hg19\\.data-version=.*|exomiser.hg19.data-version=#{DATA_VERSION}|" \
          -e "s|^#\\?\\s*exomiser\\.hg38\\.data-version=.*|exomiser.hg38.data-version=#{DATA_VERSION}|" \
          -e "s|^#\\?\\s*exomiser\\.phenotype\\.data-version=.*|exomiser.phenotype.data-version=#{DATA_VERSION}|" \
          "${TEMPLATE}" > "${CONFIG_FILE}"

        echo "──────────────────────────────────────────────────────────"
        echo "Exomiser: first-run setup complete."
        echo "  Config : ${CONFIG_FILE}"
        echo "  Data   : ${EXOMISER_HOME}/data"
        echo "  Run 'brew info exomiser/tap/exomiser' for data download instructions."
        echo "──────────────────────────────────────────────────────────"
      fi

      exec "#{Formula["openjdk"].opt_bin}/java" \
        --sun-misc-unsafe-memory-access=allow \
        ${JAVA_TOOL_OPTIONS:-} \
        -Dspring.config.location="${CONFIG_FILE}" \
        -jar "#{libexec}/exomiser-cli-#{version}.jar" \
        "$@"
    SHELL
    chmod 0755, bin/"exomiser"
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

        exomiser analyse --analysis #{libexec}/examples/preset-exome-analysis.yml \
         --vcf #{libexec}/examples/Pfeiffer.vcf.gz --assembly hg19 \
         --sample #{libexec}/examples/pfeiffer-phenopacket.yml 

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
