# syntax=docker/dockerfile:1

# ---- deps: instala solo dependencias de producción ----
FROM node:26.13.0-alpine3.24 AS deps
WORKDIR /app
COPY images/node-helloworld/src/package.json images/node-helloworld/src/package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts --no-audit --no-fund \
    && npm cache clean --force
# Quitar símbolos de debug del binario de node (~24MB menos)
RUN apk add --no-cache binutils \
    && strip /usr/local/bin/node

# ---- runtime: alpine + binario de node, sin npm/yarn/corepack ----
# La versión de alpine debe coincidir con la de la etapa deps (musl / libstdc++)
FROM alpine:3.24

LABEL org.opencontainers.image.title="node-helloworld" \
      org.opencontainers.image.description="Hello World en Node.js/Express para pruebas" \
      org.opencontainers.image.source="https://github.com/Brsalcedom/container-images" \
      org.opencontainers.image.authors="Bryan Salcedo <brsalcedom@gmail.com>" \
      org.opencontainers.image.licenses="ISC"

RUN apk add --no-cache libstdc++ libatomic \
    && addgroup -S -g 1000 node \
    && adduser -S -D -H -u 1000 -G node node

COPY --from=deps /usr/local/bin/node /usr/local/bin/node

WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY images/node-helloworld/src/package.json images/node-helloworld/src/index.js ./

ENV NODE_ENV=production \
    PORT=3000

USER 1000:1000
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["sh", "-c", "wget -qO- http://127.0.0.1:${PORT}/health/liveness > /dev/null || exit 1"]

CMD ["node", "index.js"]
