## Info

Imagen de CI para infraestructura como código en el homelab.

| Herramienta | Versión | Origen |
|---|---|---|
| OpenTofu (`tofu`) | 1.13 | compilado desde el código fuente con Go 1.27 |
| kubectl | 1.37 | compilado desde el código fuente con Go 1.27 |
| Task (`task`) | 3.54 | compilado desde el código fuente con Go 1.27 |
| git, curl, ssh, envsubst | — | paquetes de Debian trixie |

* Base `debian:trixie-slim`, multi-arch (amd64/arm64)
* Corre como usuario no-root `ci` (`1000:1000`), con `/workspace` como directorio de trabajo
* `git` acepta repositorios montados de otro dueño (`safe.directory '*'`)

## Tags

| Tag | Contenido |
|---|---|
| `3.0.0` | versión exacta e inmutable (recomendado para pipelines) |
| `3.0` | último patch de la 3.0 |
| `3` | último minor/patch de la 3 |
| `latest` | última versión publicada |

Cada versión se escanea con [Trivy](https://trivy.dev) antes de publicarse. No se
publica si tiene vulnerabilidades HIGH o CRITICAL con fix disponible. Los cambios de
cada versión están en el [CHANGELOG](CHANGELOG.md).

## Uso

Docker Hub: [https://hub.docker.com/r/brsalcedom/homelab-ci](https://hub.docker.com/r/brsalcedom/homelab-ci)

**Shell con el directorio actual montado**

```bash
docker run --rm -it -v "$(pwd):/workspace" brsalcedom/homelab-ci:3 bash
```

Si necesitas escribir en el directorio montado y tu UID no es 1000, agrega `--user "$(id -u):$(id -g)"`.

**Como imagen de job en GitHub Actions**

El workspace del runner pertenece al UID 1001, así que hay que correr el contenedor con ese usuario:

```yaml
jobs:
  plan:
    runs-on: ubuntu-latest
    container:
      image: brsalcedom/homelab-ci:3
      options: --user 1001
    steps:
      - uses: actions/checkout@v6
      - run: tofu init && tofu plan
```

**Construir desde el código fuente**

Desde la raíz del repositorio (el contexto incluye `scripts/go-bump.sh`):

```bash
docker build -t brsalcedom/homelab-ci:dev -f images/homelab-ci/Dockerfile .
```

## Migrar desde 2.x

La 3.0 corre como usuario `ci` en vez de `root`:

* `apt-get install` dentro del job ya no funciona. Si necesitas paquetes extra, crea
  una imagen derivada con `USER root` → instalar → `USER 1000:1000`.
* Los archivos que el contenedor crea en volúmenes montados quedan con UID 1000.
* Si dependías de `/root` (por ejemplo `~/.ssh` o `~/.kube`), el home ahora es `/home/ci`.

## Historial

Ver el [CHANGELOG](CHANGELOG.md).

* **3.0**: usuario no-root `ci` (antes root); OpenTofu, kubectl y Task compilados desde el código fuente con Go actual.
* **2.x**: Debian trixie con OpenTofu, kubectl, Task y envsubst.
