# syntax=docker/dockerfile:1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

# ---- builder: install linode-cli into an isolated virtualenv ----
FROM alpine:3.24@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf AS builder

# renovate: datasource=pypi depName=linode-cli
ARG LINODE_CLI_VERSION=5.70.0
# renovate: datasource=pypi depName=boto3
ARG BOTO3_VERSION=1.43.124

RUN apk add --no-cache python3

RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir \
         "linode-cli==${LINODE_CLI_VERSION}" \
         "boto3==${BOTO3_VERSION}" \
    && /opt/venv/bin/pip uninstall -y pip \
    && find /opt/venv -name '__pycache__' -type d -prune -exec rm -rf {} +

# ---- runtime: only Alpine's python3 + the virtualenv, no pip ----
FROM alpine:3.24@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf

LABEL org.opencontainers.image.title="linode-cli" \
      org.opencontainers.image.description="Lightweight linode-cli image (includes boto3 for Object Storage)" \
      org.opencontainers.image.source="https://github.com/Brsalcedom/container-images" \
      org.opencontainers.image.authors="Bryan Salcedo <brsalcedom@gmail.com>" \
      org.opencontainers.image.licenses="MIT"

RUN apk add --no-cache python3 ca-certificates \
    && adduser -D -u 1000 linode

COPY --from=builder /opt/venv /opt/venv

ENV PATH="/opt/venv/bin:${PATH}" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

USER 1000:1000
WORKDIR /home/linode

ENTRYPOINT ["linode-cli"]
CMD ["--help"]
