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
