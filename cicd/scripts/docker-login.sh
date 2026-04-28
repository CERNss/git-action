#!/usr/bin/env bash
set -euo pipefail

oci_registry_url="${OCI_REGISTRY_URL:-docker.io}"

if [[ -z "${OCI_USERNAME:-}" || -z "${OCI_PASSWORD:-}" ]]; then
  echo "OCI_USERNAME and OCI_PASSWORD are required for docker login" >&2
  exit 1
fi

login_target="${oci_registry_url%/}"

case "${login_target}" in
  docker.io|index.docker.io|registry-1.docker.io)
    printf '%s' "${OCI_PASSWORD}" | docker login \
      --username "${OCI_USERNAME}" \
      --password-stdin
    ;;
  *)
    printf '%s' "${OCI_PASSWORD}" | docker login "${login_target}" \
      --username "${OCI_USERNAME}" \
      --password-stdin
    ;;
esac
