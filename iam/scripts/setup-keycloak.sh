#!/bin/bash

# Script de configuração do Keycloak para AUREUS Core Banking
# Este script configura o Keycloak com realm, clientes, usuários e permissões

set -e

echo "============================================="
echo "AUREUS Core Banking - Configuração Keycloak"
echo "============================================="

# Variáveis de configuração
KEYCLOAK_URL="http://localhost:8080"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin123"
REALM_NAME="aurix"

# Aguardar o Keycloak estar disponível
echo "Aguardando Keycloak estar disponível..."
until curl -f -s "${KEYCLOAK_URL}/health/ready" > /dev/null 2>&1; do
    echo "Aguardando Keycloak..."
    sleep 5
done

echo "Keycloak está disponível!"

# Obter token de acesso do admin
echo "Obtendo token de acesso do administrador..."
ADMIN_TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=${ADMIN_USER}" \
    -d "password=${ADMIN_PASSWORD}" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" | jq -r '.access_token')

if [ "$ADMIN_TOKEN" = "null" ] || [ -z "$ADMIN_TOKEN" ]; then
    echo "Erro: Não foi possível obter token de acesso do administrador"
    exit 1
fi

echo "Token de acesso obtido com sucesso!"

# Verificar se o realm já existe
echo "Verificando se o realm '${REALM_NAME}' já existe..."
REALM_EXISTS=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -w "%{http_code}" -o /dev/null)

if [ "$REALM_EXISTS" = "200" ]; then
    echo "Realm '${REALM_NAME}' já existe. Removendo..."
    curl -s -X DELETE "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}" \
        -H "Authorization: Bearer ${ADMIN_TOKEN}"
    echo "Realm removido!"
fi

# Criar realm
echo "Criando realm '${REALM_NAME}'..."
curl -s -X POST "${KEYCLOAK_URL}/admin/realms" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -H "Content-Type: application/json" \
    -d @/opt/keycloak/data/import/aurix-realm.json

echo "Realm criado com sucesso!"

# Aguardar um momento para o realm ser processado
sleep 5

# Criar client scopes
echo "Criando client scopes..."
for scope_file in /opt/keycloak/data/import/aurix-client-scopes.json; do
    if [ -f "$scope_file" ]; then
        echo "Processando client scopes de $scope_file..."
        jq -c '.[]' "$scope_file" | while read -r scope; do
            curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/client-scopes" \
                -H "Authorization: Bearer ${ADMIN_TOKEN}" \
                -H "Content-Type: application/json" \
                -d "$scope"
        done
    fi
done

# Criar clientes
echo "Criando clientes..."
for client_file in /opt/keycloak/data/import/aurix-clients.json; do
    if [ -f "$client_file" ]; then
        echo "Processando clientes de $client_file..."
        jq -c '.[]' "$client_file" | while read -r client; do
            curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients" \
                -H "Authorization: Bearer ${ADMIN_TOKEN}" \
                -H "Content-Type: application/json" \
                -d "$client"
        done
    fi
done

# Criar roles
echo "Criando roles..."
for role_file in /opt/keycloak/data/import/aurix-roles.json; do
    if [ -f "$role_file" ]; then
        echo "Processando roles de $role_file..."
        jq -c '.[]' "$role_file" | while read -r role; do
            curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/roles" \
                -H "Authorization: Bearer ${ADMIN_TOKEN}" \
                -H "Content-Type: application/json" \
                -d "$role"
        done
    fi
done

# Criar grupos
echo "Criando grupos..."
for group_file in /opt/keycloak/data/import/aurix-groups.json; do
    if [ -f "$group_file" ]; then
        echo "Processando grupos de $group_file..."
        jq -c '.[]' "$group_file" | while read -r group; do
            curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/groups" \
                -H "Authorization: Bearer ${ADMIN_TOKEN}" \
                -H "Content-Type: application/json" \
                -d "$group"
        done
    fi
done

# Criar usuários
echo "Criando usuários..."
for user_file in /opt/keycloak/data/import/aurix-users.json; do
    if [ -f "$user_file" ]; then
        echo "Processando usuários de $user_file..."
        jq -c '.[]' "$user_file" | while read -r user; do
            # Extrair username para obter o ID do usuário criado
            username=$(echo "$user" | jq -r '.username')
            
            # Criar usuário
            curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/users" \
                -H "Authorization: Bearer ${ADMIN_TOKEN}" \
                -H "Content-Type: application/json" \
                -d "$user"
            
            # Obter ID do usuário criado
            user_id=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/users?username=${username}" \
                -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0].id')
            
            if [ "$user_id" != "null" ] && [ -n "$user_id" ]; then
                # Definir senha
                echo "Definindo senha para usuário $username..."
                password=$(echo "$user" | jq -r '.credentials[0].value')
                curl -s -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/users/${user_id}/reset-password" \
                    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
                    -H "Content-Type: application/json" \
                    -d "{\"type\":\"password\",\"value\":\"${password}\",\"temporary\":false}"
                
                # Atribuir roles
                echo "Atribuindo roles para usuário $username..."
                roles=$(echo "$user" | jq -r '.realmRoles[]? // empty')
                if [ -n "$roles" ]; then
                    echo "$roles" | while read -r role; do
                        role_id=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/roles/${role}" \
                            -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.id')
                        
                        if [ "$role_id" != "null" ] && [ -n "$role_id" ]; then
                            curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/users/${user_id}/role-mappings/realm" \
                                -H "Authorization: Bearer ${ADMIN_TOKEN}" \
                                -H "Content-Type: application/json" \
                                -d "[{\"id\":\"${role_id}\",\"name\":\"${role}\"}]"
                        fi
                    done
                fi
            fi
        done
    fi
done

echo "============================================="
echo "Configuração do Keycloak concluída!"
echo "============================================="
echo "Realm: ${REALM_NAME}"
echo "URL: ${KEYCLOAK_URL}/realms/${REALM_NAME}"
echo "Admin Console: ${KEYCLOAK_URL}/admin"
echo "============================================="
echo "Usuários criados:"
echo "- admin / admin123 (Administrador)"
echo "- gerente / gerente123 (Gerente)"
echo "- operador / operador123 (Operador)"
echo "- cliente.teste / cliente123 (Cliente)"
echo "============================================="
