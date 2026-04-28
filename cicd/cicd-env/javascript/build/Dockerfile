ARG BASE_IMAGE=node:20-alpine
FROM ${BASE_IMAGE}

COPY package.json /opt/cicd/javascript/package.json

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    g++ \
    git \
    jq \
    libc6-compat \
    make \
    openssh-client \
    python3 \
    tzdata \
    unzip \
    zip \
  && corepack enable \
  && corepack prepare yarn@1.22.22 --activate \
  && corepack prepare pnpm@10.8.0 --activate \
  && npm install --global cnpm \
  && update-ca-certificates

WORKDIR /workspace

CMD ["/bin/sh"]
