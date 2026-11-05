# Container Images

Monorepo con mis imágenes de contenedor. Cada imagen tiene su propio versionamiento
semántico y se publica en Docker Hub (`docker.io/brsalcedom/<imagen>`) solo si pasa el
security gate.

| Imagen | Descripción | Plataformas | Links |
|---|---|---|---|
| [homelab-ci](images/homelab-ci/) | CI para IaC: OpenTofu, kubectl, Task, git, ssh, envsubst (no-root) | amd64, arm64 | [Docker Hub](https://hub.docker.com/r/brsalcedom/homelab-ci) · [CHANGELOG](images/homelab-ci/CHANGELOG.md) |
| [kubetools](images/kubetools/) | Toolbox de Kubernetes, AWS y GCP (kubectl, helm, eksctl, aws, gcloud) | amd64, arm64 | [Docker Hub](https://hub.docker.com/r/brsalcedom/kubetools) · [CHANGELOG](images/kubetools/CHANGELOG.md) |
| [linode-cli](images/linode-cli/) | linode-cli con boto3 (Object Storage) | amd64, arm64 | [Docker Hub](https://hub.docker.com/r/brsalcedom/linode-cli) · [CHANGELOG](images/linode-cli/CHANGELOG.md) |
| [node-helloworld](images/node-helloworld/) | Hello World en Node.js/Express con health checks para Kubernetes | amd64, arm64 | [Docker Hub](https://hub.docker.com/r/brsalcedom/node-helloworld) · [CHANGELOG](images/node-helloworld/CHANGELOG.md) |
| [pentesting](images/pentesting/) | Kali Rolling con herramientas de pentesting para labs (HTB, THM) | amd64 | [Docker Hub](https://hub.docker.com/r/brsalcedom/pentesting) · [CHANGELOG](images/pentesting/CHANGELOG.md) |

La versión actual de cada imagen está en [`.release-please-manifest.json`](.release-please-manifest.json).

## Estructura

```text
images/<imagen>/
  Dockerfile
  Dockerfile.dockerignore   # el contexto es la raíz del repo: solo pasa lo necesario
  README.md                 # se publica como descripción en Docker Hub
  CHANGELOG.md              # lo mantiene release-please
images.yml                  # configuración de build (plataformas, smoke test, caché...)
.release-please-manifest.json  # versión actual de cada imagen
release-please-config.json  # un package de release-please por imagen
scripts/go-bump.sh          # sube dependencias Go con CVEs al compilar herramientas
.github/scripts/            # plan.sh (qué imágenes procesar), scan.sh (gate), publish.sh
.trivyignore.yaml           # excepciones de CVEs, con justificación y vencimiento
.hadolint.yaml              # reglas de lint de Dockerfiles
```

Las imágenes se construyen siempre desde la raíz del repo:

```sh
docker build -t brsalcedom/<imagen>:dev -f images/<imagen>/Dockerfile .
```

## Versionamiento

Cada imagen se versiona por separado con [release-please](https://github.com/googleapis/release-please)
a partir de los commits (Conventional Commits, validado en el título del PR) que tocan
`images/<imagen>/`:

| Commit | Release |
|---|---|
| `fix(kubetools): ...`, `deps(...)`, `perf(...)` | patch (`2.0.0` → `2.0.1`) |
| `feat(kubetools): ...` | minor (`2.0.1` → `2.1.0`) |
| `feat(kubetools)!: ...` o `BREAKING CHANGE:` | major (`2.1.0` → `3.0.0`) |
| `chore`, `ci`, `docs`, `refactor`, `test`, `build`, `style` | sin release |

Renovate usa `fix(deps)` para lo que está dentro de `images/`, así que las
actualizaciones de dependencias generan un release patch.

Cada versión se publica con los tags `X.Y.Z`, `X.Y`, `X` y `latest`. Los tags flotantes
solo se mueven si la versión es la más alta de su rama, y una versión publicada nunca
se sobrescribe.

## Pipeline (`.github/workflows/images.yml`)

```text
plan ──► build (matrix, una por imagen modificada) ──► gate
         hadolint → build multi-arch a registry local → smoke test
         → Trivy por plataforma → [main + versión nueva] copia a Docker Hub
```

1. **PR**: se construyen, prueban y escanean solo las imágenes modificadas. Si alguna
   tiene CVEs HIGH/CRITICAL con fix disponible, falla el check `gate` y no se puede
   hacer merge.
2. **Merge a main**: se repite la validación; release-please abre un PR de release por
   cada imagen con cambios releasables.
3. **Merge del PR de release**: la versión nueva se construye, se escanea y, si pasa,
   se publica. Lo que se publica es exactamente el índice multi-arch que se escaneó
   (mismo digest), copiado con `skopeo` desde el registry local del job.
4. **Cada lunes**: se re-escanean las versiones publicadas (salen CVEs nuevas después
   de publicar) y el reporte completo se sube a la pestaña *Security*. Si falla,
   corresponde un `fix(<imagen>): rebuild` para publicar un patch con los parches.

También se puede lanzar a mano (*Actions → images → Run workflow*), para una imagen o
para todas. En `main` publica las versiones que aún no estén en Docker Hub.

### Security gate

* [Trivy](https://trivy.dev), con la versión de la imagen oficial fijada en el workflow.
* Bloquea `CRITICAL` y `HIGH` con fix disponible (`--ignore-unfixed`), en **todas** las
  plataformas de la imagen.
* Excepciones solo en [`.trivyignore.yaml`](.trivyignore.yaml), cada una con `statement`
  y `expired_at`. Al vencer, el gate vuelve a bloquear.

## Configuración del repositorio

* **Secrets**:
  * `DOCKERHUB_USERNAME` y `DOCKERHUB_TOKEN`: token de Docker Hub con permisos *Read,
    Write, Delete*. *Delete* es necesario para actualizar la descripción.
  * `RELEASE_PLEASE_TOKEN`: fine-grained PAT de este repo con *Contents* y *Pull
    requests* en read/write. Sin él, los PRs de release no disparan los checks.
* **Protección de `main`**: ver [`.github/BRANCH_PROTECTION.md`](.github/BRANCH_PROTECTION.md).

## Agregar una imagen

1. Crear `images/<imagen>/` con `Dockerfile`, `Dockerfile.dockerignore` (copiar el de
   otra imagen) y `README.md`.
2. Agregarla en `images.yml`, en `release-please-config.json` (`packages`) y en
   `.release-please-manifest.json` con su versión inicial.
3. Abrir el PR. Al hacer merge se publica la versión inicial.
