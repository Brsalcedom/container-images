# AGENTS.md

Guidelines for people and AI agents working in this repository. If something here
conflicts with what the user asks in a conversation, the user wins. If it conflicts
with the code, flag it: one of the two probably needs updating.

## Repository goal

A monorepo with all of Bryan Salcedo's (`brsalcedom`) custom container images,
published to Docker Hub (`docker.io/brsalcedom/<image>`) and GitHub Container Registry
(`ghcr.io/brsalcedom/<image>`), with the same digest in every registry.

1. **One image per folder** under `images/<image>/`, each with its own independent
   semantic version.
2. **Nothing reaches a registry without passing the security gate.** An image with
   HIGH or CRITICAL CVEs that have a fix available is not published.
3. **Minimal, reproducible images**: pinned versions, multi-stage builds, no build
   tooling in the final image, non-root unless there is a reason not to.

## Layout

| Path | What it is |
|---|---|
| `images/<image>/Dockerfile` | image build; the build context is **the repository root** |
| `images/<image>/Dockerfile.dockerignore` | what enters the context (everything excluded except the image folder and any shared files it uses) |
| `images/<image>/README.md` | documentation; published as the Docker Hub description |
| `images/<image>/CHANGELOG.md` | maintained by release-please; do not edit by hand except when adding the image |
| `images.yml` | target `registries` and per-image build settings: `registries`, `platforms`, `test`, `free-disk-space`, `cache`, `sbom` |
| `.release-please-manifest.json` | current version of each image (single source of truth) |
| `release-please-config.json` | one release-please package per image |
| `scripts/go-bump.sh` | bumps vulnerable Go dependencies when building tools from source |
| `.github/scripts/plan.sh` | decides which images to process (matrix) |
| `.github/scripts/metadata.sh` | reads and validates the OCI labels; emits index annotations and the Docker Hub short description |
| `.github/scripts/scan.sh` | security gate (Trivy) |
| `.github/scripts/publish.sh` | copies the scanned digest to every registry, moves tags, checks registries are in sync |
| `.github/workflows/images.yml` | pipeline: lint, build, smoke test, gate, publish, weekly re-scan |
| `.trivyignore.yaml` | CVE exceptions |
| `.hadolint.yaml` | Dockerfile lint rules |

## Language and tone

* **Everything in the repository is written in English**: code, comments, docs,
  commit messages, PR titles and descriptions, workflow and script output.
* **Commit and PR titles** follow Conventional Commits, imperative mood, lowercase,
  no trailing period.
* **Tone**: direct, technical and specific. Explain the *why* behind non-obvious
  decisions, not the *what* that the code already shows. No filler, no marketing, no
  emojis outside the PR template.
* Prefer verifiable facts over adjectives, e.g. "from 1.4 GB and 212 CVEs to 810 MB
  and 0" instead of "much smaller and more secure".
* If something was not tested, say so explicitly. Never claim something works without
  having verified it.

## Commits and versioning

Conventional Commits, with **the image name as the scope**. The type determines the
release that release-please cuts for every image whose files changed:

| Type | Release | Use for |
|---|---|---|
| `fix(<image>)` | patch | bug, fixed CVE, rebuild to pick up patches |
| `deps(<image>)` | patch | dependency updates (Renovate uses `fix(deps)`) |
| `perf(<image>)` | patch | smaller image, faster build |
| `feat(<image>)` | minor | new tool, new capability |
| `feat(<image>)!` or a `BREAKING CHANGE:` footer | major | changes the user, ENTRYPOINT, paths or ports, or removes tools |
| `ci`, `chore`, `docs`, `refactor`, `test`, `build`, `style` | none | pipeline, tooling, documentation |

Rules:

* **Always squash merge.** The PR title becomes the commit release-please reads, so
  it must be right.
* **One PR, one image**, except for cross-cutting changes (pipeline, shared scripts).
* **Do not edit versions by hand** in `.release-please-manifest.json`. The only
  exception is adding a new image.
* A `BREAKING CHANGE` in the commit body also counts for release-please. Only use it
  when a major release is really intended.
* Changes that only touch `.github/`, `scripts/` or the root do not trigger releases.
  If an image must be republished because of such a change, add a
  `fix(<image>): ...` commit.

## Pull requests

**Always use the template [`.github/pull_request_template.md`](.github/pull_request_template.md)**,
fully, without removing sections.

### Title

`<type>(<image>): <description, imperative, lowercase, no trailing period>`

Examples: `fix(kubetools): bump golang.org/x/net to patch CVE-2026-1234`,
`feat(homelab-ci)!: run as non-root user ci`, `ci: add weekly scan of published images`.

### PR Type

Check **exactly one** box, the one matching the title's type:

| Title type | Box |
|---|---|
| `feat` | ✨ Feature |
| `fix` | 🐛 Fix |
| `docs` | 📚 Docs |
| `refactor` | ♻️ Refactor |
| `test` | 🧪 Test |
| `chore`, `ci`, `build` | 🔧 Chore |
| `deps`, `fix(deps)` | ⬆️ Dependency Update |
| `perf` | 🚀 Performance Improvement |
| `style` or cleanup with no functional change | 🧹 Code Cleanup |

### Summary

Start with 1-3 sentences on **what changes and why**. Then add only the sections that
apply, in this order:

* **Affected images** and **expected release**, e.g. `kubetools: 2.0.0 → 2.0.1 (patch)`,
  or "none".
* **Changes**: a short list grouped by image or area. Do not list every file.
* **Breaking changes / migration**: what image users have to change.
* **Security**: fixed CVEs, gate result, new `.trivyignore.yaml` exceptions with
  their justification and expiry.
