-- Indices para estrategia de particionamento e performance (Roadmap 14.7)
-- Aplicar apos o schema e tabelas existirem (ddl-auto ou migrations).
-- Ver: docs/banco-dados/estrategia-particionamento-14.7.md
-- Complementa: 03-indices-performance.sql

-- movimentos_conta: consultas por tenant e periodo; extrato por conta
CREATE INDEX IF NOT EXISTS idx_movimentos_conta_tenant_data
  ON aurix.movimentos_conta (tenant_id, data_movimento DESC);

CREATE INDEX IF NOT EXISTS idx_movimentos_conta_conta_data
  ON aurix.movimentos_conta (conta_id, data_movimento DESC);

CREATE INDEX IF NOT EXISTS idx_movimentos_conta_status_data
  ON aurix.movimentos_conta (status, data_movimento)
  WHERE status = 'PENDENTE';

-- liquidacoes: consultas por tenant e periodo; por transacao
CREATE INDEX IF NOT EXISTS idx_liquidacoes_tenant_data
  ON aurix.liquidacoes (tenant_id, data_liquidacao DESC);

CREATE INDEX IF NOT EXISTS idx_liquidacoes_transacao_data
  ON aurix.liquidacoes (transacao_id, data_liquidacao DESC);

CREATE INDEX IF NOT EXISTS idx_liquidacoes_status_data
  ON aurix.liquidacoes (status, data_liquidacao)
  WHERE status = 'PENDENTE';

-- transacoes_spi: consultas por periodo e status (sem tenant_id na entidade)
CREATE INDEX IF NOT EXISTS idx_transacoes_spi_data_criacao
  ON aurix.transacoes_spi (data_criacao DESC);

CREATE INDEX IF NOT EXISTS idx_transacoes_spi_status_data
  ON aurix.transacoes_spi (status, data_liquidacao);

-- transacoes_str: consultas por periodo e status
CREATE INDEX IF NOT EXISTS idx_transacoes_str_data_criacao
  ON aurix.transacoes_str (data_criacao DESC);

CREATE INDEX IF NOT EXISTS idx_transacoes_str_status_data
  ON aurix.transacoes_str (status, data_liquidacao);

-- logs_auditoria: consultas por tenant e periodo; por entidade
CREATE INDEX IF NOT EXISTS idx_logs_auditoria_tenant_data
  ON aurix.logs_auditoria (tenant_id, data_acao DESC);

CREATE INDEX IF NOT EXISTS idx_logs_auditoria_entidade_data
  ON aurix.logs_auditoria (entidade, data_acao DESC);

CREATE INDEX IF NOT EXISTS idx_logs_auditoria_data_criacao
  ON aurix.logs_auditoria (data_criacao DESC);

-- relatorios_bacen: consultas por data de referencia e status
CREATE INDEX IF NOT EXISTS idx_relatorios_bacen_data_referencia
  ON aurix.relatorios_bacen (data_referencia DESC);

CREATE INDEX IF NOT EXISTS idx_relatorios_bacen_status_data
  ON aurix.relatorios_bacen (status, data_criacao DESC);
