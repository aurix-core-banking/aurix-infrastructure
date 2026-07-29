# Environments

## Dev

Used for local development and feature branch testing.

```bash
# Deploy dev stack
terraform workspace select dev && terraform apply
```

## Staging

Pre-production environment for integration testing and validation.

```bash
terraform workspace select staging && terraform apply
```

## Production

Live customer-facing environment with HA and DR.

```bash
terraform workspace select production && terraform apply
```
