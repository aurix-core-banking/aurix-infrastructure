package com.aurix.mock.bacen.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class BacenMockService {
    private static final Logger log = LoggerFactory.getLogger(BacenMockService.class);
    private static final DateTimeFormatter FORMATO_DATA_HORA = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSS");

    @Value("${mock.bacen.delay-ms:200}")
    private long delayMs;

    @Value("${mock.bacen.cenario:SUCESSO}")
    private String cenarioPadrao;

    private final Map<String, Map<String, Object>> registrosPix = new ConcurrentHashMap<>();
    private final Map<String, Map<String, Object>> registrosStr = new ConcurrentHashMap<>();
    private final Map<String, Map<String, Object>> registrosRequisicoes = new ConcurrentHashMap<>();

    public Map<String, Object> processarLiquidacaoPix(Map<String, Object> requisicao) {
        String e2eId = "E" + UUID.randomUUID().toString().replace("-", "").substring(0, 32);
        String idempotencia = (String) requisicao.getOrDefault("idempotencia", UUID.randomUUID().toString());
        String agora = LocalDateTime.now().format(FORMATO_DATA_HORA);

        log.info("[BACEN-SPI] Recebida solicitação de liquidação PIX. e2eId={}, idempotencia={}", e2eId, idempotencia);

        aguardarDelay();
        registrarRequisicao("PIX_SPI", requisicao);

        Map<String, Object> registro = new ConcurrentHashMap<>();
        registro.put("endToEndId", e2eId);
        registro.put("status", "LIQUIDADA");
        registro.put("dataHoraLiquidacao", agora);
        registro.put("ispbOrigem", requisicao.getOrDefault("ispbOrigem", "00000000"));
        registro.put("ispbDestino", requisicao.getOrDefault("ispbDestino", "12345678"));
        registro.put("valor", requisicao.getOrDefault("valor", "0.00"));
        registro.put("chave", requisicao.getOrDefault("chave", ""));
        registro.put("idempotencia", idempotencia);
        registrosPix.put(e2eId, registro);

        log.info("[BACEN-SPI] Liquidação PIX processada. e2eId={}, status=LIQUIDADA", e2eId);

        return montarRespostaSucesso(e2eId, "LIQUIDADA", agora);
    }

    public Map<String, Object> consultarStatusPix(String e2eId) {
        log.info("[BACEN-SPI] Consultando status PIX. e2eId={}", e2eId);
        aguardarDelay();
        registrarRequisicao("PIX_STATUS", Map.of("e2eId", e2eId));

        Map<String, Object> registro = registrosPix.get(e2eId);
        if (registro == null) {
            log.warn("[BACEN-SPI] PIX não encontrado. e2eId={}", e2eId);
            return montarRespostaErro("PIX_NAO_ENCONTRADO", "Transação PIX não encontrada para o e2eId informado");
        }

        return montarRespostaConsulta(registro);
    }

    public Map<String, Object> validarChavePix(Map<String, Object> requisicao) {
        String chave = (String) requisicao.getOrDefault("chave", "");
        String tipoChave = (String) requisicao.getOrDefault("tipoChave", "CPF");

        log.info("[BACEN-SPI] Validando chave PIX. chave={}, tipo={}", chave, tipoChave);
        aguardarDelay();
        registrarRequisicao("PIX_CHAVE_VALIDAR", requisicao);

        Map<String, Object> resultado = new ConcurrentHashMap<>();
        resultado.put("chave", chave);
        resultado.put("tipoChave", tipoChave);
        resultado.put("valida", true);
        resultado.put("titularidade", Map.of(
                "tipoPessoa", "PF",
                "nome", "Titular Mock",
                "documento", "000.000.000-00"
        ));
        resultado.put("ispb", "00000000");
        resultado.put("instituicao", "Banco Aurix Mock");
        resultado.put("dataHoraConsulta", LocalDateTime.now().format(FORMATO_DATA_HORA));

        log.info("[BACEN-SPI] Chave PIX validada com sucesso. chave={}", chave);
        return resultado;
    }

    public Map<String, Object> processarLiquidacaoStr(Map<String, Object> requisicao) {
        String strId = "STR" + UUID.randomUUID().toString().replace("-", "").substring(0, 29);
        String agora = LocalDateTime.now().format(FORMATO_DATA_HORA);

        log.info("[BACEN-STR] Recebida solicitação de liquidação STR. strId={}", strId);
        aguardarDelay();
        requisicao.put("_strId", strId);
        registrarRequisicao("STR_LIQUIDAR", requisicao);

        Map<String, Object> registro = new ConcurrentHashMap<>();
        registro.put("strId", strId);
        registro.put("status", "LIQUIDADA");
        registro.put("dataHoraLiquidacao", agora);
        registro.put("compensacao", requisicao.getOrDefault("compensacao", "SPB"));
        registro.put("valor", requisicao.getOrDefault("valor", "0.00"));
        registro.put("bancoOrigem", requisicao.getOrDefault("bancoOrigem", "000"));
        registro.put("bancoDestino", requisicao.getOrDefault("bancoDestino", "000"));
        registrosStr.put(strId, registro);

        log.info("[BACEN-STR] Liquidação STR processada. strId={}, status=LIQUIDADA", strId);

        Map<String, Object> resposta = new ConcurrentHashMap<>();
        resposta.put("sucesso", true);
        resposta.put("strId", strId);
        resposta.put("status", "LIQUIDADA");
        resposta.put("dataHoraLiquidacao", agora);
        resposta.put("mensagem", "Liquidação STR processada com sucesso (simulação)");
        return resposta;
    }

    public Map<String, Object> consultarStatusStr(String strId) {
        log.info("[BACEN-STR] Consultando status STR. strId={}", strId);
        aguardarDelay();
        registrarRequisicao("STR_STATUS", Map.of("strId", strId));

        Map<String, Object> registro = registrosStr.get(strId);
        if (registro == null) {
            log.warn("[BACEN-STR] STR não encontrada. strId={}", strId);
            return montarRespostaErro("STR_NAO_ENCONTRADA", "Liquidação STR não encontrada para o ID informado");
        }

        return registro;
    }

    public Map<String, Object> consultarCcs(String cpf) {
        log.info("[BACEN-CCS] Consultando titularidades CCS. cpf={}", cpf);
        aguardarDelay();
        registrarRequisicao("CCS_TITULARIDADES", Map.of("cpf", cpf));

        return Map.of(
                "sucesso", true,
                "cpf", cpf,
                "titularidades", Map.of(
                        "contas", Map.of(
                                "corrente", Map.of(
                                        "quantidade", 1,
                                        "detalhes", Map.of(
                                                "banco", "000",
                                                "agencia", "0001",
                                                "conta", "123456-7",
                                                "tipoConta", "CORRENTE",
                                                "titularidade", "TITULAR"
                                        )
                                ),
                                "poupanca", Map.of("quantidade", 0),
                                "salario", Map.of("quantidade", 0)
                        ),
                        "cartoes", Map.of("quantidade", 1),
                        "credito", Map.of("quantidade", 0)
                ),
                "dataHoraConsulta", LocalDateTime.now().format(FORMATO_DATA_HORA)
        );
    }

    public Map<String, Object> processarConsultaCcs(Map<String, Object> requisicao) {
        String cpf = (String) requisicao.getOrDefault("cpf", "");
        log.info("[BACEN-CCS] Processando consulta CCS completa. cpf={}", cpf);
        aguardarDelay();
        registrarRequisicao("CCS_CONSULTA", requisicao);

        return Map.of(
                "sucesso", true,
                "cpf", cpf,
                "resultado", "CONSULTA_PROCESSADA",
                "dataHoraConsulta", LocalDateTime.now().format(FORMATO_DATA_HORA)
        );
    }

    public Map<String, Object> consultarScr(String cnpj) {
        log.info("[BACEN-SCR] Consultando situação SCR. cnpj={}", cnpj);
        aguardarDelay();
        registrarRequisicao("SCR_SITUACAO", Map.of("cnpj", cnpj));

        return Map.of(
                "sucesso", true,
                "cnpj", cnpj,
                "situacao", Map.of(
                        "risco", "BAIXO",
                        "score", 780,
                        "concentracao", "ADEQUADA",
                        "carteira", "SAUDAVEL",
                        "provisao", "SEM_PROVISAO"
                ),
                "ultimaAtualizacao", LocalDateTime.now().format(FORMATO_DATA_HORA)
        );
    }

    public Map<String, Object> processarConsultaScr(Map<String, Object> requisicao) {
        String cnpj = (String) requisicao.getOrDefault("cnpj", "");
        log.info("[BACEN-SCR] Processando consulta SCR completa. cnpj={}", cnpj);
        aguardarDelay();
        registrarRequisicao("SCR_CONSULTA", requisicao);

        return Map.of(
                "sucesso", true,
                "cnpj", cnpj,
                "resultado", "CONSULTA_PROCESSADA",
                "dataHoraConsulta", LocalDateTime.now().format(FORMATO_DATA_HORA)
        );
    }

    private Map<String, Object> montarRespostaSucesso(String id, String status, String dataHora) {
        return Map.of(
                "sucesso", true,
                "endToEndId", id,
                "status", status,
                "dataHoraLiquidacao", dataHora,
                "mensagem", "Operação processada com sucesso (simulação BACEN)"
        );
    }

    private Map<String, Object> montarRespostaErro(String codigo, String mensagem) {
        return Map.of(
                "sucesso", false,
                "erro", Map.of(
                        "codigo", codigo,
                        "mensagem", mensagem
                )
        );
    }

    private Map<String, Object> montarRespostaConsulta(Map<String, Object> registro) {
        return registro;
    }

    private void aguardarDelay() {
        if (delayMs > 0) {
            try {
                Thread.sleep(delayMs);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
    }

    private void registrarRequisicao(String tipo, Map<String, Object> dados) {
        String id = UUID.randomUUID().toString();
        Map<String, Object> registro = new ConcurrentHashMap<>();
        registro.put("tipo", tipo);
        registro.put("dados", dados);
        registro.put("dataHora", LocalDateTime.now().format(FORMATO_DATA_HORA));
        registrosRequisicoes.put(id, registro);
        log.debug("[BACEN-MOCK] Requisição registrada. id={}, tipo={}", id, tipo);
    }

    public Map<String, Object> obterEstatisticas() {
        return Map.of(
                "totalRequisicoes", registrosRequisicoes.size(),
                "totalPix", registrosPix.size(),
                "totalStr", registrosStr.size(),
                "cenarioAtivo", cenarioPadrao,
                "delayConfiguradoMs", delayMs
        );
    }

    public void limparRegistros() {
        registrosPix.clear();
        registrosStr.clear();
        registrosRequisicoes.clear();
        log.info("[BACEN-MOCK] Todos os registros foram limpos");
    }
}
