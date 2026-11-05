## Info

Node.js + Express Hello World for testing (e.g. to validate Kubernetes deployments).

* Node.js 26 LTS on Alpine 3.24, no npm/yarn in the final image and the node binary stripped of debug symbols
* Express 5
* Runs as a non-root user (`1000:1000`) on port `3000` (configurable with `PORT`)
* Health endpoints for Kubernetes probes: `/health/liveness`, `/health/readiness`, `/health/startup`
* Docker `HEALTHCHECK` included and clean shutdown on `SIGTERM`
* Multi-arch (amd64/arm64)

## Tags

| Tag | Content |
|---|---|
| `2.0.0` | exact, immutable version (recommended for Kubernetes manifests) |
| `2.0` | latest 2.0 patch |
| `2` | latest 2.x minor/patch |
| `latest` | latest published version |

Every version is scanned with [Trivy](https://trivy.dev) before it is published, and
is not published if it has fixable HIGH or CRITICAL vulnerabilities. Changes for each
version are in the [CHANGELOG](CHANGELOG.md).

## Usage

Docker Hub: [https://hub.docker.com/r/brsalcedom/node-helloworld](https://hub.docker.com/r/brsalcedom/node-helloworld)

**Quick start**

```bash
docker run -d --name node-helloworld -p 8080:3000 brsalcedom/node-helloworld:2
curl http://localhost:8080
```

**Kubernetes probes**

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

**Build from source**

From the repository root:

```bash
docker build -t brsalcedom/node-helloworld:dev -f images/node-helloworld/Dockerfile .
```

## History

Since 2.0.0, the changes in each version are recorded in the [CHANGELOG](CHANGELOG.md).

* **2.0**: Node 26 LTS, Express 5, multi-stage image (~49 MB compressed), non-root user, port 3000 (previously 80), health checks and multi-arch (amd64/arm64)
* **1.0**: initial version
