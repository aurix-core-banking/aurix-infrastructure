ALTER TABLE aurix.contas ADD COLUMN IF NOT EXISTS tenant_id VARCHAR(64) NULL;
ALTER TABLE aurix.clientes ADD COLUMN IF NOT EXISTS tenant_id VARCHAR(64) NULL;
ALTER TABLE aurix.transacoes ADD COLUMN IF NOT EXISTS tenant_id VARCHAR(64) NULL;

UPDATE aurix.contas SET tenant_id = 'default' WHERE tenant_id IS NULL;
UPDATE aurix.clientes SET tenant_id = 'default' WHERE tenant_id IS NULL;
UPDATE aurix.transacoes SET tenant_id = 'default' WHERE tenant_id IS NULL;

CREATE INDEX IF NOT EXISTS idx_contas_tenant_id ON aurix.contas(tenant_id);
CREATE INDEX IF NOT EXISTS idx_clientes_tenant_id ON aurix.clientes(tenant_id);
CREATE INDEX IF NOT EXISTS idx_transacoes_tenant_id ON aurix.transacoes(tenant_id);
