-- Particionamento RANGE por mes/ano (opcional - Roadmap 14.7)
-- Usar quando o volume justificar (milhoes de linhas ou lentidao em relatorios por periodo).
-- Ver: docs/banco-dados/estrategia-particionamento-14.7.md
--
-- Este script contem:
-- 1. Função para criar partição mensal para uma tabela particionada.
-- 2. Exemplo de definicao de tabela particionada (transacoes) para NOVO ambiente.
-- 3. Nao altera tabelas existentes; migracao de tabela existente exige procedimento separado.

-- =============================================================================
-- 1. Função: criar partição mensal para tabela particionada por RANGE (data)
-- =============================================================================
-- Uso: SELECT aurix.criar_particao_mensal('aurix.transacoes', 'data_transacao', '2026-02-01');
-- Cria partição para o mes de fevereiro de 2026 (desde 2026-02-01 ate 2026-03-01 exclusive).

CREATE OR REPLACE FUNCTION aurix.criar_particao_mensal(
  p_tabela_qualificada TEXT,
  p_coluna_data TEXT,
  p_inicio_mes DATE
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  v_schema TEXT;
  v_tabela TEXT;
  v_partition_name TEXT;
  v_inicio_ts TIMESTAMP;
  v_fim_ts TIMESTAMP;
  v_sql TEXT;
BEGIN
  v_schema := split_part(p_tabela_qualificada, '.', 1);
  v_tabela := split_part(p_tabela_qualificada, '.', 2);
  v_partition_name := v_tabela || '_y' || to_char(p_inicio_mes, 'YYYYmMM');
  v_inicio_ts := p_inicio_mes::TIMESTAMP;
  v_fim_ts := (p_inicio_mes + INTERVAL '1 month')::TIMESTAMP;

  v_sql := format(
    'CREATE TABLE IF NOT EXISTS %I.%I PARTITION OF %I.%I FOR VALUES FROM (%L) TO (%L)',
    v_schema, v_partition_name, v_schema, v_tabela, v_inicio_ts, v_fim_ts
  );
  EXECUTE v_sql;
  RETURN v_schema || '.' || v_partition_name;
END;
$$;

COMMENT ON FUNCTION aurix.criar_particao_mensal(TEXT, TEXT, DATE) IS
  'Cria partição mensal para tabela particionada por RANGE na coluna de data. Roadmap 14.7.';

-- =============================================================================
-- 2. Exemplo: tabela transacoes particionada (APENAS para novo ambiente)
-- =============================================================================
-- Nao executar se aurix.transacoes ja existir como tabela nao particionada.
-- Para ambiente existente: criar transacoes_partitioned, migrar dados por mes,
-- depois em janela de manutencao: renomear transacoes -> transacoes_old,
-- transacoes_partitioned -> transacoes, recriar FKs e indices.

/*
CREATE TABLE IF NOT EXISTS aurix.transacoes (
    id BIGSERIAL,
    tenant_id VARCHAR(64),
    conta_origem_id BIGINT,
    conta_destino_id BIGINT,
    tipo_transacao VARCHAR(50) NOT NULL,
    valor NUMERIC(15,2) NOT NULL,
    descricao VARCHAR(500),
    status VARCHAR(50) NOT NULL DEFAULT 'PENDENTE',
    codigo_transacao VARCHAR(100),
    dados_pix JSONB,
    dados_ted JSONB,
    data_transacao TIMESTAMP NOT NULL DEFAULT NOW(),
    data_processamento TIMESTAMP,
    data_criacao TIMESTAMP NOT NULL DEFAULT NOW(),
    data_atualizacao TIMESTAMP,
    versao INTEGER DEFAULT 1,
    PRIMARY KEY (id, data_transacao)
) PARTITION BY RANGE (data_transacao);

CREATE INDEX IF NOT EXISTS idx_transacoes_part_tenant_data
  ON aurix.transacoes (tenant_id, data_transacao DESC);
CREATE INDEX IF NOT EXISTS idx_transacoes_part_conta_origem_data
  ON aurix.transacoes (conta_origem_id, data_transacao DESC);
CREATE INDEX IF NOT EXISTS idx_transacoes_part_status_data
  ON aurix.transacoes (status, data_transacao);

SELECT aurix.criar_particao_mensal('aurix.transacoes', 'data_transacao', CURRENT_DATE::DATE);
SELECT aurix.criar_particao_mensal('aurix.transacoes', 'data_transacao', (CURRENT_DATE + INTERVAL '1 month')::DATE);
*/

-- =============================================================================
-- 3. Instrucoes para outras tabelas
-- =============================================================================
-- Replicar o padrao para: movimentos_conta (data_movimento), liquidacoes (data_liquidacao),
-- transacoes_spi (data_criacao), transacoes_str (data_criacao), logs_auditoria (data_acao),
-- relatorios_bacen (data_referencia ou data_criacao).
-- Em cada caso: criar tabela PARTITION BY RANGE (coluna_data), criar partições
-- via criar_particao_mensal ou equivalente para data_referencia (partição mensal).
-- Job recomendado: mensalmente chamar criar_particao_mensal para o proximo mes.
