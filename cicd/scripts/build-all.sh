#!/usr/bin/env bash
set -euo pipefail

image_tag="${1:-latest}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

environments=(
  golang
  java
  javascript
  python
  typescript
)

image_types=(
  validate
  build
)

for environment_name in "${environments[@]}"; do
  for image_type in "${image_types[@]}"; do
    "${script_dir}/build-image.sh" "${environment_name}" "${image_type}" "${image_tag}"
  done
done
