CREATE TABLE IF NOT EXISTS aurix.permissoes_granulares (
    id BIGSERIAL PRIMARY KEY,
    tenant_id VARCHAR(64),
    data_criacao TIMESTAMP NOT NULL DEFAULT NOW(),
    data_atualizacao TIMESTAMP,
    versao INTEGER DEFAULT 1,
    role_id BIGINT NOT NULL,
    recurso VARCHAR(80) NOT NULL,
    acao VARCHAR(40) NOT NULL,
    condicao VARCHAR(500),
    escopo VARCHAR(40) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT true,
    descricao VARCHAR(300)
);

CREATE INDEX IF NOT EXISTS idx_perm_gran_role ON aurix.permissoes_granulares(role_id);
CREATE INDEX IF NOT EXISTS idx_perm_gran_recurso_acao ON aurix.permissoes_granulares(recurso, acao);
CREATE UNIQUE INDEX IF NOT EXISTS idx_perm_gran_uk ON aurix.permissoes_granulares(role_id, recurso, acao, escopo) WHERE ativo = true;

COMMENT ON TABLE aurix.permissoes_granulares IS 'Permissões granulares RBAC: recurso, ação, condição, escopo';
