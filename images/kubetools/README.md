## Info

Toolbox para trabajar con Kubernetes, AWS y GCP desde la CLI.

| Herramienta | Versión | Origen |
|---|---|---|
| kubectl | 1.37 | compilado desde el código fuente con Go 1.27 |
| helm | 4.3 | compilado desde el código fuente con Go 1.27 |
| eksctl | 0.231 | compilado desde el código fuente con Go 1.27 |
| gcloud + gke-gcloud-auth-plugin | 592 | SDK oficial, sin Python embebido ni `gsutil` |
| aws-cli | 2.x | paquete de Alpine |
| jq, yq, git, curl, openssl, nmap, telnet | — | paquetes de Alpine |

kubectl, helm y eksctl se compilan desde el código fuente porque los binarios oficiales
suelen salir con versiones de Go o dependencias que ya tienen CVEs corregidos. El
Dockerfile permite subir dependencias puntuales (`*_GO_BUMPS`) sin esperar a upstream.

* Base `alpine:3.24`, multi-arch (amd64/arm64)
* Autocompletado de bash para kubectl, helm y eksctl
* Corre como `root` (es una toolbox interactiva), con `/root` como directorio de trabajo

## Tags

| Tag | Contenido |
|---|---|
| `2.0.0` | versión exacta e inmutable (recomendado para scripts y CI) |
| `2.0` | último patch de la 2.0 |
| `2` | último minor/patch de la 2 |
| `latest` | última versión publicada |

Cada versión se escanea con [Trivy](https://trivy.dev) antes de publicarse. No se
publica si tiene vulnerabilidades HIGH o CRITICAL con fix disponible. Los cambios de
cada versión están en el [CHANGELOG](CHANGELOG.md).

## Uso

Docker Hub: [https://hub.docker.com/r/brsalcedom/kubetools](https://hub.docker.com/r/brsalcedom/kubetools)

**Inicio rápido**

```bash
docker run --rm -it brsalcedom/kubetools:2
```

**Usar tus credenciales locales**

```bash
docker run --rm -it \
  -v ~/.kube:/root/.kube \
  -v ~/.aws:/root/.aws \
  -v ~/.config/gcloud:/root/.config/gcloud \
  brsalcedom/kubetools:2
```

**Pod de debugging en Kubernetes**

```bash
kubectl run --rm -it kubetools -n testing --image=brsalcedom/kubetools:2 -- bash
```

**Construir desde el código fuente**

Desde la raíz del repositorio (el contexto incluye `scripts/go-bump.sh`):

```bash
docker build -t brsalcedom/kubetools:dev -f images/kubetools/Dockerfile .
```

## Historial

Desde la 2.0.0, los cambios de cada versión se registran en el [CHANGELOG](CHANGELOG.md).

* **2.0**: base `alpine:3.24` (antes `python:alpine`, que dejaba dos Pythons en la imagen); kubectl/helm/eksctl compilados desde fuente; versiones fijadas; helm 4; `gke-gcloud-auth-plugin`; se elimina `gsutil` (usar `gcloud storage`); multi-arch (amd64/arm64). De 1.4 GB y 212 CVEs HIGH/CRITICAL a ~810 MB y 0.
* **1.5**: downgrade de Alpine por compatibilidad con aws-cli, limpieza
* **1.4**: gcloud-cli
* **1.3**: Python 3.12.5, nmap, telnet
* **1.1**: mysql-cli
* **1.0**: python, curl, kubectl, eksctl, awscli
