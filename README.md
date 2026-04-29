# CI/CD environment images

This repository stores the base images used by `validate` and `build` jobs.

Each language environment has:

- its own `validate` image
- its own `build` image
- its own `Dockerfile`
- its own `build.sh` entrypoint
- optional template dependency files such as `requirements.txt`, `package.json`, and `go.mod`

Directory layout:

```text
cicd/
  action/
  cicd-env/
    golang/
      build/
      validate/
    java/
      build/
      validate/
    javascript/
      build/
      validate/
    python/
      build/
      validate/
    typescript/
      build/
      validate/
  scripts/
    build-image.sh
    build-all.sh
    docker-login.sh
    publish-all.sh
```

## Build a single image

```bash
./cicd/cicd-env/golang/validate/build.sh
./cicd/cicd-env/python/build/build.sh v1
```

Default tag: `latest`

Optional environment variables:

- `IMAGE_REPO_PREFIX`: full image repository root override. Local build defaults to `local/<repository>`, publish mode derives it from OCI settings.
- `IMAGE_REPOSITORY_NAME`: repository name segment, default is the current GitHub repository name or local directory name.
- `IMAGE_NAME_OVERRIDE`: full image name override
- `BASE_IMAGE`: optional exact base image override
- `DOCKER_BUILD_PULL`: whether to pull the latest base image before build, default `true`
- `TARGET_PLATFORM`: optional single-platform Docker build target, for example `linux/amd64`
- `TARGET_PLATFORMS`: optional buildx multi-platform target list, for example `linux/amd64,linux/arm64`
- `PUSH_IMAGE`: when `true`, push the built image after `docker build`
- `OCI_REGISTRY_URL`: target registry URL, default `docker.io`
- `OCI_NAMESPACE`: target namespace. Defaults to `OCI_USERNAME`
- `OCI_USERNAME`: registry login username
- `OCI_PASSWORD`: registry login password or token

## Build all images

```bash
./cicd/scripts/build-all.sh
./cicd/scripts/build-all.sh v1
```

## Publish all images

Default behavior publishes to Docker Hub.

```bash
OCI_USERNAME=my-user \
OCI_PASSWORD=my-token \
./cicd/scripts/publish-all.sh v1.0.0
```

When publishing with a version tag such as `v1.0.0`, the scripts also publish `latest` by default.
You can override that behavior with `EXTRA_IMAGE_TAGS`, for example `EXTRA_IMAGE_TAGS=stable,latest`.
When `TARGET_PLATFORMS` is not set, `publish-all.sh` defaults to `linux/amd64,linux/arm64`.

## Preloaded tooling and templates

- `python`: installs common CI tools and a baseline FastAPI test stack from `requirements.txt`, including `build`, `coverage`, `fastapi`, `httpx`, `pip-tools`, `pipenv`, `poetry`, `pytest==9.0.3`, `python-dotenv`, `requests`, `starlette`, `tox`, `twine`, `uvicorn`, and `virtualenv`
- `javascript`: activates `yarn@1.22.22` and `pnpm@10.8.0` through `corepack`, installs `cnpm`, and carries a template `package.json` at `/opt/cicd/javascript/package.json`
- `typescript`: activates `yarn@1.22.22` and `pnpm@10.8.0` through `corepack`, installs `cnpm`, `typescript`, `ts-node`, and `tsx`, and carries a template `package.json` at `/opt/cicd/typescript/package.json`
- `golang`: carries a template `go.mod` at `/opt/cicd/golang/go.mod`

Push to another OCI registry:

```bash
OCI_REGISTRY_URL=ghcr.io \
OCI_NAMESPACE=my-org \
OCI_USERNAME=my-user \
OCI_PASSWORD=my-token \
./cicd/scripts/publish-all.sh v1.0.0
```

Generated image naming rule:

```text
docker.io:      ${namespace}/${repository}-${language}-cicd-${image_type}:${tag}
non-docker.io:  ${registry}/${namespace}/${repository}/${language}/cicd-${image_type}:${tag}
```

Example:

```text
local/git-action/golang/cicd-validate:latest
my-user/git-action-golang-cicd-validate:v1
ghcr.io/my-org/git-action/python/cicd-build:v1
```

Default naming behavior:

- `IMAGE_REPO_PREFIX`, if set
- publish mode forces Docker Hub to use `${OCI_NAMESPACE}/${IMAGE_REPOSITORY_NAME}-${language}-cicd-${image_type}:${tag}`
- publish mode forces non-Docker-Hub registries to use `${OCI_REGISTRY_URL}/${OCI_NAMESPACE}/${IMAGE_REPOSITORY_NAME}/${language}/cicd-${image_type}:${tag}`
- `local/${IMAGE_REPOSITORY_NAME}` for build-only local usage

Publish tag behavior:

- `./cicd/scripts/publish-all.sh v1.0.0` publishes both `v1.0.0` and `latest`
- `./cicd/scripts/publish-all.sh latest` publishes only `latest`
- set `EXTRA_IMAGE_TAGS` to publish additional aliases

Platform behavior:

- `TARGET_PLATFORM=linux/amd64` uses classic single-platform `docker build`
- `TARGET_PLATFORMS=linux/amd64,linux/arm64` uses `docker buildx build`
- multi-platform `TARGET_PLATFORMS` requires `PUSH_IMAGE=true` because buildx can only `--load` single-platform results into the local Docker image store

Go and Python version behavior:

- `golang` publishes `go1.21`, `go1.22`, and `go1.23` variants from [versions.conf](/Users/cern/LocalDisk/D/Repo/infra/git-action/cicd/cicd-env/golang/versions.conf:1)
- `python` publishes `py3.10`, `py3.11`, and `py3.12` variants from [versions.conf](/Users/cern/LocalDisk/D/Repo/infra/git-action/cicd/cicd-env/python/versions.conf:1)
- default variants also keep the plain tags, so `v1.0.0` and `latest` still point to Go `1.22` and Python `3.12`
- non-default variants use version-suffixed tags such as `v1.0.0-go1.21`, `latest-go1.21`, `v1.0.0-py3.11`, and `latest-py3.11`

Notes:

- Docker Hub is detected by `docker.io`, `index.docker.io`, and `registry-1.docker.io`
- `OCI_NAMESPACE` defaults to `OCI_USERNAME`
- `IMAGE_REPOSITORY_NAME` defaults to the current GitHub repository name or local directory name

## GitHub Actions

The workflow [publish-images.yml](/Users/cern/LocalDisk/D/Repo/infra/git-action/.github/workflows/publish-images.yml:1) publishes all images automatically when a git tag is pushed. It also supports manual runs through `workflow_dispatch`, where `image_tag` must be provided explicitly.

Configure these repository settings before using it:

- Repository secrets: `OCI_PASSWORD` required
- Repository variables or secrets: `OCI_USERNAME`
- Repository variables or secrets: `OCI_REGISTRY_URL` optional, defaults to Docker Hub when empty
- Repository variables or secrets: `OCI_NAMESPACE` optional, defaults to `OCI_USERNAME`
- Repository variables or secrets: `IMAGE_REPO_PREFIX` optional exact repository prefix override
