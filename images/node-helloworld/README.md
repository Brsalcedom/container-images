## Info

Hello World en Node.js + Express para pruebas (por ejemplo, para validar despliegues en Kubernetes).

* Node.js 26 LTS sobre Alpine 3.24, sin npm/yarn en la imagen final y con el binario de node sin símbolos de debug
* Express 5
* Corre como usuario no-root (`1000:1000`) en el puerto `3000` (configurable con `PORT`)
* Endpoints de salud para probes de Kubernetes: `/health/liveness`, `/health/readiness`, `/health/startup`
* `HEALTHCHECK` de Docker incluido y apagado limpio con `SIGTERM`
* Multi-arch (amd64/arm64)

## Tags

| Tag | Contenido |
|---|---|
| `2.0.0` | versión exacta e inmutable (recomendado para manifiestos de Kubernetes) |
| `2.0` | último patch de la 2.0 |
| `2` | último minor/patch de la 2 |
| `latest` | última versión publicada |

Cada versión se escanea con [Trivy](https://trivy.dev) antes de publicarse. No se
publica si tiene vulnerabilidades HIGH o CRITICAL con fix disponible. Los cambios de
cada versión están en el [CHANGELOG](CHANGELOG.md).

## Uso

Docker Hub: [https://hub.docker.com/r/brsalcedom/node-helloworld](https://hub.docker.com/r/brsalcedom/node-helloworld)

**Inicio rápido**

```bash
docker run -d --name node-helloworld -p 8080:3000 brsalcedom/node-helloworld:2
curl http://localhost:8080
```

**Probes en Kubernetes**

```yaml
containers:
  - name: app
    image: brsalcedom/node-helloworld:2.0.0
    ports:
      - containerPort: 3000
    securityContext:
      runAsNonRoot: true
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
    startupProbe:
      httpGet: { path: /health/startup, port: 3000 }
    livenessProbe:
      httpGet: { path: /health/liveness, port: 3000 }
    readinessProbe:
      httpGet: { path: /health/readiness, port: 3000 }
```

**Construir desde el código fuente**

Desde la raíz del repositorio:

```bash
docker build -t brsalcedom/node-helloworld:dev -f images/node-helloworld/Dockerfile .
```

## Historial

Desde la 2.0.0, los cambios de cada versión se registran en el [CHANGELOG](CHANGELOG.md).

* **2.0**: Node 26 LTS, Express 5, imagen multi-stage (~49 MB comprimida), usuario no-root, puerto 3000 (antes 80), health checks y multi-arch (amd64/arm64)
* **1.0**: versión inicial
