# Changelog

## 2.0.0 (2026-11-05)

Primera versión publicada desde este repositorio.

* base `alpine:3.24` (antes `python:alpine`, que dejaba dos Pythons en la imagen); kubectl/helm/eksctl compilados desde fuente; versiones fijadas; helm 4; `gke-gcloud-auth-plugin`; se elimina `gsutil` (usar `gcloud storage`); multi-arch (amd64/arm64). De 1.4 GB y 212 CVEs HIGH/CRITICAL a ~810 MB y 0.
