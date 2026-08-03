#!/usr/bin/env bash
#
# Install Gate as a rootless Podman container with systemd.
#
# Usage: see --help

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
readonly REPO_ROOT
readonly DEPLOY_DIR="${REPO_ROOT}/deploy"
readonly GATE_DIR="${HOME}/.gate"
readonly CONFIG_DIR="${GATE_DIR}/config"
readonly DATA_DIR="${GATE_DIR}/data"
readonly QUADLET_DIR="${HOME}/.config/containers/systemd"

usage() {
  cat <<EOF
${SCRIPT_NAME} - Install Gate as a rootless Podman container

Creates ~/.gate/{config,data} and installs systemd Quadlet units.
Generates a default config.toml if none exists.

Usage: ${SCRIPT_NAME} [options]

Options:
  -h, --help          Show this help and exit
  -v, --verbose       Enable verbose output (shell trace)
      --image IMAGE   OCI image to install
                      (default: ghcr.io/murillo-consulting/gate:0.1.0)
      --pull POLICY   Pull policy: missing or always (default: missing)

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --image ghcr.io/murillo-consulting/gate:0.2.0
  ${SCRIPT_NAME} --pull always
  ${SCRIPT_NAME} --verbose

Environment:
  GATE_IMAGE        Default value for --image
  GATE_PULL_POLICY  Default value for --pull

Exit codes:
  0  success
  1  error (invalid option, missing dependency, or installation failure)
EOF
}

main() {
  local verbose=0
  local image="${GATE_IMAGE:-ghcr.io/murillo-consulting/gate:0.1.0}"
  local pull_policy="${GATE_PULL_POLICY:-missing}"

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      -v|--verbose)
        verbose=1
        shift
        ;;
      --image)
        if [[ "$#" -lt 2 || -z "$2" ]]; then
          echo "--image requires a value" >&2
          exit 1
        fi
        image="$2"
        shift 2
        ;;
      --image=*)
        image="${1#*=}"
        shift
        ;;
      --pull)
        if [[ "$#" -lt 2 || -z "$2" ]]; then
          echo "--pull requires a value" >&2
          exit 1
        fi
        pull_policy="$2"
        shift 2
        ;;
      --pull=*)
        pull_policy="${1#*=}"
        shift
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  if [[ ! "${image}" =~ ^[A-Za-z0-9._:/@-]+$ ]]; then
    echo "Invalid OCI image reference: ${image}" >&2
    exit 1
  fi

  case "${pull_policy}" in
    always|missing) ;;
    *)
      echo "Invalid pull policy: ${pull_policy} (expected: missing or always)" >&2
      exit 1
      ;;
  esac

  if [[ "${verbose}" -eq 1 ]]; then
    set -x
  fi

  local red green nc
  if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-}" != "dumb" ]; then
    red='\033[0;31m'
    green='\033[0;32m'
    nc='\033[0m'
  else
    red='' green='' nc=''
  fi

  echo -e "${green}Installing Gate as rootless Podman container...${nc}"

  if ! command -v podman &> /dev/null; then
    echo -e "${red}Podman not found. Please install first.${nc}"
    exit 1
  fi

  echo "Creating directories..."
  mkdir -p "${CONFIG_DIR}"
  mkdir -p "${DATA_DIR}"
  mkdir -p "${QUADLET_DIR}"

  if [ ! -f "${CONFIG_DIR}/config.toml" ]; then
    echo "Creating default config..."
    cat > "${CONFIG_DIR}/config.toml" << 'EOF'
# Gate Configuration
# See docs/reference/configuration.md for full reference.

[server]
host = "0.0.0.0"
port = 8080
log_level = "info"

[server.timeouts]
api_timeout_ms = 600000
connect_timeout_ms = 10000

[auth]
mode = "none"

[router]
default = "placeholder-model"

[security]
audit_dir = "/var/lib/gate/audit"

[dlp]
enabled = true
scan_input = true
scan_output = true
EOF
  fi

  echo "Installing systemd unit files..."
  local container_unit="${QUADLET_DIR}/gate.container"
  local container_unit_tmp
  container_unit_tmp="$(mktemp "${QUADLET_DIR}/.gate.container.XXXXXX")"
  trap 'rm -f -- "${container_unit_tmp:-}"' EXIT
  sed \
    -e "s|^Image=.*$|Image=${image}|" \
    -e "s|^Pull=.*$|Pull=${pull_policy}|" \
    "${DEPLOY_DIR}/gate.container" > "${container_unit_tmp}"
  chmod 0644 "${container_unit_tmp}"
  mv -f -- "${container_unit_tmp}" "${container_unit}"
  trap - EXIT
  cp "${DEPLOY_DIR}/gate.volume" "${QUADLET_DIR}/"
  echo "Configured image: ${image} (pull: ${pull_policy})"

  echo "Reloading systemd..."
  systemctl --user daemon-reload

  echo "Enabling Gate service..."
  systemctl --user enable gate

  echo ""
  echo -e "${green}Installation complete!${nc}"
  echo ""
  echo "To start Gate:"
  echo "  systemctl --user start gate"
  echo ""
  echo "To check status:"
  echo "  systemctl --user status gate"
  echo "  podman logs gate"
  echo "  curl http://localhost:8080/health"
  echo ""
  echo "Config directory: ${CONFIG_DIR}"
  echo "Data directory: ${DATA_DIR}"
}

main "$@"
