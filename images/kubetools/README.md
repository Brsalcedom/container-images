## Info

CLI toolbox for working with Kubernetes, AWS and GCP.

| Tool | Version | Source |
|---|---|---|
| kubectl | 1.37 | built from source with Go 1.27 |
| helm | 4.3 | built from source with Go 1.27 |
| eksctl | 0.231 | built from source with Go 1.27 |
| gcloud + gke-gcloud-auth-plugin | 592 | official SDK, without the bundled Python or `gsutil` |
| aws-cli | 2.x | Alpine package |
| jq, yq, git, curl, openssl, nmap, telnet | — | Alpine packages |

kubectl, helm and eksctl are built from source because the official binaries often
ship with Go versions or dependencies that already have fixed CVEs. The Dockerfile
can bump specific dependencies (`*_GO_BUMPS`) without waiting for upstream.

* Based on `alpine:3.24`, multi-arch (amd64/arm64)
* Bash completion for kubectl, helm and eksctl
* Runs as `root` (it is an interactive toolbox), with `/root` as the working directory

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

Docker Hub: [https://hub.docker.com/r/brsalcedom/kubetools](https://hub.docker.com/r/brsalcedom/kubetools)

**Quick start**

```bash
docker run --rm -it brsalcedom/kubetools:2
```

**Use your local credentials**

```bash
docker run --rm -it \
  -v ~/.kube:/root/.kube \
  -v ~/.aws:/root/.aws \
  -v ~/.config/gcloud:/root/.config/gcloud \
  brsalcedom/kubetools:2
```

**Debugging pod in Kubernetes**

```bash
kubectl run --rm -it kubetools -n testing --image=brsalcedom/kubetools:2 -- bash
```

**Build from source**

From the repository root (the context includes `scripts/go-bump.sh`):

```bash
docker build -t brsalcedom/kubetools:dev -f images/kubetools/Dockerfile .
```

## History

Since 2.0.0, the changes in each version are recorded in the [CHANGELOG](CHANGELOG.md).

* **2.0**: `alpine:3.24` base (previously `python:alpine`, which left two Pythons in the image); kubectl/helm/eksctl built from source; pinned versions; helm 4; `gke-gcloud-auth-plugin`; `gsutil` removed (use `gcloud storage`); multi-arch (amd64/arm64). From 1.4 GB and 212 HIGH/CRITICAL CVEs down to ~810 MB and 0.
* **1.5**: Alpine downgrade for aws-cli compatibility, cleanup
* **1.4**: gcloud-cli
* **1.3**: Python 3.12.5, nmap, telnet
* **1.1**: mysql-cli
* **1.0**: python, curl, kubectl, eksctl, awscli
