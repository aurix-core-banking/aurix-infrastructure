# Aurix Infrastructure

Docker Compose (30+ serviços), Kubernetes Helm charts (38), Terraform multi-cloud, Vault, PgBouncer, Istio service mesh, Temporal workflows.

## Componentes

### Docker Compose (local dev)

```bash
cd aurix-infrastructure
docker-compose up -d                        # Stack completo
docker-compose up -d postgres kafka redis   # Só infraestrutura
```

19 serviços no `data-stack/docker-compose.yml`:

| Serviço | Porta | Descrição |
|---|---|---|
| Traefik | 8080 | API Gateway |
| PostgreSQL 15 | 5432 | OLTP (aurix_db) |
| Redis 7 | 6379 | Cache |
| Kafka + Zookeeper | 9092 | Event streaming |
| Elasticsearch + Kibana | 9200/5601 | Full-text search |
| Prometheus + Grafana | 9090/3000 | Monitoring |
| MinIO | 9000/9001 | S3-compatible data lake |
| Keycloak 23 | 8443 | Auth |
| ClickHouse | 8123/9002 | OLAP analytics |
| TimescaleDB | 5433 | Time-series |
| Debezium Connect | 8083 | CDC from PostgreSQL |
| Iceberg REST | 8181 | Iceberg catalog |
| Trino | 8090 | Federated SQL |
| Airflow | 8082 | Orchestration |
| Vault | 8200 | Secrets management |
| PgBouncer | 6432 | Connection pooling |
| Temporal | 7233/8088 | Workflow orchestration |

### Kubernetes + Helm (38 charts)

```bash
cd aurix-infrastructure
helm install aureus-core kubernetes/charts/aureus-core/
helm install istio-security kubernetes/charts/istio-security/
helm install temporal kubernetes/charts/temporal/
```

Charts organizados por domínio:
- **Infra**: `infra`, `aureus-gateway`, `aureus-shared`
- **Banking**: `aureus-core`, `aureus-pix`, `aureus-poupanca`, `aureus-salario`
- **Credit**: `aureus-credit`, `aureus-consignado`, `aureus-financiamento`
- **Cards**: `aureus-cartoes`
- **Open Finance**: `aureus-openfinance`, `svc-openfinance`
- **Data**: `aureus-analytics`, `aureus-audit`
- **ML**: `aureus-ai`
- **Security**: `istio-security` (AuthorizationPolicy + RequestAuthentication)
- **Temporal**: `temporal` (workflow orchestration)

### Istio Service Mesh

- **mTLS STRICT**: Todos os pods com sidecar
- **AuthorizationPolicy**: deny-all default + ALLOW por serviço
- **RequestAuthentication**: JWT Keycloak + FAPI-Brazil
- **DestinationRule**: retry, timeout, outlier detection

### Vault (Secrets Management)

```bash
vault secrets enable -path=aurix kv-v2
vault kv put aurix/database/postgres username=aurix_user password=<FORTISSEN>
vault kv put aurix/kafka sasl-username=aurix sasl-password=<FORTISSEN>
```

### Terraform (multi-cloud)

- `terraform/aws/` — EKS, RDS, ElastiCache, S3
- `terraform/azure/` — AKS, Azure SQL, Redis
- `terraform/gcp/` — GKE, Cloud SQL, Memorystore

## Relacionados

- [aurix-backend](https://github.com/aurix-core-banking/aurix-backend)
- [aurix-data-platform](https://github.com/aurix-core-banking/aurix-data-platform)
