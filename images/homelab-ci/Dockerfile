# =========================
# Stage 1: downloader
# =========================
FROM debian:trixie-slim AS downloader
ARG TOFU_VERSION="1.10.3"
ARG KUBECTL_VERSION="v1.30.3"
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

RUN set -eux; \
case "$TARGETARCH" in \
  amd64) A="amd64" ;; \
  arm64) A="arm64" ;; \
  *) echo "Arch not supported: $TARGETARCH" && exit 1 ;; \
esac; \
curl -fsSL -o /usr/local/bin/kubectl \
  "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${A}/kubectl"; \
chmod +x /usr/local/bin/kubectl;

RUN set -eux; \
curl -fsSL https://taskfile.dev/install.sh | sh; \
mv bin/task /usr/local/bin/task; 

# =========================
# Stage 2: CI 
# =========================
FROM debian:trixie-slim AS ci
WORKDIR /workspace
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git openssh-client \
  && update-ca-certificates \
  && rm -rf /var/lib/apt/lists/*
COPY --from=downloader /usr/local/bin/tofu /usr/local/bin/tofu
COPY --from=downloader /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=downloader /usr/local/bin/task /usr/local/bin/task

ARG VERSION="dev"
LABEL org.opencontainers.image.title="homelab-ci (ci)" \
      org.opencontainers.image.description="Imagen CI con OpenTofu, kubectl, git, curl, ssh (con shell)" \
      org.opencontainers.image.source="https://github.com/brsalcedom/homelab-ci" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${VERSION}"