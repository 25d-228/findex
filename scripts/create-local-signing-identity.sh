#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IDENTITY="${1:-Findex Local Code Signing}"
KEYCHAIN="${HOME}/Library/Keychains/login.keychain-db"
WORK_DIR="$ROOT/build/LocalSigning"

if security find-identity -v -p codesigning | grep -F "\"$IDENTITY\"" >/dev/null; then
  echo "$IDENTITY"
  exit 0
fi

mkdir -p "$WORK_DIR"

cat > "$WORK_DIR/openssl.cnf" <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = codesign_ext
prompt = no

[req_distinguished_name]
CN = $IDENTITY

[codesign_ext]
basicConstraints = critical,CA:true
keyUsage = critical,digitalSignature,keyCertSign
extendedKeyUsage = codeSigning
subjectKeyIdentifier = hash
EOF

openssl req \
  -newkey rsa:2048 \
  -nodes \
  -x509 \
  -days 3650 \
  -config "$WORK_DIR/openssl.cnf" \
  -keyout "$WORK_DIR/FindexLocalCodeSigning.key" \
  -out "$WORK_DIR/FindexLocalCodeSigning.crt"

openssl pkcs12 \
  -export \
  -name "$IDENTITY" \
  -inkey "$WORK_DIR/FindexLocalCodeSigning.key" \
  -in "$WORK_DIR/FindexLocalCodeSigning.crt" \
  -out "$WORK_DIR/FindexLocalCodeSigning.p12" \
  -passout pass:

security import "$WORK_DIR/FindexLocalCodeSigning.p12" \
  -k "$KEYCHAIN" \
  -P "" \
  -A

security add-trusted-cert \
  -r trustRoot \
  -p codeSign \
  -k "$KEYCHAIN" \
  "$WORK_DIR/FindexLocalCodeSigning.crt"

echo "$IDENTITY"
