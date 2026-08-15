#!/usr/bin/env bash
# Fetch llama.cpp's macOS arm64 build into mac-app/Vendor/llama/.
#
# The assistant runs its model NATIVELY rather than in Colima, because Colima
# is a Linux VM with no access to Metal. Measured on an M4 Pro with the same
# 1.5B model and the same 3,411-token prompt: 175 seconds in a container,
# 2.1 seconds natively. This script is what puts the native engine in place.
#
# The binaries are NOT committed. They are 25 MB of build output that would
# sit in every clone forever, and this repo already builds its container image
# from a recipe rather than shipping one — same reasoning. Run this once
# before building the app; `xcodegen` copies Vendor/llama into the bundle.
set -euo pipefail

# Pinned deliberately. An assistant whose engine changes under it between two
# builds is one whose measurements mean nothing.
BUILD="b10435"
ARCHIVE="llama-${BUILD}-bin-macos-arm64.tar.gz"
URL="https://github.com/ggml-org/llama.cpp/releases/download/${BUILD}/${ARCHIVE}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESTINATION="${HERE}/llama"

if [[ -x "${DESTINATION}/llama-server" ]]; then
  echo "✅ llama.cpp ${BUILD} is already in place (${DESTINATION})."
  echo "   Delete that folder and re-run to fetch it again."
  exit 0
fi

WORKING="$(mktemp -d)"
trap 'rm -rf "${WORKING}"' EXIT

echo "⬇️  Fetching llama.cpp ${BUILD} for macOS (arm64)…"
curl -fsSL -o "${WORKING}/${ARCHIVE}" "${URL}"

echo "📦 Unpacking…"
tar xzf "${WORKING}/${ARCHIVE}" -C "${WORKING}"

SOURCE="${WORKING}/llama-${BUILD}"
if [[ ! -x "${SOURCE}/llama-server" ]]; then
  echo "❌ That archive did not contain llama-server. Nothing was installed."
  exit 1
fi

mkdir -p "${DESTINATION}"
# -a keeps the symlinked dylib aliases as symlinks. Copying them as regular
# files works but doubles the size of the bundle for nothing.
cp -a "${SOURCE}/llama-server" "${DESTINATION}/"
cp -a "${SOURCE}"/lib*.dylib "${DESTINATION}/"

# The Metal backend is the entire reason for running natively. If it is
# missing, the app would still start and would quietly be slow, which is
# exactly the failure this whole design exists to avoid — so say so loudly.
if [[ ! -e "${DESTINATION}/libggml-metal.dylib" ]]; then
  echo "❌ No Metal backend in that build. The assistant would fall back to CPU."
  exit 1
fi

echo "✅ llama.cpp ${BUILD} installed into ${DESTINATION} ($(du -sh "${DESTINATION}" | cut -f1))."
