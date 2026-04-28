#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "usage: $0 <environment> <validate|build> [tag]" >&2
  exit 1
fi

environment_name="$1"
image_type="$2"
image_tag="${3:-latest}"
push_image="${PUSH_IMAGE:-false}"
extra_image_tags_raw="${EXTRA_IMAGE_TAGS:-}"
oci_registry_url="${OCI_REGISTRY_URL:-docker.io}"
oci_namespace="${OCI_NAMESPACE:-${OCI_USERNAME:-}}"
target_platform="${TARGET_PLATFORM:-}"
target_platforms_raw="${TARGET_PLATFORMS:-}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workspace_root="$(cd "${repo_root}/.." && pwd)"
dockerfile_path="${repo_root}/cicd-env/${environment_name}/${image_type}/Dockerfile"
build_context="$(dirname "${dockerfile_path}")"
repository_name="${IMAGE_REPOSITORY_NAME:-}"

if [[ -z "${repository_name}" && -n "${GITHUB_REPOSITORY:-}" ]]; then
  repository_name="${GITHUB_REPOSITORY##*/}"
fi

if [[ -z "${repository_name}" ]]; then
  repository_name="$(basename "${workspace_root}")"
fi

to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

trim_spaces() {
  printf '%s' "$1" | tr -d '[:space:]'
}

is_docker_hub_registry() {
  case "$1" in
    docker.io|index.docker.io|registry-1.docker.io)
      return 0
      ;;
  esac

  return 1
}

repository_name="$(to_lower "${repository_name}")"
environment_name="$(to_lower "${environment_name}")"
image_type="$(to_lower "${image_type}")"

if [[ ! -f "${dockerfile_path}" ]]; then
  echo "dockerfile not found: ${dockerfile_path}" >&2
  exit 1
fi

resolve_image_repo_root() {
  if [[ -n "${IMAGE_REPO_PREFIX:-}" ]]; then
    printf '%s' "${IMAGE_REPO_PREFIX}"
    return
  fi

  if [[ "${push_image}" == "true" && -n "${oci_namespace}" ]]; then
    if is_docker_hub_registry "${oci_registry_url}"; then
      printf '%s' "${oci_namespace}"
    else
      printf '%s/%s/%s' "${oci_registry_url%/}" "${oci_namespace}" "${repository_name}"
    fi
    return
  fi

  printf '%s/%s' "local" "${repository_name}"
}

if [[ "${push_image}" == "true" && -z "${IMAGE_REPO_PREFIX:-}" && -z "${oci_namespace}" ]]; then
  echo "set OCI_USERNAME or OCI_NAMESPACE or IMAGE_REPO_PREFIX before pushing images" >&2
  exit 1
fi

image_repo_root="$(resolve_image_repo_root)"

resolve_image_name() {
  local requested_tag="$1"

  if [[ "${push_image}" == "true" && -z "${IMAGE_REPO_PREFIX:-}" ]] && \
     is_docker_hub_registry "${oci_registry_url}"; then
    printf '%s/%s-%s-cicd-%s:%s' \
      "${image_repo_root}" \
      "${repository_name}" \
      "${environment_name}" \
      "${image_type}" \
      "${requested_tag}"
    return
  fi

  printf '%s/%s/cicd-%s:%s' \
    "${image_repo_root}" \
    "${environment_name}" \
    "${image_type}" \
    "${requested_tag}"
}

image_name="${IMAGE_NAME_OVERRIDE:-$(resolve_image_name "${image_tag}")}"
extra_image_names=()
image_names=("${image_name}")

if [[ -n "${IMAGE_NAME_OVERRIDE:-}" && -n "${extra_image_tags_raw}" ]]; then
  echo "IMAGE_NAME_OVERRIDE cannot be combined with EXTRA_IMAGE_TAGS" >&2
  exit 1
fi

if [[ -n "${extra_image_tags_raw}" ]]; then
  IFS=',' read -r -a extra_image_tags <<< "${extra_image_tags_raw}"

  for extra_tag in "${extra_image_tags[@]-}"; do
    extra_tag="$(printf '%s' "${extra_tag}" | xargs)"

    if [[ -z "${extra_tag}" || "${extra_tag}" == "${image_tag}" ]]; then
      continue
    fi

    extra_image_name="$(resolve_image_name "${extra_tag}")"
    extra_image_names+=("${extra_image_name}")
    image_names+=("${extra_image_name}")
  done
fi

target_platforms="$(trim_spaces "${target_platforms_raw}")"
use_buildx="false"

if [[ -n "${target_platforms}" ]]; then
  use_buildx="true"
fi

docker_args=()

if [[ "${DOCKER_BUILD_PULL:-true}" == "true" ]]; then
  docker_args+=(--pull)
fi

if [[ -n "${target_platform}" && "${use_buildx}" != "true" ]]; then
  docker_args+=(--platform "${target_platform}")
fi

if [[ "${use_buildx}" == "true" ]]; then
  buildx_args=()

  if [[ -z "${target_platforms}" ]]; then
    echo "TARGET_PLATFORMS cannot be empty when buildx mode is enabled" >&2
    exit 1
  fi

  buildx_args+=(--platform "${target_platforms}")

  for tagged_image in "${image_names[@]}"; do
    buildx_args+=(-t "${tagged_image}")
  done

  if [[ "${push_image}" == "true" ]]; then
    buildx_args+=(--push)
  else
    if [[ "${target_platforms}" == *,* ]]; then
      echo "multi-platform buildx mode requires PUSH_IMAGE=true" >&2
      exit 1
    fi

    buildx_args+=(--load)
  fi

  docker buildx build \
    "${docker_args[@]}" \
    "${buildx_args[@]}" \
    -f "${dockerfile_path}" \
    "${build_context}"

  for tagged_image in "${image_names[@]}"; do
    if [[ "${push_image}" == "true" ]]; then
      echo "pushed image: ${tagged_image}"
    else
      echo "built image: ${tagged_image}"
    fi
  done

  exit 0
fi

docker build \
  "${docker_args[@]}" \
  -t "${image_name}" \
  -f "${dockerfile_path}" \
  "${build_context}"

echo "built image: ${image_name}"

for extra_image_name in "${extra_image_names[@]-}"; do
  if [[ -z "${extra_image_name}" ]]; then
    continue
  fi

  docker tag "${image_name}" "${extra_image_name}"
  echo "tagged image: ${extra_image_name}"
done

if [[ "${push_image}" == "true" ]]; then
  docker push "${image_name}"
  echo "pushed image: ${image_name}"

  for extra_image_name in "${extra_image_names[@]-}"; do
    if [[ -z "${extra_image_name}" ]]; then
      continue
    fi

    docker push "${extra_image_name}"
    echo "pushed image: ${extra_image_name}"
  done
fi
