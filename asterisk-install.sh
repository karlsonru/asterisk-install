#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Install Asterisk from source on Debian-based systems
#
# Usage:
#   chmod +x asterisk-install.sh
#   sudo ./asterisk-install.sh
#
# With custom version:
#   sudo ./asterisk-install.sh --asterisk-version=20.19.0
#
# With sample configuration files:
#   sudo ./asterisk-install.sh --asterisk-version=20.19.0 --with-samples
#
# With custom version and samples:
#   sudo ./asterisk-install.sh --asterisk-version=20.19.0 --with-samples
# ============================================================

ASTERISK_VERSION="-1"
WITH_SAMPLES=0

SRC_DIR="/usr/local/src"

export DEBIAN_FRONTEND=noninteractive

usage() {
    cat <<EOF
Usage:
  sudo $0 --asterisk-version=VERSION [--with-samples]

Options:
  --asterisk-version=VERSION   Required. Asterisk version to install
  --with-samples               Run 'make samples' after installation
  -h, --help                   Show this help

Examples:
  sudo $0 --asterisk-version=20.19.0
  sudo $0 --asterisk-version=20.19.0 --with-samples
EOF
}

for arg in "$@"; do
    case "${arg}" in
        --asterisk-version=*)
            ASTERISK_VERSION="${arg#*=}"
            ;;
        --with-samples)
            WITH_SAMPLES=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "[ERROR] Unknown argument: ${arg}"
            usage
            exit 1
            ;;
    esac
done

if [[ "${ASTERISK_VERSION}" == "-1" ]]; then
    echo "[ERROR] --asterisk-version is required"
    usage
    exit 1
fi

if [[ -z "${ASTERISK_VERSION}" ]]; then
    echo "[ERROR] --asterisk-version cannot be empty"
    exit 1
fi

ARCHIVE="asterisk-${ASTERISK_VERSION}.tar.gz"
URL="https://downloads.asterisk.org/pub/telephony/asterisk/releases/${ARCHIVE}"
BUILD_DIR="${SRC_DIR}/asterisk-${ASTERISK_VERSION}"

if [[ "${EUID}" -ne 0 ]]; then
    echo "[ERROR] Run as root:"
    echo "        sudo $0"
    exit 1
fi

echo "[INFO] Installing Asterisk ${ASTERISK_VERSION}"

if [[ "${WITH_SAMPLES}" -eq 1 ]]; then
    echo "[INFO] Sample configuration installation: enabled"
else
    echo "[INFO] Sample configuration installation: disabled"
fi

echo "[INFO] Installing bootstrap packages"
apt-get update
apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    tar \
    build-essential \
    file

echo "[INFO] Preparing source directory"
mkdir -p "${SRC_DIR}"
cd "${SRC_DIR}"

if [[ -d "${BUILD_DIR}" ]]; then
    echo "[INFO] Removing existing build directory: ${BUILD_DIR}"
    rm -rf "${BUILD_DIR}"
fi

echo "[INFO] Downloading ${URL}"
wget -O "${ARCHIVE}" "${URL}"

echo "[INFO] Extracting source archive"
tar xzf "${ARCHIVE}"
rm -f "${ARCHIVE}"

cd "${BUILD_DIR}"

echo "[INFO] Installing Asterisk build prerequisites"

set +e
contrib/scripts/install_prereq install
PREREQ_EXIT_CODE=$?
set -e

if [[ "${PREREQ_EXIT_CODE}" -ne 0 ]]; then
    echo "[WARN] install_prereq exited with code ${PREREQ_EXIT_CODE}"
    echo "[WARN] Trying to continue. ./configure will verify required dependencies."
fi


echo "[INFO] Configuring Asterisk"
./configure

echo "[INFO] Building Asterisk"
make -j"$(nproc)"

echo "[INFO] Installing Asterisk"
make install

if [[ "${WITH_SAMPLES}" -eq 1 ]]; then
    echo "[INFO] Installing sample configuration files"
    make samples
else
    echo "[INFO] Skipping sample configuration files"
fi

echo "[INFO] Installing initialization scripts"
make config

echo "[INFO] Installing logrotate configuration"
make install-logrotate

echo "[INFO] Cleaning source build directory"
cd "${SRC_DIR}"
rm -rf "${BUILD_DIR}"

echo "[INFO] Asterisk installation completed"
asterisk -V || true

echo
echo "Asterisk installed but not started."
echo
echo "Start manually when needed:"
echo "  systemctl start asterisk"
echo
echo "Check status:"
echo "  systemctl status asterisk"
echo
echo "Connect to CLI after start:"
echo "  asterisk -rvvv"
