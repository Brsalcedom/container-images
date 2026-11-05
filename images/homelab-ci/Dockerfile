# syntax=docker/dockerfile:1

# =========================
# Stage 1: build Go tools from source
# =========================
# Official release binaries often ship with a Go toolchain or dependencies that
# already have fixed CVEs. Building them with the latest Go (and bumping specific
# dependencies) keeps the image clean. Cross-compiles on the build platform: no QEMU.
FROM --platform=$BUILDPLATFORM golang:1.27.3-alpine3.24 AS gobuild

ARG TARGETOS
ARG TARGETARCH
# renovate: datasource=github-releases depName=opentofu/opentofu
ARG TOFU_VERSION=v1.13.8
# renovate: datasource=github-releases depName=kubernetes/kubernetes
ARG KUBECTL_VERSION=v1.37.2
# renovate: datasource=github-releases depName=go-task/task
ARG TASK_VERSION=v3.54.0

# Dependencies to bump per tool (module@version). Clear them once upstream ships a
# release that includes them: go-bump.sh never downgrades.
ARG TOFU_GO_BUMPS="github.com/go-jose/go-jose/v4@v4.1.6 golang.org/x/mod@v0.40.0 golang.org/x/net@v0.60.0 google.golang.org/grpc@v1.83.2"
ARG KUBECTL_GO_BUMPS="golang.org/x/net@v0.60.0 golang.org/x/text@v0.42.0"
ARG TASK_GO_BUMPS="github.com/go-jose/go-jose/v4@v4.1.6 golang.org/x/net@v0.60.0"

ENV CGO_ENABLED=0 \
    GOTOOLCHAIN=local \
    GOFLAGS=-trimpath \
    GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH}

RUN apk add --no-cache git
COPY --chmod=755 scripts/go-bump.sh /usr/local/bin/go-bump.sh

WORKDIR /src/tofu
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    set -eux; \
    git clone -q -c advice.detachedHead=false --depth 1 --branch "${TOFU_VERSION}" \
      https://github.com/opentofu/opentofu .; \
    go-bump.sh ${TOFU_GO_BUMPS}; \
    go build -o /out/tofu \
      -ldflags "-s -w -X github.com/opentofu/opentofu/version.dev=no" \
      ./cmd/tofu

WORKDIR /src/kubernetes
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    set -eux; \
    git clone -q -c advice.detachedHead=false --depth 1 --branch "${KUBECTL_VERSION}" \
      https://github.com/kubernetes/kubernetes .; \
    export GOWORK=off; \
    go-bump.sh ${KUBECTL_GO_BUMPS}; \
    go build -mod=mod -o /out/kubectl \
      -ldflags "-s -w \
        -X k8s.io/client-go/pkg/version.gitVersion=${KUBECTL_VERSION} \
        -X k8s.io/component-base/version.gitVersion=${KUBECTL_VERSION}" \
      ./cmd/kubectl

WORKDIR /src/task
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    set -eux; \
    git clone -q -c advice.detachedHead=false --depth 1 --branch "${TASK_VERSION}" \
      https://github.com/go-task/task .; \
    go-bump.sh ${TASK_GO_BUMPS}; \
    go build -o /out/task \
      -ldflags "-s -w -X github.com/go-task/task/v3/internal/version.version=${TASK_VERSION}" \
      ./cmd/task

# =========================
# Stage 2: CI
# =========================
FROM debian:trixie-slim AS ci

LABEL org.opencontainers.image.title="homelab-ci" \
      org.opencontainers.image.description="CI image with OpenTofu, kubectl, Task, git, curl, ssh and envsubst" \
      org.opencontainers.image.source="https://github.com/Brsalcedom/container-images" \
      org.opencontainers.image.licenses="MIT"

# Non-root user `ci` (1000:1000) that owns /workspace. Numeric UID in USER so that
# Kubernetes can verify `runAsNonRoot` without resolving /etc/passwd.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates curl git openssh-client gettext-base \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g 1000 ci \
    && useradd -m -u 1000 -g ci -s /bin/bash ci \
    && install -d -o ci -g ci /workspace

COPY --from=gobuild /out/ /usr/local/bin/

# Mounted repositories usually belong to a different UID: let git operate on them
RUN git config --system --add safe.directory '*'

USER 1000:1000
WORKDIR /workspace
