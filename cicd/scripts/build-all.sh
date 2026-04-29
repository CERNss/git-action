#!/usr/bin/env bash
set -euo pipefail

image_tag="${1:-latest}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

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

build_environment_image() {
  local environment_name="$1"
  local image_type="$2"
  local version_file="${repo_root}/cicd-env/${environment_name}/versions.conf"
  local configured_extra_tags="${EXTRA_IMAGE_TAGS:-}"

  if [[ ! -f "${version_file}" ]]; then
    "${script_dir}/build-image.sh" "${environment_name}" "${image_type}" "${image_tag}"
    return
  fi

  while IFS='|' read -r version_label base_image tag_suffix is_default; do
    if [[ -z "${version_label}" || "${version_label}" == \#* ]]; then
      continue
    fi

    plain_extra_tags=""

    if [[ "${is_default}" == "true" ]]; then
      plain_extra_tags="${image_tag}"

      if [[ -n "${configured_extra_tags}" ]]; then
        plain_extra_tags="${plain_extra_tags},${configured_extra_tags}"
      fi
    fi

    BASE_IMAGE="${base_image}" \
    IMAGE_TAG_SUFFIX="${tag_suffix}" \
    EXTRA_IMAGE_TAGS="${configured_extra_tags}" \
    EXTRA_IMAGE_TAGS_PLAIN="${plain_extra_tags}" \
      "${script_dir}/build-image.sh" "${environment_name}" "${image_type}" "${image_tag}"
  done < "${version_file}"
}

for environment_name in "${environments[@]}"; do
  for image_type in "${image_types[@]}"; do
    build_environment_image "${environment_name}" "${image_type}"
  done
done
