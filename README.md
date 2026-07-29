# Aurix Infrastructure

Infrastructure as Code for the Aurix platform.

## Overview

Terraform modules, Kubernetes manifests, and CI/CD configuration for deploying and managing the entire Aurix ecosystem across environments (dev, staging, production).

## Components

- **terraform/** — AWS/GCP infrastructure provisioning
- **k8s/** — Kubernetes manifests
- **docker/** — Dockerfiles and Compose files
- **monitoring/** — Prometheus, Grafana, Loki configs

## Tech Stack

- Terraform / OpenTofu
- Kubernetes + Helm
- Docker
- GitHub Actions

## Related

- [aurix-core-banking](https://github.com/aureus-platform/aurix-core-banking)
- [aurix-backend](https://github.com/aureus-platform/aurix-backend)
- [aurix-frontend](https://github.com/aureus-platform/aurix-frontend)