* **Validation**: commands run and their results, and what was **not** validated
  (e.g. "arm64 not tested locally").
* **Follow-ups**: anything left out of the PR or requiring manual action (secrets,
  repository settings).

Example:

```markdown
## 📌 Summary

Bump helm to 4.3.2 to fix CVE-2026-1234 (HIGH) in `golang.org/x/net`.

**Affected images:** kubetools 2.0.0 → 2.0.1 (patch)

**Security:** the gate passes with no HIGH/CRITICAL CVEs on amd64 and arm64.

**Validation:**
- `docker build -f images/kubetools/Dockerfile .` + smoke test from `images.yml`
- local `scan.sh`: 0 fixable HIGH/CRITICAL vulnerabilities
```

## Image rules

* **Dockerfile**:
  * Starts with `# syntax=docker/dockerfile:1` and uses multi-stage builds.
  * `COPY` paths are relative to the repository root (`images/<image>/...`,
    `scripts/...`).
  * Base images and tool versions are pinned. Every `ARG *_VERSION` has a
    `# renovate: datasource=... depName=...` comment on the line above it.
  * Go tools are built from source with `--platform=$BUILDPLATFORM` (cross-compiled,
    no QEMU) and `go-bump.sh` for vulnerable dependencies. Empty the `*_GO_BUMPS`
    once upstream ships a release that includes them.
  * OCI labels `title`, `description` (at most 100 characters, it is also the Docker
    Hub short description), `source` (this repository), `authors` and `licenses`
    (`MIT`). They are required: `.github/scripts/metadata.sh` fails the build if any
    is missing. The pipeline adds `version`, `revision`, `created`, `url` and
    `documentation`, and copies the main ones as index annotations (GHCR reads those
    for multi-arch images).
  * Non-root user with a numeric UID (`USER 1000:1000`). If an image runs as root,
    document why in its README.
  * No secrets, keys or credentials in the image or in the repository.
* **`Dockerfile.dockerignore`**: exclude everything (`*`) and allow only what is
  needed.
* **`images.yml`**: every image has a `test` that checks its main tools start and,
  where relevant, the user or ports.
* **README**: if tools, versions, user, ports or usage change, update it in the same
  PR, along with the table in the root README.
* **New image**: full folder (`Dockerfile`, `Dockerfile.dockerignore`, `README.md`,
  `CHANGELOG.md`), an entry in `images.yml`, a package in `release-please-config.json`
  and an initial version in `.release-please-manifest.json`.

## Security gate

* Blocks **fixable HIGH and CRITICAL CVEs** on every platform.
  **Do not disable it, lower its severity or bypass it** to get an image published.
* Preferred order for fixing a CVE:
  1. update the base image or the package;
  2. build from source;
  3. `go-bump.sh`;
  4. remove the component if it is not needed;
  5. as a last resort, an exception.
* Exceptions go only in `.trivyignore.yaml`. Each one has a `statement` (why it is not
  exploitable or why there is no reasonable fix), `paths` as narrow as possible and an
  `expired_at` at most 90 days out. Adding an exception requires explicit approval
  from the repository owner.
* Trivy runs from the official image at a pinned version (`TRIVY_VERSION` in the
  workflow), not through `aquasecurity/trivy-action` or `setup-trivy`, because their
  tags were compromised in March 2026. GitHub Actions are pinned by SHA (Renovate
  `helpers:pinGitHubActionDigests`).

## Local validation

Before opening a PR, run whatever applies (Docker is enough, nothing else to install):

```sh
# Lint
docker run --rm -v "$PWD:/mnt" -w /mnt koalaman/shellcheck:stable -S warning .github/scripts/*.sh scripts/*.sh
docker run --rm -i -v "$PWD/.hadolint.yaml:/.config/hadolint.yaml" hadolint/hadolint < images/<image>/Dockerfile
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:latest

# Build + smoke test + gate
docker build -t localhost:5000/<image>:dev -f images/<image>/Dockerfile .
docker run --rm --entrypoint sh localhost:5000/<image>:dev -c "<test from images.yml>"
docker run -d --name registry -p 5000:5000 registry:3 && docker push localhost:5000/<image>:dev
TRIVY_IMAGE=aquasec/trivy:<TRIVY_VERSION> .github/scripts/scan.sh localhost:5000/<image>:dev linux/amd64
```

In Git Bash (Windows), prefix commands that use `-v` with `MSYS_NO_PATHCONV=1`.

## AI agents

**May do without asking:** read the repository, edit files on a working branch, run
linters, builds and local scans, and draft commits and PR descriptions.

**Requires explicit confirmation from the user:**

* `git commit`, `git push`, opening, editing or merging PRs, and creating tags or
  releases.
* Anything that publishes to Docker Hub or triggers workflows (`workflow_dispatch`).
* Adding or extending exceptions in `.trivyignore.yaml`, or changing gate severities
  or flags.
* Changing versions in `.release-please-manifest.json`, `bootstrap-sha` or the
  release-please configuration.
* Destructive operations: `push --force`, rewriting history, deleting branches, tags
  or published images.

**Always:**

* Work on a branch, never directly on `main`.
* Check tool and base image versions against their actual releases before pinning
  them. Never make up versions, digests or SHAs.
* Keep the code, `images.yml`, the READMEs and this file in sync.
* When done, report what changed, what was validated (with results) and what could
  not be validated.
* Never expose or copy secrets, tokens or keys, not even in logs or examples.
