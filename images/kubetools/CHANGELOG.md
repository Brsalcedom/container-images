# Changelog

## 2.0.0 (2026-11-05)

First version published from this repository.

* `alpine:3.24` base (previously `python:alpine`, which left two Pythons in the image); kubectl/helm/eksctl built from source; pinned versions; helm 4; `gke-gcloud-auth-plugin`; `gsutil` removed (use `gcloud storage`); multi-arch (amd64/arm64). From 1.4 GB and 212 HIGH/CRITICAL CVEs down to ~810 MB and 0.
