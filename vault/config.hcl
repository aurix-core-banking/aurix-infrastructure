# ============================================================
# Vault Configuration — Secrets Management
# Uso: docker exec aurix-vault vault operator init
# ============================================================

# Vault config em JSON
{
  "api_addr": "http://localhost:8200",
  "cluster_addr": "https://vault.aurix.internal:8201",
  "storage": {
    "consul": {
      "address": "consul:8500",
      "path": "vault/"
    }
  },
  "listener": {
    "tcp": {
      "address": "0.0.0.0:8200",
      "tls_disable": true
    }
  },
  "ui": true
}

# ============================================================
# Secrets Engine —KV v2
# ============================================================
# vault secrets enable -path=aurix kv-v2

# ============================================================
# Dados sensíveis
# ============================================================
# vault kv put aurix/database/postgres \
#   username=aurix_user \
#   password=<FORTISSEN>

# vault kv put aurix/database/redis \
#   password=<FORTISSEN>

# vault kv put aurix/kafka \
#   sasl-username=aurix \
#   sasl-password=<FORTISSEN> \
#   ssl-truststore-password=<FORTISSEN>

# vault kv put aurix/keycloak \
#   admin-password=<FORTISSEN>

# vault kv put aurix/encryption \
#   aes-key-base64=<32_BYTES_BASE64>

# vault kv put aurix/bacen/mtls \
#   keystore-password=<FORTISSEN> \
#   truststore-password=<FORTISSEN>

# ============================================================
# AppRole — cada microserviço recebe role_id + secret_id
# ============================================================
# vault auth enable approle
# vault write auth/approle/role/svc-customer \
#   token_policies="aurix-readonly" \
#   token_ttl=1h \
#   token_max_ttl=4h
#
# vault read auth/approle/role/svc-customer/role-id
# vault write -f auth/approle/role/svc-customer/secret-id
