ARG BASE_IMAGE=eclipse-temurin:21-jdk-alpine
FROM ${BASE_IMAGE}

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    make \
    maven \
    openssh-client \
    tar \
    tzdata \
    unzip \
    zip \
  && update-ca-certificates

WORKDIR /workspace

CMD ["/bin/sh"]
