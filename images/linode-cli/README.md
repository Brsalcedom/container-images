## Info

Imagen liviana para usar **linode-cli** sin instalar Python en tu equipo.

* linode-cli 5.70
* boto3 (necesario para `linode-cli obj`, Object Storage)
* Alpine 3.24 + Python 3 en un virtualenv, sin pip en la imagen final
* Corre como usuario no-root (`1000:1000`)
* Multi-arch (amd64/arm64)

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

Docker Hub: [https://hub.docker.com/r/brsalcedom/linode-cli](https://hub.docker.com/r/brsalcedom/linode-cli)

Desde la versión 2.0 el `ENTRYPOINT` es `linode-cli`, así que los argumentos van directo:

```bash
export LINODE_CLI_TOKEN=<tu-token>
docker run --rm -e LINODE_CLI_TOKEN brsalcedom/linode-cli:2 linodes list
```

**Alias para usarla como si estuviera instalada**

```bash
alias linode-cli='docker run --rm -it -e LINODE_CLI_TOKEN brsalcedom/linode-cli:2'
linode-cli regions list
```

**Usar tu configuración existente** (`~/.config/linode-cli`)

```bash
docker run --rm -it -v ~/.config/linode-cli:/home/linode/.config/linode-cli:ro brsalcedom/linode-cli:2 linodes list
```

**Abrir una shell**

```bash
docker run --rm -it --entrypoint sh brsalcedom/linode-cli:2
```

**Construir desde el código fuente**

Desde la raíz del repositorio:

```bash
docker build -t brsalcedom/linode-cli:dev -f images/linode-cli/Dockerfile .
```

## Historial

Desde la 2.0.0, los cambios de cada versión se registran en el [CHANGELOG](CHANGELOG.md).

* **2.0**: linode-cli 5.70, Python 3.14 sobre Alpine 3.24, `boto` (obsoleto) reemplazado por `boto3`, `ENTRYPOINT linode-cli`, usuario no-root y multi-arch (amd64/arm64)
* **1.0**: linode-cli 5.21 sobre Python 3.10
