#!/usr/bin/env bash

OUTPUT_DIR="./.cloudflared"
DEFAULT_CREDS_PATH="${HOME}/.cloudflared/creds.json"

[[ -d "${OUTPUT_DIR}" ]] && rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

if [[ -f "${DEFAULT_CREDS_PATH}" ]]; then
  sudo cp "${DEFAULT_CREDS_PATH}" "${OUTPUT_DIR}/creds.json"
  echo "Copied credentials to ${OUTPUT_DIR}/creds.json"
else
  echo "Warning: credentials file not found at $DEFAULT_CREDS_PATH" >&2
  echo "If this tunnel already existed before this script ran, you may need" >&2
  echo "to locate its credentials file manually." >&2
fi