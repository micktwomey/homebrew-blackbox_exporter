# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class BlackboxExporter < Formula
  desc "Prometheus exporter for machine metrics"
  homepage "https://prometheus.io/"
  url "https://github.com/prometheus/blackbox_exporter/archive/refs/tags/v0.23.0.tar.gz"
  sha256 "516e36badac48f25ff905cc7561ad9013db40ac22194f8ad2821779c29a441a4"
  license "Apache-2.0"

  depends_on "go" => :build

  def install
    dflags = %W[
      -s -w
      -X github.com/prometheus/common/version.Version=#{version}
      -X github.com/prometheus/common/version.BuildUser=Homebrew
    ]
    system "go", "build", *std_go_args(ldflags: ldflags)

    touch etc/"blackbox_exporter.args"

    (bin/"blackbox_exporter_brew_services").write <<~EOS
      #!/bin/bash
      exec #{bin}/blackbox_exporter $(<#{etc}/blackbox_exporter.args)
    EOS
  end

  def caveats
    <<~EOS
      When run from `brew services`, `blackbox_exporter` is run from
      `blackbox_exporter_brew_services` and uses the flags in:
        #{etc}/blackbox_exporter.args
    EOS
  end

  service do
    run [opt_bin/"blackbox_exporter_brew_services"]
    keep_alive false
    log_path var/"log/blackbox_exporter.log"
    error_log_path var/"log/blackbox_exporter.err.log"
  end

  test do
    assert_match "blackbox_exporter", shell_output("#{bin}/blackbox_exporter --version 2>&1")

    fork { exec bin/"blackbox_exporter" }
    sleep 2
    assert_match "# HELP", shell_output("curl -s localhost:9100/metrics")
  end
end
