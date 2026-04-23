#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SUPPORT_DIR="$HOME/Library/Application Support/com.todolist.app/local-signing"
KEYCHAIN_PATH="$HOME/Library/Keychains/todo-list-local-dev.keychain-db"
KEYCHAIN_PASSWORD_FILE="$SUPPORT_DIR/keychain-password"
ENV_FILE="$SUPPORT_DIR/env.sh"
CERT_NAME="Todo List Local Dev"

mkdir -p "$SUPPORT_DIR"

if [[ ! -f "$KEYCHAIN_PASSWORD_FILE" ]]; then
  openssl rand -hex 24 >"$KEYCHAIN_PASSWORD_FILE"
fi
KEYCHAIN_PASSWORD="$(<"$KEYCHAIN_PASSWORD_FILE")"

ensure_keychain() {
  if [[ ! -f "$KEYCHAIN_PATH" ]]; then
    security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
    security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
  fi

  security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
}

matching_certificate_count() {
  security find-certificate -a -c "$CERT_NAME" -Z "$KEYCHAIN_PATH" 2>/dev/null | grep -c "SHA-1 hash:"
}

reset_keychain_if_needed() {
  if [[ ! -f "$KEYCHAIN_PATH" ]]; then
    return
  fi

  local count
  count="$(matching_certificate_count || true)"
  if [[ "$count" -le 1 ]]; then
    return
  fi

  security delete-keychain "$KEYCHAIN_PATH" >/dev/null 2>&1 || rm -f "$KEYCHAIN_PATH"
}

ensure_search_list() {
  local current_raw
  current_raw="$(security list-keychains -d user)"
  if [[ "$current_raw" == *"$KEYCHAIN_PATH"* ]]; then
    return
  fi

  local keychains=("$KEYCHAIN_PATH")
  while IFS= read -r line; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%\"}"
    line="${line#\"}"
    [[ -n "$line" ]] && keychains+=("$line")
  done < <(printf '%s\n' "$current_raw")

  security list-keychains -d user -s "${keychains[@]}"
}

identity_exists() {
  [[ "$(matching_certificate_count || true)" -eq 1 ]]
}

identity_sha1() {
  security find-certificate -a -c "$CERT_NAME" -Z "$KEYCHAIN_PATH" 2>/dev/null \
    | awk '/SHA-1 hash:/ { print $3; exit }'
}

create_identity() {
  local temp_dir
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' RETURN

  cat >"$temp_dir/openssl.cnf" <<'EOF'
[ req ]
default_bits = 2048
distinguished_name = dn
x509_extensions = exts
prompt = no

[ dn ]
CN = Todo List Local Dev
O = Local Development
OU = Todo List

[ exts ]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
EOF

  openssl req \
    -x509 \
    -newkey rsa:2048 \
    -sha256 \
    -days 3650 \
    -nodes \
    -config "$temp_dir/openssl.cnf" \
    -keyout "$temp_dir/key.pem" \
    -out "$temp_dir/cert.pem" >/dev/null 2>&1

  local import_password
  import_password="$(openssl rand -hex 12)"
  openssl pkcs12 \
    -export \
    -inkey "$temp_dir/key.pem" \
    -in "$temp_dir/cert.pem" \
    -out "$temp_dir/cert.p12" \
    -name "$CERT_NAME" \
    -passout "pass:$import_password" >/dev/null 2>&1

  security import "$temp_dir/cert.p12" \
    -k "$KEYCHAIN_PATH" \
    -P "$import_password" \
    -f pkcs12 \
    -A \
    -T /usr/bin/codesign \
    -T /usr/bin/security >/dev/null

  security set-key-partition-list \
    -S apple-tool:,apple: \
    -s \
    -k "$KEYCHAIN_PASSWORD" \
    "$KEYCHAIN_PATH" >/dev/null
}

write_env_file() {
  local identity_hash
  identity_hash="$(identity_sha1)"
  cat >"$ENV_FILE" <<EOF
export TODO_LIST_SIGNING_IDENTITY="$CERT_NAME"
export TODO_LIST_SIGNING_IDENTITY_HASH="$identity_hash"
export TODO_LIST_SIGNING_KEYCHAIN="$KEYCHAIN_PATH"
EOF
}

reset_keychain_if_needed
ensure_keychain
ensure_search_list

if ! identity_exists; then
  create_identity
fi

write_env_file

if [[ "${1:-}" != "--quiet" ]]; then
  echo "Local signing identity ready:"
  echo "  identity: $CERT_NAME"
  echo "  keychain: $KEYCHAIN_PATH"
fi
