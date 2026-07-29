-- 🏛️ AUREUS - PostgreSQL Initialization Script
-- Script de inicialização do banco de dados AUREUS

-- Criar schema principal
CREATE SCHEMA IF NOT EXISTS aurix;

-- Configurar extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Tabela de contas
CREATE TABLE IF NOT EXISTS aurix.contas (
    id BIGSERIAL PRIMARY KEY,
    numero_conta VARCHAR(20) UNIQUE NOT NULL,
    cpf VARCHAR(11) NOT NULL,
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    telefone VARCHAR(20),
    saldo DECIMAL(15,2) DEFAULT 0.00,
    limite DECIMAL(15,2) DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'ATIVA',
    tipo_conta VARCHAR(20) DEFAULT 'CORRENTE',
    dados_extras JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    version INTEGER DEFAULT 1
);

-- Tabela de transações
CREATE TABLE IF NOT EXISTS aurix.transacoes (
    id BIGSERIAL PRIMARY KEY,
    conta_origem_id BIGINT REFERENCES aurix.contas(id),
    conta_destino_id BIGINT REFERENCES aurix.contas(id),
    valor DECIMAL(15,2) NOT NULL,
    tipo VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDENTE',
    descricao TEXT,
    dados_extras JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    version INTEGER DEFAULT 1
);

