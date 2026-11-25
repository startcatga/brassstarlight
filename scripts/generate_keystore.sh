#!/usr/bin/env bash
# Generates a JKS keystore for signing the Android release build.
#
# Privacy: this script asks you for company details and nothing else. It does
# NOT read your username, machine name, IP address, location, or any other
# system information, and it does NOT auto-fill any field. Every value in the
# certificate comes only from what you type.
#
# Requirements: a JDK on PATH (provides `keytool`). Check with: keytool -help
#
# Output:
#   - starcart-upload.jks          (the keystore — keep it safe, never commit)
#   - starcart-keystore-base64.txt (base64 of the keystore for GitHub Secrets)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYSTORE_PATH="$SCRIPT_DIR/starcart-upload.jks"
BASE64_PATH="$SCRIPT_DIR/starcart-keystore-base64.txt"

read_required() {
  local prompt="$1" value=""
  while true; do
    read -r -p "$prompt: " value
    if [ -n "${value// }" ]; then printf '%s' "$value"; return; fi
    echo "  This field is required." >&2
  done
}

read_secret() {
  local prompt="$1" value=""
  while true; do
    read -r -s -p "$prompt: " value; echo >&2
    if [ "${#value}" -ge 6 ]; then printf '%s' "$value"; return; fi
    echo "  Use at least 6 characters." >&2
  done
}

echo ""
echo "=== Brass & Starlight Android signing keystore generator ==="
echo "Enter your company details. Nothing is read from your system."
echo ""

# Company details only (6 distinct fields for the certificate dname).
COMPANY_NAME="$(read_required "Company / app publisher name (CN)")"
ORG_UNIT="$(read_required "Organizational unit, e.g. Mobile (OU)")"
ORG="$(read_required "Organization / legal entity (O)")"
CITY="$(read_required "City / locality (L)")"
STATE="$(read_required "State / province (ST)")"
COUNTRY="$(read_required "Two-letter country code, e.g. US (C)")"

echo ""
ALIAS="$(read_required "Key alias, e.g. starcart-upload")"
VALIDITY="$(read_required "Validity in days (>= 10000 recommended)")"

echo ""
STORE_PASS="$(read_secret "Keystore (store) password")"
KEY_PASS="$(read_secret "Key password")"

DNAME="CN=$COMPANY_NAME, OU=$ORG_UNIT, O=$ORG, L=$CITY, ST=$STATE, C=$COUNTRY"

rm -f "$KEYSTORE_PATH"

echo ""
echo "Generating keystore..."

keytool -genkeypair -v \
  -keystore "$KEYSTORE_PATH" \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity "$VALIDITY" \
  -alias "$ALIAS" \
  -dname "$DNAME" \
  -storepass "$STORE_PASS" \
  -keypass "$KEY_PASS"

# Single-line base64 (no wrapping) so it pastes cleanly into a GitHub Secret.
if base64 --help 2>&1 | grep -q -- "-w"; then
  base64 -w0 "$KEYSTORE_PATH" > "$BASE64_PATH"
else
  base64 "$KEYSTORE_PATH" | tr -d '\n' > "$BASE64_PATH"
fi

echo ""
echo "Done."
echo "  Keystore : $KEYSTORE_PATH"
echo "  Base64   : $BASE64_PATH"
echo ""
echo "Add these GitHub repository secrets (Settings -> Secrets and variables -> Actions):"
echo "  STARCART_KEYSTORE_BASE64  = contents of starcart-keystore-base64.txt"
echo "  STARCART_STORE_PASSWORD   = the keystore (store) password you entered"
echo "  STARCART_KEY_ALIAS        = $ALIAS"
echo "  STARCART_KEY_PASSWORD     = the key password you entered"
echo ""
echo "Keep starcart-upload.jks and the passwords safe and OFFLINE."
echo "Both generated files are git-ignored — never commit them."
