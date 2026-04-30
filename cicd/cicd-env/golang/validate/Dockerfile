ARG BASE_IMAGE=golang:1.26-alpine
FROM ${BASE_IMAGE}

COPY go.mod /opt/cicd/golang/go.mod

RUN apk add --no-cache \
    bash \
    build-base \
    ca-certificates \
    curl \
    git \
    jq \
    make \
    openssh-client \
    tzdata \
    unzip \
    zip \
  && update-ca-certificates

WORKDIR /workspace

CMD ["/bin/sh"]
