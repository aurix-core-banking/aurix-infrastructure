# AURIX Infrastructure

Este diretório contém todo o "Infrastructure as Code" (IaC) e configurações operacionais da plataforma AURIX.

## 🏗 Estrutura
- **[terraform/](./terraform/)**: Provisionamento de recursos em nuvem (AWS/OpenStack).
- **[docker-compose.yml](./docker-compose.yml)**: Orquestração local para desenvolvimento.
- **[kubernetes/](./kubernetes/)**: Manifestos de deploy para produção.
- **[monitoring/](./monitoring/)**: Configurações de Grafana, Prometheus e ELK.
- **[scripts/](./scripts/)**: Automação de tarefas operacionais.

## 🚀 Como Iniciar

### Ambiente Local
Recomendamos o uso do Makefile na raiz para subir a infra local:
```bash
# Na raiz do projeto
make infra-up
```

Ou diretamente via Docker Compose:
```bash
docker-compose up -d
```

### Provisionamento Nuvem
```bash
cd terraform
terraform init
terraform plan
```

## 🛡 Segurança (DevSecOps)
As políticas de segurança e scans estão localizadas em `devsecops/`.

---
**Stack**: Terraform | Kubernetes | Docker | Ansible

## 🔌 Mapa Canônico de Portas

Este mapa lista a atribuição única de portas host entre todos os `docker-compose.yml` do repositório.
**Ao adicionar um novo serviço**, atualize esta tabela no mesmo pull request para evitar conflitos.

| Porta Host | Serviço | Arquivo Compose |
|-----------|---------|-----------------|
| 80 | nginx | `infra/docker-compose.yml` |
| 443 | nginx (HTTPS) | `infra/docker-compose.yml` |
| 2181 | zookeeper | `data/platform/kafka/docker-compose.yml` |
| 3000 | grafana | `infra/docker-compose.yml` |
| 5432 | postgres | `infra/docker-compose.yml` |
| 5433 | timescaledb | `infra/docker-compose.yml` |
| 5601 | kibana | `infra/docker-compose.yml` |
| 6379 | redis | `infra/docker-compose.yml` |
| 8080 | keycloak | `infra/docker-compose.yml` |
| 8081 | schema-registry | `data/platform/kafka/docker-compose.yml` |
| 8083 | kafka-connect | `data/platform/kafka/docker-compose.yml` |
| **8085** | **kafka-ui** (movido de 8080) | `data/platform/kafka/docker-compose.yml` |
| 8123 | clickhouse HTTP | `infra/docker-compose.yml` |
| 9000 | minio | `infra/docker-compose.yml` |
| 9001 | minio console | `infra/docker-compose.yml` |
| 9002 | clickhouse native | `infra/docker-compose.yml` |
| 9090 | prometheus | `infra/docker-compose.yml` |
| 9092 | kafka | `data/platform/kafka/docker-compose.yml` |
| 9101 | kafka JMX | `data/platform/kafka/docker-compose.yml` |
| 9200 | elasticsearch | `infra/docker-compose.yml` |

> ⚠️ **Conflito resolvido:** A porta `8080` era usada tanto pelo `keycloak` (`infra/docker-compose.yml`) quanto pelo `kafka-ui` (`data/platform/kafka/docker-compose.yml`). O `kafka-ui` foi movido para a porta `8085`.
