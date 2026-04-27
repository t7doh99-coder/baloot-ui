#!/usr/bin/env bash
# Netlify runs on Linux; installs Flutter then builds web.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
INSTALL_DIR="${HOME}/.flutter_sdk_netlify"

if [[ ! -x "${INSTALL_DIR}/bin/flutter" ]]; then
  echo "Installing Flutter (${FLUTTER_VERSION})..."
  rm -rf "${INSTALL_DIR}"
  git clone --branch "${FLUTTER_VERSION}" --depth 1 \
    https://github.com/flutter/flutter.git "${INSTALL_DIR}"
fi

export PATH="${INSTALL_DIR}/bin:${PATH}"

flutter --version
flutter config --enable-web --no-analytics
flutter pub get
flutter build web --release --no-wasm-dry-run

echo "OK: output in build/web"
