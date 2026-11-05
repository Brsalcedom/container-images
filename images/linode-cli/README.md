## Info

Lightweight image to use **linode-cli** without installing Python on your machine.

* linode-cli 5.70
* boto3 (required by `linode-cli obj`, Object Storage)
* Alpine 3.24 + Python 3 in a virtualenv, no pip in the final image
* Runs as a non-root user (`1000:1000`)
* Multi-arch (amd64/arm64)

## Tags

| Tag | Content |
|---|---|
| `2.0.0` | exact, immutable version (recommended for scripts and CI) |
| `2.0` | latest 2.0 patch |
| `2` | latest 2.x minor/patch |
| `latest` | latest published version |

Every version is scanned with [Trivy](https://trivy.dev) before it is published, and
is not published if it has fixable HIGH or CRITICAL vulnerabilities. Changes for each
version are in the [CHANGELOG](CHANGELOG.md).

## Usage

Docker Hub: [https://hub.docker.com/r/brsalcedom/linode-cli](https://hub.docker.com/r/brsalcedom/linode-cli)

Since 2.0 the `ENTRYPOINT` is `linode-cli`, so arguments are passed directly:

```bash
export LINODE_CLI_TOKEN=<your-token>
docker run --rm -e LINODE_CLI_TOKEN brsalcedom/linode-cli:2 linodes list
```

**Alias to use it as if it were installed**

```bash
alias linode-cli='docker run --rm -it -e LINODE_CLI_TOKEN brsalcedom/linode-cli:2'
linode-cli regions list
```

**Use your existing configuration** (`~/.config/linode-cli`)

```bash
docker run --rm -it -v ~/.config/linode-cli:/home/linode/.config/linode-cli:ro brsalcedom/linode-cli:2 linodes list
```

**Open a shell**

```bash
docker run --rm -it --entrypoint sh brsalcedom/linode-cli:2
```

**Build from source**

From the repository root:

```bash
docker build -t brsalcedom/linode-cli:dev -f images/linode-cli/Dockerfile .
```

## History

Since 2.0.0, the changes in each version are recorded in the [CHANGELOG](CHANGELOG.md).

* **2.0**: linode-cli 5.70, Python 3.14 on Alpine 3.24, deprecated `boto` replaced by `boto3`, `ENTRYPOINT linode-cli`, non-root user and multi-arch (amd64/arm64)
* **1.0**: linode-cli 5.21 on Python 3.10
