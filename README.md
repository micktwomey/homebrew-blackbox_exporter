# homebrew-blackbox_exporter
Brew tap of https://github.com/prometheus/blackbox_exporter


## Installation

1. Install [homebrew](https://brew.sh/)
2. `brew tap micktwomey/blackbox_exporter`
3. `brew install blackbox_exporter`
  - optional: if you want the blackbox_exporter service to run as root add `--with-root`

## Notes

- The supplied blackbox_exporter.yml uses IPv4 by default
- blackbox_exporter's service can be run as root to allow for privileged socket access. Use `--with-root` to enable this option during install.