-- Tabela de pagamentos PIX
CREATE TABLE IF NOT EXISTS aurix.pix_pagamentos (
    id BIGSERIAL PRIMARY KEY,
    transacao_id BIGINT REFERENCES aurix.transacoes(id),
    chave_pix VARCHAR(255) NOT NULL,
    tipo_chave VARCHAR(20) NOT NULL,
    valor DECIMAL(15,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDENTE',
    end_to_end_id VARCHAR(32),
    txid VARCHAR(32),
    dados_extras JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabela de crédito
CREATE TABLE IF NOT EXISTS aurix.credito_solicitacoes (
    id BIGSERIAL PRIMARY KEY,
    conta_id BIGINT REFERENCES aurix.contas(id),
    valor_solicitado DECIMAL(15,2) NOT NULL,
    valor_aprovado DECIMAL(15,2),
    taxa_juros DECIMAL(5,4),
    prazo_meses INTEGER,
    status VARCHAR(20) DEFAULT 'PENDENTE',
    motivo_rejeicao TEXT,
    dados_analise JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabela de investimentos
CREATE TABLE IF NOT EXISTS aurix.investimentos (
    id BIGSERIAL PRIMARY KEY,
    conta_id BIGINT REFERENCES aurix.contas(id),
    tipo VARCHAR(50) NOT NULL,
    valor_aplicado DECIMAL(15,2) NOT NULL,
    valor_atual DECIMAL(15,2),
    rentabilidade DECIMAL(5,4),
    data_aplicacao TIMESTAMP DEFAULT NOW(),
    data_vencimento TIMESTAMP,
    status VARCHAR(20) DEFAULT 'ATIVO',
    dados_extras JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabela de auditoria
CREATE TABLE IF NOT EXISTS aurix.auditoria (
    id BIGSERIAL PRIMARY KEY,
    tabela VARCHAR(100) NOT NULL,
    operacao VARCHAR(10) NOT NULL,
    registro_id BIGINT,
    dados_antigos JSONB,
    dados_novos JSONB,
    usuario VARCHAR(100),
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_contas_cpf ON aurix.contas(cpf);
CREATE INDEX IF NOT EXISTS idx_contas_numero ON aurix.contas(numero_conta);
CREATE INDEX IF NOT EXISTS idx_contas_status ON aurix.contas(status);
CREATE INDEX IF NOT EXISTS idx_contas_dados_gin ON aurix.contas USING GIN (dados_extras);

CREATE INDEX IF NOT EXISTS idx_transacoes_conta_origem ON aurix.transacoes(conta_origem_id);
CREATE INDEX IF NOT EXISTS idx_transacoes_conta_destino ON aurix.transacoes(conta_destino_id);
CREATE INDEX IF NOT EXISTS idx_transacoes_created_at ON aurix.transacoes(created_at);
CREATE INDEX IF NOT EXISTS idx_transacoes_tipo ON aurix.transacoes(tipo);
CREATE INDEX IF NOT EXISTS idx_transacoes_status ON aurix.transacoes(status);
CREATE INDEX IF NOT EXISTS idx_transacoes_dados_gin ON aurix.transacoes USING GIN (dados_extras);

CREATE INDEX IF NOT EXISTS idx_pix_chave ON aurix.pix_pagamentos(chave_pix);
CREATE INDEX IF NOT EXISTS idx_pix_txid ON aurix.pix_pagamentos(txid);
CREATE INDEX IF NOT EXISTS idx_pix_status ON aurix.pix_pagamentos(status);

CREATE INDEX IF NOT EXISTS idx_credito_conta ON aurix.credito_solicitacoes(conta_id);
CREATE INDEX IF NOT EXISTS idx_credito_status ON aurix.credito_solicitacoes(status);
CREATE INDEX IF NOT EXISTS idx_credito_created_at ON aurix.credito_solicitacoes(created_at);

CREATE INDEX IF NOT EXISTS idx_investimentos_conta ON aurix.investimentos(conta_id);
CREATE INDEX IF NOT EXISTS idx_investimentos_tipo ON aurix.investimentos(tipo);
CREATE INDEX IF NOT EXISTS idx_investimentos_status ON aurix.investimentos(status);

CREATE INDEX IF NOT EXISTS idx_auditoria_tabela ON aurix.auditoria(tabela);
CREATE INDEX IF NOT EXISTS idx_auditoria_operacao ON aurix.auditoria(operacao);
CREATE INDEX IF NOT EXISTS idx_auditoria_created_at ON aurix.auditoria(created_at);

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION aurix.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.version = OLD.version + 1;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para updated_at
CREATE TRIGGER update_contas_updated_at BEFORE UPDATE ON aurix.contas
    FOR EACH ROW EXECUTE FUNCTION aurix.update_updated_at_column();

CREATE TRIGGER update_transacoes_updated_at BEFORE UPDATE ON aurix.transacoes
    FOR EACH ROW EXECUTE FUNCTION aurix.update_updated_at_column();

CREATE TRIGGER update_pix_updated_at BEFORE UPDATE ON aurix.pix_pagamentos
    FOR EACH ROW EXECUTE FUNCTION aurix.update_updated_at_column();

CREATE TRIGGER update_credito_updated_at BEFORE UPDATE ON aurix.credito_solicitacoes
    FOR EACH ROW EXECUTE FUNCTION aurix.update_updated_at_column();

CREATE TRIGGER update_investimentos_updated_at BEFORE UPDATE ON aurix.investimentos
    FOR EACH ROW EXECUTE FUNCTION aurix.update_updated_at_column();

-- Função de auditoria
CREATE OR REPLACE FUNCTION aurix.audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO aurix.auditoria (tabela, operacao, registro_id, dados_antigos, usuario, ip_address, user_agent)
        VALUES (TG_TABLE_NAME, TG_OP, OLD.id, row_to_json(OLD), current_user, inet_client_addr(), current_setting('request.headers', true));
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO aurix.auditoria (tabela, operacao, registro_id, dados_antigos, dados_novos, usuario, ip_address, user_agent)
        VALUES (TG_TABLE_NAME, TG_OP, NEW.id, row_to_json(OLD), row_to_json(NEW), current_user, inet_client_addr(), current_setting('request.headers', true));
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO aurix.auditoria (tabela, operacao, registro_id, dados_novos, usuario, ip_address, user_agent)
        VALUES (TG_TABLE_NAME, TG_OP, NEW.id, row_to_json(NEW), current_user, inet_client_addr(), current_setting('request.headers', true));
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

-- Triggers de auditoria
CREATE TRIGGER audit_contas AFTER INSERT OR UPDATE OR DELETE ON aurix.contas
    FOR EACH ROW EXECUTE FUNCTION aurix.audit_trigger();

CREATE TRIGGER audit_transacoes AFTER INSERT OR UPDATE OR DELETE ON aurix.transacoes
    FOR EACH ROW EXECUTE FUNCTION aurix.audit_trigger();

CREATE TRIGGER audit_pix AFTER INSERT OR UPDATE OR DELETE ON aurix.pix_pagamentos
    FOR EACH ROW EXECUTE FUNCTION aurix.audit_trigger();

CREATE TRIGGER audit_credito AFTER INSERT OR UPDATE OR DELETE ON aurix.credito_solicitacoes
    FOR EACH ROW EXECUTE FUNCTION aurix.audit_trigger();

CREATE TRIGGER audit_investimentos AFTER INSERT OR UPDATE OR DELETE ON aurix.investimentos
    FOR EACH ROW EXECUTE FUNCTION aurix.audit_trigger();

-- Dados de exemplo para desenvolvimento
INSERT INTO aurix.contas (numero_conta, cpf, nome, email, telefone, saldo, limite, status, tipo_conta) VALUES
('12345-6', '12345678901', 'João Silva', 'joao@email.com', '11999999999', 1000.00, 5000.00, 'ATIVA', 'CORRENTE'),
('67890-1', '98765432100', 'Maria Santos', 'maria@email.com', '11888888888', 2500.00, 10000.00, 'ATIVA', 'CORRENTE'),
('11111-2', '11111111111', 'Pedro Costa', 'pedro@email.com', '11777777777', 500.00, 2000.00, 'ATIVA', 'POUPANCA')
ON CONFLICT (numero_conta) DO NOTHING;

-- Comentários para documentação
COMMENT ON SCHEMA aurix IS 'Schema principal do sistema AUREUS Core Banking';
COMMENT ON TABLE aurix.contas IS 'Tabela de contas bancárias';
COMMENT ON TABLE aurix.transacoes IS 'Tabela de transações bancárias';
COMMENT ON TABLE aurix.pix_pagamentos IS 'Tabela de pagamentos PIX';
COMMENT ON TABLE aurix.credito_solicitacoes IS 'Tabela de solicitações de crédito';
COMMENT ON TABLE aurix.investimentos IS 'Tabela de investimentos';
COMMENT ON TABLE aurix.auditoria IS 'Tabela de auditoria do sistema';

-- Configurações de performance
ALTER TABLE aurix.contas SET (fillfactor = 90);
ALTER TABLE aurix.transacoes SET (fillfactor = 90);
ALTER TABLE aurix.pix_pagamentos SET (fillfactor = 90);
ALTER TABLE aurix.credito_solicitacoes SET (fillfactor = 90);
ALTER TABLE aurix.investimentos SET (fillfactor = 90);
ALTER TABLE aurix.auditoria SET (fillfactor = 100);

-- Estatísticas atualizadas
ANALYZE aurix.contas;
ANALYZE aurix.transacoes;
ANALYZE aurix.pix_pagamentos;
ANALYZE aurix.credito_solicitacoes;
ANALYZE aurix.investimentos;
ANALYZE aurix.auditoria;
