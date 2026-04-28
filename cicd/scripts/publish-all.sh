#!/usr/bin/env bash
set -euo pipefail

image_tag="${1:-latest}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
extra_image_tags="${EXTRA_IMAGE_TAGS:-}"
target_platforms="${TARGET_PLATFORMS:-}"

if [[ -z "${extra_image_tags}" && "${image_tag}" != "latest" ]]; then
  extra_image_tags="latest"
fi

if [[ -z "${target_platforms}" ]]; then
  target_platforms="linux/amd64,linux/arm64"
fi

"${script_dir}/docker-login.sh"
PUSH_IMAGE=true EXTRA_IMAGE_TAGS="${extra_image_tags}" TARGET_PLATFORMS="${target_platforms}" "${script_dir}/build-all.sh" "${image_tag}"
