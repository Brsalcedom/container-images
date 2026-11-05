# syntax=docker/dockerfile:1

# ---- gobuild: compila kubectl, helm y eksctl desde el código fuente ----
# Los binarios oficiales suelen traer un Go o dependencias con CVEs ya corregidos;
# compilarlos con el último Go (y subir dependencias puntuales) deja la imagen limpia.
# Compila de forma cruzada en la plataforma del runner: no necesita QEMU.
FROM --platform=$BUILDPLATFORM golang:1.27.3-alpine3.24 AS gobuild

ARG TARGETOS
ARG TARGETARCH
# renovate: datasource=github-releases depName=kubernetes/kubernetes
ARG KUBECTL_VERSION=v1.37.2
# renovate: datasource=github-releases depName=helm/helm
ARG HELM_VERSION=v4.3.1
# renovate: datasource=github-releases depName=eksctl-io/eksctl
ARG EKSCTL_VERSION=v0.231.0

# Dependencias a subir en cada herramienta (module@version). Vaciar cuando upstream
# publique una release que ya las incluya: go-bump.sh nunca baja de versión.
ARG KUBECTL_GO_BUMPS="golang.org/x/net@v0.60.0 golang.org/x/text@v0.42.0"
ARG HELM_GO_BUMPS=""
ARG EKSCTL_GO_BUMPS="github.com/klauspost/compress@v1.18.7 golang.org/x/net@v0.60.0"

ENV CGO_ENABLED=0 \
    GOTOOLCHAIN=local \
    GOFLAGS=-trimpath \
    GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH}

RUN apk add --no-cache git
COPY --chmod=755 scripts/go-bump.sh /usr/local/bin/go-bump.sh

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

WORKDIR /src/helm
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    set -eux; \
    git clone -q -c advice.detachedHead=false --depth 1 --branch "${HELM_VERSION}" \
      https://github.com/helm/helm .; \
    go-bump.sh ${HELM_GO_BUMPS}; \
    go build -o /out/helm \
      -ldflags "-s -w -X helm.sh/helm/v4/internal/version.version=${HELM_VERSION}" \
      ./cmd/helm

WORKDIR /src/eksctl
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    set -eux; \
    git clone -q -c advice.detachedHead=false --depth 1 --branch "${EKSCTL_VERSION}" \
      https://github.com/eksctl-io/eksctl .; \
    go-bump.sh ${EKSCTL_GO_BUMPS}; \
    go build -o /out/eksctl \
      -ldflags "-s -w -X github.com/weaveworks/eksctl/pkg/version.PreReleaseID=" \
      ./cmd/eksctl

# ---- gcloud: SDK sin python embebido (usa el python3 de alpine) ----
FROM alpine:3.24 AS gcloud

ARG TARGETARCH
# https://cloud.google.com/sdk/docs/release-notes
ARG GCLOUD_VERSION=592.0.0

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN apk add --no-cache curl python3

# Se eliminan: gsutil (reemplazado por `gcloud storage`), gcloud-crc32c (acelerador
# opcional compilado con un Go vulnerable), backups, instaladores y caches
RUN set -eux; \
    case "$TARGETARCH" in amd64) arch=x86_64 ;; arm64) arch=arm ;; *) exit 1 ;; esac; \
    curl -fsSL "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GCLOUD_VERSION}-linux-${arch}.tar.gz" \
      | tar -xz --no-same-owner -C /opt; \
    export CLOUDSDK_PYTHON=python3; \
    /opt/google-cloud-sdk/bin/gcloud config set --installation component_manager/disable_update_check true; \
    /opt/google-cloud-sdk/bin/gcloud config set --installation core/disable_usage_reporting true; \
    /opt/google-cloud-sdk/bin/gcloud components install gke-gcloud-auth-plugin --quiet; \
    rm -rf /opt/google-cloud-sdk/.install/.backup \
           /opt/google-cloud-sdk/platform/bundledpythonunix \
           /opt/google-cloud-sdk/platform/gsutil \
           /opt/google-cloud-sdk/bin/gsutil \
           /opt/google-cloud-sdk/bin/gcloud-crc32c \
           /opt/google-cloud-sdk/bin/anthoscli \
           /opt/google-cloud-sdk/RELEASE_NOTES \
           /opt/google-cloud-sdk/install.* \
           /opt/google-cloud-sdk/deb \
           /opt/google-cloud-sdk/rpm \
           /root/.config/gcloud; \
    find /opt/google-cloud-sdk -name '__pycache__' -type d -prune -exec rm -rf {} +

# ---- runtime ----
FROM alpine:3.24

LABEL org.opencontainers.image.title="kubetools" \
      org.opencontainers.image.description="Toolbox liviano para Kubernetes, AWS y GCP desde la CLI" \
      org.opencontainers.image.source="https://github.com/Brsalcedom/container-images" \
      org.opencontainers.image.authors="Bryan Salcedo <brsalcedom@gmail.com>"

RUN apk add --no-cache \
      aws-cli \
      bash \
      bash-completion \
      busybox-extras \
      ca-certificates \
      curl \
      git \
      jq \
      nmap \
      openssl \
      python3 \
      yq-go

COPY --from=gobuild /out/ /usr/local/bin/
COPY --from=gcloud /opt/google-cloud-sdk /opt/google-cloud-sdk

ENV PATH="/opt/google-cloud-sdk/bin:${PATH}" \
    CLOUDSDK_PYTHON=python3

RUN kubectl completion bash > /usr/share/bash-completion/completions/kubectl \
    && helm completion bash > /usr/share/bash-completion/completions/helm \
    && eksctl completion bash > /usr/share/bash-completion/completions/eksctl

WORKDIR /root
CMD ["/bin/bash"]
