############################################
# Stage: tofu-downloader
############################################
FROM alpine:3.22 AS tofu-downloader
ARG TOFU_VERSION="1.10.3"
ARG TARGETARCH

RUN apk add --no-cache curl tar openssl
RUN set -eux; \
    case "$TARGETARCH" in \
      amd64)  TOFU_ARCH="amd64"  ;; \
      arm64)  TOFU_ARCH="arm64"  ;; \
      *)      echo "Architecture not supported: $TARGETARCH" && exit 1 ;; \
    esac; \
    TOFU_URL="https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_linux_${TOFU_ARCH}.tar.gz"; \
    curl -fsSL -o /tmp/tofu.tgz "$TOFU_URL"; \
    tar -xzf /tmp/tofu.tgz -C /tmp; \
    install -m 0755 /tmp/tofu /tofu

############################################
# Stage: final
############################################
FROM alpine:3.22
ARG TOFU_VERSION="1.10.3"
RUN apk add --no-cache \
      curl \
      git \
      openssl \
      ca-certificates \
    && update-ca-certificates

COPY --from=tofu-downloader /tofu /usr/local/bin/tofu

WORKDIR /workspace

# OCI Labels
LABEL org.opencontainers.image.title="homelab-ci" \
      org.opencontainers.image.description="Imagen mínima para workflows de homelab-iac (OpenTofu, curl, openssl, ca-certificates)" \
      org.opencontainers.image.source="https://github.com/brsalcedom/homelab-ci" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${TOFU_VERSION}"
