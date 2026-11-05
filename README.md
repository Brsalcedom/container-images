# Container Images

A monorepo with my container images. Each image is versioned independently with
semantic versioning and is published to Docker Hub (`docker.io/brsalcedom/<image>`) and
GitHub Container Registry (`ghcr.io/brsalcedom/<image>`), with the same digest in both,
only if it passes the security gate.

| Image | Description | Platforms | Links |
|---|---|---|---|
| [homelab-ci](images/homelab-ci/) | CI for IaC: OpenTofu, kubectl, Task, git, ssh, envsubst (non-root) | amd64, arm64 | [Docker Hub](https://hub.docker.com/r/brsalcedom/homelab-ci) · [GHCR](https://github.com/Brsalcedom/container-images/pkgs/container/homelab-ci) · [CHANGELOG](images/homelab-ci/CHANGELOG.md) |
| [kubetools](images/kubetools/) | Kubernetes, AWS and GCP toolbox (kubectl, helm, eksctl, aws, gcloud) | amd64, arm64 | [Docker Hub](https://hub.docker.com/r/brsalcedom/kubetools) · [GHCR](https://github.com/Brsalcedom/container-images/pkgs/container/kubetools) · [CHANGELOG](images/kubetools/CHANGELOG.md) |
| [linode-cli](images/linode-cli/) | linode-cli with boto3 (Object Storage) | amd64, arm64 | [Docker Hub](https://hub.docker.com/r/brsalcedom/linode-cli) · [GHCR](https://github.com/Brsalcedom/container-images/pkgs/container/linode-cli) · [CHANGELOG](images/linode-cli/CHANGELOG.md) |
| [node-helloworld](images/node-helloworld/) | Node.js/Express Hello World with Kubernetes health checks | amd64, arm64 | [Docker Hub](https://hub.docker.com/r/brsalcedom/node-helloworld) · [GHCR](https://github.com/Brsalcedom/container-images/pkgs/container/node-helloworld) · [CHANGELOG](images/node-helloworld/CHANGELOG.md) |
| [pentesting](images/pentesting/) | Kali Rolling with pentesting tools for labs (HTB, THM) | amd64 | [Docker Hub](https://hub.docker.com/r/brsalcedom/pentesting) · [GHCR](https://github.com/Brsalcedom/container-images/pkgs/container/pentesting) · [CHANGELOG](images/pentesting/CHANGELOG.md) |

The current version of each image is in [`.release-please-manifest.json`](.release-please-manifest.json).

## Layout

```text
images/<image>/
  Dockerfile
  Dockerfile.dockerignore   # the context is the repo root: only let through what is needed
  README.md                 # published as the Docker Hub description
  CHANGELOG.md              # maintained by release-please
images.yml                  # target registries + build settings (platforms, smoke test...)
.release-please-manifest.json  # current version of each image
release-please-config.json  # one release-please package per image
scripts/go-bump.sh          # bumps vulnerable Go dependencies when building tools
.github/scripts/            # plan.sh (which images to process), metadata.sh, scan.sh (gate), publish.sh
.trivyignore.yaml           # CVE exceptions, with justification and expiry
.trivyignore.rego           # policy for findings never exploitable in a container
.hadolint.yaml              # Dockerfile lint rules
AGENTS.md                   # guidelines for contributors and AI agents
```

Images are always built from the repo root:

```sh
docker build -t brsalcedom/<image>:dev -f images/<image>/Dockerfile .
```

## Versioning

Each image is versioned separately with [release-please](https://github.com/googleapis/release-please),
based on the commits (Conventional Commits, enforced on the PR title) that touch
`images/<image>/`:

| Commit | Release |
|---|---|
| `fix(kubetools): ...`, `deps(...)`, `perf(...)` | patch (`2.0.0` → `2.0.1`) |
| `feat(kubetools): ...` | minor (`2.0.1` → `2.1.0`) |
| `feat(kubetools)!: ...` or `BREAKING CHANGE:` | major (`2.1.0` → `3.0.0`) |
| `chore`, `ci`, `docs`, `refactor`, `test`, `build`, `style` | no release |

Renovate uses `fix(deps)` for anything inside `images/`, so dependency updates produce
a patch release.

Each version is published with the `X.Y.Z`, `X.Y`, `X` and `latest` tags. Floating
tags only move if the version is the highest in its line, and a published version is
never overwritten.

## Pipeline (`.github/workflows/images.yml`)

```text
plan ──► build (matrix, one per changed image) ──► gate
         hadolint → multi-arch build to a local registry → smoke test
         → Trivy per platform → [main + new version] copy to every registry
```

1. **PR**: only the changed images are built, tested and scanned. If any of them has
   fixable HIGH/CRITICAL CVEs, the `gate` check fails and the PR cannot be merged.
2. **Merge to main**: validation runs again; release-please opens one release PR per
   image with releasable changes.
3. **Merging the release PR**: the new version is built, scanned and, if it passes,
   published to every registry in `images.yml`. What gets published is exactly the
   multi-arch index that was scanned (same digest), copied with `skopeo` from the job's
   local registry.
4. **Every Monday**: published versions are re-scanned (new CVEs show up after
   publishing), the full report is uploaded to the *Security* tab, and every registry
   is checked to serve the same digest. If the scan fails, a `fix(<image>): rebuild`
   commit publishes a patch with the fixes.

It can also be triggered manually (*Actions → images → Run workflow*) for one image or
all of them. On `main` it publishes any versions missing from a registry.

### Registries

Target registries are listed under `registries:` in [`images.yml`](images.yml) (an
image can override the list). Adding a registry backfills it with the current version
of every image on the next run. Registries other than Docker Hub and GHCR need a login
step in the workflow.

### Security gate

* [Trivy](https://trivy.dev), with the official image version pinned in the workflow.
* Blocks fixable `CRITICAL` and `HIGH` vulnerabilities (`--ignore-unfixed`) on **every**
  platform of the image.
* Exceptions only in [`.trivyignore.yaml`](.trivyignore.yaml), each with a `statement`
  and an `expired_at`. Once it expires, the gate blocks again.
* [`.trivyignore.rego`](.trivyignore.rego) drops whole classes of findings that are never
  exploitable in a container (kernel headers in `linux-libc-dev`).

## Repository settings

* **Secrets**:
  * `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`: Docker Hub token with *Read, Write,
    Delete* permissions. *Delete* is needed to update the description.
  * `RELEASE_PLEASE_TOKEN`: fine-grained PAT for this repository with *Contents* and
    *Pull requests* read/write. Without it, release PRs do not trigger the checks.
* **GHCR**: the workflow pushes with `GITHUB_TOKEN` (`packages: write`), so no secret is
  needed. New packages are created **private**: make each one public once under
  *Package settings → Change visibility*. A package that already exists and was not
  created by this repository must grant it *Write* access under *Manage Actions access*.
* **`main` protection**: see [`.github/BRANCH_PROTECTION.md`](.github/BRANCH_PROTECTION.md).

## Adding an image

1. Create `images/<image>/` with `Dockerfile`, `Dockerfile.dockerignore` (copy it from
   another image), `README.md` and `CHANGELOG.md`.
2. Add it to `images.yml`, to `release-please-config.json` (`packages`) and to
   `.release-please-manifest.json` with its initial version.
3. Open the PR. The initial version is published on merge.

See [AGENTS.md](AGENTS.md) for conventions on commits, PRs and Dockerfiles.

## Image metadata

Every image carries the same metadata in every registry:

* **OCI labels** from the Dockerfile (`title`, `description`, `source`, `authors`,
  `licenses`) plus `version`, `revision`, `created`, `url` and `documentation` added
  by the pipeline. The main ones are also set as **index annotations**, which is where
  GHCR reads the description and license of multi-arch images.
* **Attestations**: SLSA provenance (`mode=max`) and an SPDX SBOM (except
  `pentesting`, whose SBOM exceeds BuildKit's size limit).
* **Docker Hub**: the image README as the full description and the `description`
  label as the short description.

## License

[MIT](LICENSE), for the contents of this repository (Dockerfiles, scripts and
configuration). The software installed in each image keeps its own license.
