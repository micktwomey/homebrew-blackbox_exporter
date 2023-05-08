class BlackboxExporter < Formula
  desc "Prometheus exporter for machine metrics"
  homepage "https://prometheus.io/"
  url "https://github.com/prometheus/blackbox_exporter/archive/refs/tags/v0.23.0.tar.gz"
  sha256 "516e36badac48f25ff905cc7561ad9013db40ac22194f8ad2821779c29a441a4"
  license "Apache-2.0"

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/prometheus/common/version.Version=#{version}
      -X github.com/prometheus/common/version.BuildUser=Homebrew
    ]
    system "go", "build", *std_go_args(ldflags: ldflags)

    (buildpath/"blackbox_exporter.args").write <<~EOS
      --config.file=#{etc}/blackbox_exporter.yml
    EOS

    (buildpath/"blackbox_exporter.yml").write <<~EOS
      modules:
        http_2xx:
          prober: http
          http:
            preferred_ip_protocol: ip4
        http_post_2xx:
          prober: http
          http:
            method: POST
            preferred_ip_protocol: ip4
        tcp_connect:
          prober: tcp
          tcp:
            preferred_ip_protocol: ip4
        pop3s_banner:
          prober: tcp
          tcp:
            query_response:
            - expect: "^+OK"
            tls: true
            tls_config:
              insecure_skip_verify: false
            preferred_ip_protocol: ip4
        grpc:
          prober: grpc
          grpc:
            tls: true
            preferred_ip_protocol: "ip4"
        grpc_plain:
          prober: grpc
          grpc:
            tls: false
            service: "service1"
            preferred_ip_protocol: ip4
        ssh_banner:
          prober: tcp
          tcp:
            query_response:
            - expect: "^SSH-2.0-"
            - send: "SSH-2.0-blackbox-ssh-check"
            preferred_ip_protocol: ip4
        irc_banner:
          prober: tcp
          tcp:
            query_response:
            - send: "NICK prober"
            - send: "USER prober prober prober :prober"
            - expect: "PING :([^ ]+)"
              send: "PONG ${1}"
            - expect: "^:[^ ]+ 001"
            preferred_ip_protocol: ip4
        icmp:
          prober: icmp
          icmp:
            preferred_ip_protocol: ip4
        icmp_ttl5:
          prober: icmp
          timeout: 5s
          icmp:
            ttl: 5
            preferred_ip_protocol: ip4
    EOS

    etc.install "blackbox_exporter.args", "blackbox_exporter.yml"

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
    require_root true
    log_path var/"log/blackbox_exporter.log"
    error_log_path var/"log/blackbox_exporter.err.log"
  end

  test do
    assert_match "blackbox_exporter", shell_output("#{bin}/blackbox_exporter --version 2>&1")

    fork { exec bin/"blackbox_exporter" }
    sleep 2
    assert_match "# HELP", shell_output("curl -s localhost:9115/metrics")
  end
end
