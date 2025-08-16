# =========================
# Stage 1: downloader
# =========================
FROM debian:bookworm-slim AS downloader
ARG TOFU_VERSION="1.10.3"
ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl tar \
 && rm -rf /var/lib/apt/lists/*

  RUN set -eux; \
  case "$TARGETARCH" in \
    amd64) A="amd64" ;; \
    arm64) A="arm64" ;; \
    *) echo "Arch not supported: $TARGETARCH" && exit 1 ;; \
  esac; \
  curl -fsSL -o /tmp/tofu.tgz \
    "https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_linux_${A}.tar.gz"; \
  tar -xzf /tmp/tofu.tgz -C /usr/local/bin tofu; 

# =========================
# Stage 2: CI 
# =========================
FROM debian:bookworm-slim AS ci
WORKDIR /workspace
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git openssh-client \
  && update-ca-certificates \
  && rm -rf /var/lib/apt/lists/*
COPY --from=downloader /usr/local/bin/tofu /usr/local/bin/tofu
ARG VERSION="dev"
LABEL org.opencontainers.image.title="homelab-ci (ci)" \
      org.opencontainers.image.description="Imagen CI con OpenTofu, git, curl, ssh (con shell)" \
      org.opencontainers.image.source="https://github.com/brsalcedom/homelab-ci" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${VERSION}"