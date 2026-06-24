#!/usr/bin/env bash

set -euo pipefail

TUNNEL_NAME="devhill"
CLOUDFLARE_DIR="${HOME}/.cloudflared"
OUTPUT_DIR="./.cloudflared"

DOMAINS="devhill.top"

command -v cloudflared >/dev/null 2>&1 || {
  echo "Error: cloudflared is not installed or not on PATH." >&2
  echo "Install it: https://github.com/cloudflare/cloudflared/releases" >&2
  exit 1
}

[[ -d "${OUTPUT_DIR}" ]] && rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

CERT_PATH="${CLOUDFLARE_DIR}/cert.pem"
if [[ -f "$CERT_PATH" ]]; then
  echo "Already logged in (found $CERT_PATH). Skipping login step."
else
  echo "Opening browser to authenticate with Cloudflare..."
  cloudflared tunnel login
fi

if cloudflared tunnel list 2>/dev/null | awk '{print $2}' | grep -qx "$TUNNEL_NAME"; then
  echo "Tunnel '$TUNNEL_NAME' already exists. Skipping creation."
else
  echo "Creating tunnel '$TUNNEL_NAME'..."
  cloudflared tunnel create "$TUNNEL_NAME"
fi

TUNNEL_ID=$(cloudflared tunnel list -o json | python3 -c "
import json,sys
data = json.load(sys.stdin)
match = [t for t in data if t['name'] == '$TUNNEL_NAME']
if not match:
    sys.exit('Tunnel not found after creation attempt')
print(match[0]['id'])
")

DEFAULT_CREDS_PATH="${CLOUDFLARE_DIR}/${TUNNEL_ID}.json"
if [[ -f "${DEFAULT_CREDS_PATH}" ]]; then
  if cp "${DEFAULT_CREDS_PATH}" "${OUTPUT_DIR}/creds.json"; then
    echo "Copied credentials to ${OUTPUT_DIR}/creds.json"
  else
    echo "Could not copy credentials to ${OUTPUT_DIR}/creds.json"
  fi
else
  echo "Warning: credentials file not found at ${DEFAULT_CREDS_PATH}" >&2
  echo "If this tunnel already existed before this script ran, you may need" >&2
  echo "to locate its credentials file manually." >&2
fi

CONFIG_PATH="${OUTPUT_DIR}/config.yml"
{
  echo "tunnel: ${TUNNEL_ID}"
  echo "credentials-file: /etc/cloudflared/creds.json"
  echo
  echo "ingress:"
  i=0
  for hostname in $DOMAINS; do
      port=$((2000 + i))
      echo "  - hostname: ${hostname}"
      echo "    service: http://nginx:${port}"
      i=$((i + 1))
  done
  echo "  - service: http_status:404"
} > "$CONFIG_PATH"

echo "Wrote config to $CONFIG_PATH"

echo
echo "Routing DNS for configured hostnames..."
for hostname in $DOMAINS; do
  echo "  -> ${hostname}"
  cloudflared tunnel route dns "$TUNNEL_NAME" "$hostname" || echo "     (skip: route may already exist)"
done
echo
echo "Done. Review ${OUTPUT_DIR}/config.yml, then start the tunnel with:"
echo "  cloudflared tunnel --config ${OUTPUT_DIR}/config.yml run"
echo "or via your docker-compose.yml cloudflare-tunnel service."