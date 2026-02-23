# Container Images

This repository contains various container images for different purposes.

## Available Images

### `homelab-ci`

A minimal container image for CI/CD workflows, specifically designed for home lab infrastructure-as-code (IaC) tasks.

This image is based on Alpine Linux and comes pre-installed with the necessary tools for IaC workflows.

#### Included Software

*   **OpenTofu:** v1.10.3
*   `git`
*   `curl`
*   `openssl`
*   `ca-certificates`

#### How to Use

##### Building the Image

To build the Docker image, run the following command from the root of the repository:

```sh
docker build -t homelab-ci -f images/homelab-ci/Dockerfile .
```

##### Running the Container

You can run the container interactively and mount a local directory into the container's workspace. This is useful for running OpenTofu commands against your local IaC files.

```sh
docker run -it --rm -v "$(pwd):/workspace" homelab-ci sh
```

This command will start a shell session inside the container. The container runs as a non-root user `ci`, and the working directory is set to `/workspace`.

#### Image Details

*   **Base Image:** `alpine:3.22`
*   **User:** `ci` (non-root)
*   **Working Directory:** `/workspace`
*   **Source:** The Dockerfile can be found at `images/homelab-ci/Dockerfile`.

---

## 🔒 Security

All container images in this repository are automatically scanned for vulnerabilities using [Trivy](https://github.com/aquasecurity/trivy) before being published.

### Security Workflows

This repository uses two separate workflows for security:

1. **Security Report** (`security-report.yml`)
   - Runs on every PR that modifies images
   - Generates SARIF reports for GitHub Security tab
   - Creates SBOM (Software Bill of Materials)
   - Always succeeds (never blocks PRs)
   - Provides detailed vulnerability information

2. **Security Gate** (`security-gate.yml`)
   - Runs on every PR that modifies images
   - Blocks PRs with CRITICAL vulnerabilities
   - Comments on PR with gate status
   - Must pass for PR to be mergeable

### Security Scanning Process

1. **Automated PR Scans**: Every pull request that modifies image files triggers both security workflows
2. **Vulnerability Detection**: Trivy scans for CRITICAL, HIGH, and MEDIUM severity vulnerabilities
3. **Merge Protection**: PRs with CRITICAL vulnerabilities are automatically blocked by the Security Gate
4. **SARIF Reports**: Scan results are uploaded to GitHub Security tab for tracking
5. **SBOM Generation**: Software Bill of Materials (SBOM) is generated in CycloneDX format for compliance

### Scan Results

Security scan results are available in:
- **PR Comments**: Security Gate posts status and summary
- **GitHub Security Tab**: Detailed SARIF reports with CVE information (from Security Report workflow)
- **Workflow Summaries**: Both workflows provide detailed summaries
- **Workflow Artifacts**: SBOM files are stored for 7 days

### Branch Protection

The `main` branch is protected with required status checks:
- `Security Gate Check` - Must pass (no CRITICAL vulnerabilities)
- `Generate Security Report` - Informational only

See [`.github/BRANCH_PROTECTION.md`](.github/BRANCH_PROTECTION.md) for configuration details.

### Manual Security Scan

You can manually trigger a security scan for any image:

1. Go to the **Actions** tab
2. Select **Docker :: Security Scan** workflow
3. Click **Run workflow**
4. Choose the image to scan

### Fixing Vulnerabilities

If a security scan detects vulnerabilities:

1. Review the scan results in the PR comment or Security tab
2. Update the base image to a newer version
3. Update vulnerable packages in the Dockerfile
4. Push changes to trigger a new scan
5. Merge once the scan passes
