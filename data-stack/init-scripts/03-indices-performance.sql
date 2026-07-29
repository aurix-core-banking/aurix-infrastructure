-- Indices para performance da camada transacional (OLTP)
-- Aplicar apos o schema estar criado (ddl-auto ou migrations)
-- Ver: docs/banco-dados/performance-transacional.md

-- transacoes: consultas por tenant e periodo (extratos, relatorios)
CREATE INDEX IF NOT EXISTS idx_transacoes_tenant_data
  ON aurix.transacoes (tenant_id, data_transacao DESC);

-- transacoes: extrato por conta origem
CREATE INDEX IF NOT EXISTS idx_transacoes_conta_origem_data
  ON aurix.transacoes (conta_origem_id, data_transacao DESC);

-- transacoes: extrato por conta destino
CREATE INDEX IF NOT EXISTS idx_transacoes_conta_destino_data
  ON aurix.transacoes (conta_destino_id, data_transacao DESC);

-- transacoes: pendentes por periodo (liquidacao, batch)
CREATE INDEX IF NOT EXISTS idx_transacoes_status_data
  ON aurix.transacoes (status, data_transacao)
  WHERE status = 'PENDENTE';

-- contas: buscas por tenant + cliente (ja existe idx_contas_tenant_id em 02)
CREATE INDEX IF NOT EXISTS idx_contas_tenant_cliente
  ON aurix.contas (tenant_id, cliente_id);

-- clientes: buscas por tenant + status (ja existe idx_clientes_tenant_id em 02)
CREATE INDEX IF NOT EXISTS idx_clientes_tenant_status
  ON aurix.clientes (tenant_id, status);
