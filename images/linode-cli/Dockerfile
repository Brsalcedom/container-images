# syntax=docker/dockerfile:1

# ---- builder: instala linode-cli en un virtualenv aislado ----
FROM alpine:3.24 AS builder

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

# ---- runtime: solo python3 de alpine + el virtualenv, sin pip ----
FROM alpine:3.24

LABEL org.opencontainers.image.title="linode-cli" \
      org.opencontainers.image.description="Imagen liviana con linode-cli (incluye boto3 para Object Storage)" \
      org.opencontainers.image.source="https://github.com/Brsalcedom/container-images" \
      org.opencontainers.image.authors="Bryan Salcedo <brsalcedom@gmail.com>"

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
