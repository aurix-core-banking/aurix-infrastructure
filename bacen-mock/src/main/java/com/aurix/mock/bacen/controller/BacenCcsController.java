package com.aurix.mock.bacen.controller;

import com.aurix.mock.bacen.service.BacenMockService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/bacen/ccs")
@CrossOrigin(origins = "*")
public class BacenCcsController {
    private static final Logger log = LoggerFactory.getLogger(BacenCcsController.class);
    private final BacenMockService bacenMockService;

    public BacenCcsController(BacenMockService bacenMockService) {
        this.bacenMockService = bacenMockService;
    }

    @GetMapping("/{cpf}/titularidades")
    public ResponseEntity<Map<String, Object>> consultarTitularidades(@PathVariable String cpf) {
        log.info("[BACEN-CCS] Consultando titularidades. cpf={}", cpf);
        Map<String, Object> resultado = bacenMockService.consultarCcs(cpf);
        return ResponseEntity.ok(resultado);
    }

    @PostMapping("/consulta")
    public ResponseEntity<Map<String, Object>> processarConsultaCcs(@RequestBody Map<String, Object> requisicao) {
        log.info("[BACEN-CCS] Processando consulta CCS");
        Map<String, Object> resultado = bacenMockService.processarConsultaCcs(requisicao);
        return ResponseEntity.ok(resultado);
    }
}
