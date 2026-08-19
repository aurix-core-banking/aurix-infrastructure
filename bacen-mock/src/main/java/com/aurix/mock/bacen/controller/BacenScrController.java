package com.aurix.mock.bacen.controller;

import com.aurix.mock.bacen.service.BacenMockService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/bacen/scr")
@CrossOrigin(origins = "*")
public class BacenScrController {
    private static final Logger log = LoggerFactory.getLogger(BacenScrController.class);
    private final BacenMockService bacenMockService;

    public BacenScrController(BacenMockService bacenMockService) {
        this.bacenMockService = bacenMockService;
    }

    @GetMapping("/{cnpj}/situacao")
    public ResponseEntity<Map<String, Object>> consultarSituacaoScr(@PathVariable String cnpj) {
        log.info("[BACEN-SCR] Consultando situação SCR. cnpj={}", cnpj);
        Map<String, Object> resultado = bacenMockService.consultarScr(cnpj);
        return ResponseEntity.ok(resultado);
    }

    @PostMapping("/consulta")
    public ResponseEntity<Map<String, Object>> processarConsultaScr(@RequestBody Map<String, Object> requisicao) {
        log.info("[BACEN-SCR] Processando consulta SCR");
        Map<String, Object> resultado = bacenMockService.processarConsultaScr(requisicao);
        return ResponseEntity.ok(resultado);
    }
}
