ARG BASE_IMAGE=python:3.14-alpine
FROM ${BASE_IMAGE}

COPY requirements.txt /opt/cicd/python/requirements.txt

RUN apk add --no-cache \
    bash \
    build-base \
    ca-certificates \
    curl \
    git \
    jq \
    libffi-dev \
    make \
    openssh-client \
    openssl-dev \
    tzdata \
    unzip \
    zip \
  && update-ca-certificates \
  && python -m pip install --upgrade pip setuptools wheel \
  && python -m pip install -r /opt/cicd/python/requirements.txt

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /workspace

CMD ["/bin/sh"]
