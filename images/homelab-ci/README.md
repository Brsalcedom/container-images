## Info

CI image for infrastructure as code in the homelab.

| Tool | Version | Source |
|---|---|---|
| OpenTofu (`tofu`) | 1.13 | built from source with Go 1.27 |
| kubectl | 1.37 | built from source with Go 1.27 |
| Task (`task`) | 3.54 | built from source with Go 1.27 |
| git, curl, ssh, envsubst | — | Debian trixie packages |

* Based on `debian:trixie-slim`, multi-arch (amd64/arm64)
* Runs as the non-root user `ci` (`1000:1000`), with `/workspace` as the working directory
* `git` accepts mounted repositories owned by another user (`safe.directory '*'`)

## Tags

| Tag | Content |
|---|---|
| `3.0.0` | exact, immutable version (recommended for pipelines) |
| `3.0` | latest 3.0 patch |
| `3` | latest 3.x minor/patch |
| `latest` | latest published version |

Every version is scanned with [Trivy](https://trivy.dev) before it is published, and
is not published if it has fixable HIGH or CRITICAL vulnerabilities. Changes for each
version are in the [CHANGELOG](CHANGELOG.md).

## Usage

Available from two registries, with the same digest in both:

| Registry | Image |
|---|---|
| [Docker Hub](https://hub.docker.com/r/brsalcedom/homelab-ci) | `docker.io/brsalcedom/homelab-ci` |
| [GitHub Container Registry](https://github.com/Brsalcedom/container-images/pkgs/container/homelab-ci) | `ghcr.io/brsalcedom/homelab-ci` |

**Shell with the current directory mounted**

```bash
docker run --rm -it -v "$(pwd):/workspace" brsalcedom/homelab-ci:3 bash
```

If you need to write to the mounted directory and your UID is not 1000, add `--user "$(id -u):$(id -g)"`.

**As a GitHub Actions job container**

The runner workspace is owned by UID 1001, so the container has to run as that user:

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

**Build from source**

From the repository root (the context includes `scripts/go-bump.sh`):

```bash
docker build -t brsalcedom/homelab-ci:dev -f images/homelab-ci/Dockerfile .
```

## Migrating from 2.x

3.0 runs as the user `ci` instead of `root`:

* `apt-get install` inside the job no longer works. If you need extra packages, build
  a derived image with `USER root` → install → `USER 1000:1000`.
* Files the container creates on mounted volumes are owned by UID 1000.
* If you relied on `/root` (e.g. `~/.ssh` or `~/.kube`), the home is now `/home/ci`.

## History

See the [CHANGELOG](CHANGELOG.md).

* **3.0**: non-root user `ci` (previously root); OpenTofu, kubectl and Task built from source with current Go.
* **2.x**: Debian trixie with OpenTofu, kubectl, Task and envsubst.
