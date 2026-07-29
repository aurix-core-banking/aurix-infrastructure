# Architecture

## Overview

Infrastructure as Code (IaC) manages all cloud resources and Kubernetes clusters for the Aurix platform across dev, staging, and production environments.

## Components

- **Terraform** — cloud resource provisioning (AWS/GCP)
- **Kubernetes** — container orchestration with Helm charts
- **Docker** — container images and Compose files for local dev
- **Monitoring** — Prometheus, Grafana, Loki, Alertmanager
- **CI/CD** — GitHub Actions for automated deployment

## Environment Strategy

| Environment | Purpose | K8s Cluster | DB |
|-------------|---------|-------------|-----|
| `dev` | Development & testing | Single-node | Shared dev |
| `staging` | Pre-production validation | Multi-node | Isolated |
| `production` | Live customer traffic | HA multi-az | HA replicated |

## Directory

```
infra/
├── terraform/       # Terraform modules
├── k8s/             # Kubernetes manifests + Helm values
├── monitoring/      # Prometheus, Grafana configs
├── docker/          # Dockerfiles
└── scripts/         # Utility scripts
```
