#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../../.." && pwd)"
image_tag="${1:-latest}"

IMAGE_REPO_PREFIX="${IMAGE_REPO_PREFIX:-local}" \
  exec "${repo_root}/scripts/build-image.sh" java build "${image_tag}"
