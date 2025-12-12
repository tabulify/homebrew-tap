class Tabulify < Formula
  desc "Tabulify CLI application"
  homepage "https://www.tabulify.com"
  url "https://github.com/tabulify/tabulify/releases/download/v2.0.0/tabulify-2.0.0-nojre.zip"
  version "2.0.0"
  sha256 "21fd98fc673b6203f87280a48d7fcc73dbf2564379e54fb4551f8cffe9c75383"
  license "Functional Source License (FSL)"

  head "https://github.com/tabulify/tabulify.git", branch: "main"

  
  depends_on "openjdk@17"

  def install

    # Install the software
    if build.head?
        # HEAD: install/build from the git repo
        # Install Tabulify Jars
        system "mvnw", "clean", "install", "-DskipTests"
        # Copy dependencies
        project = "cli-tabul"
        system "mvnw", "-Pdeps", "-pl", project
        # Assemble
        system "mvnw", "jreleaser:assemble", "-Djreleaser.config.file=jreleaser.yml", "-pl", project, "-Djreleaser.assemblers=javaArchive"
        # Install
        libexec.install Dir[project+"/target/jreleaser/assemble/tabulify-nojre/java-archive/work/tabulify-early-access-nojre/*"]
    else
        # Install from the zip
        libexec.install Dir["*"]
    end

    # Symlink
    bin.install_symlink "#{libexec}/bin/tabul" => "tabul"

    # Injecting JAVA_HOME in the header
    bin.children.each do |script|
        next unless script.file?
        original = File.read(script)
        modified = original.sub(
            /^#!\/usr\/bin\/env bash/,
            "#!/usr/bin/env bash\nJAVA_HOME=\"#{Formula["openjdk@17"].opt_prefix}\""
        )
        File.write(script, modified)
    end

  end

  # https://rubydoc.brew.sh/Formula#caveats-instance_method
  def caveats
    scripts_list = bin.children.map { |script| "  - #{script.basename}" }.join("\n")
    <<~EOS
      The following scripts have been installed:

      #{scripts_list}

    EOS
  end

  test do

    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail, and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test dockenv`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system bin/"program", "do", "something"`.

    output = shell_output("#{bin}/tabul --version")
    assert_match "2.0.0", output

  end

end
