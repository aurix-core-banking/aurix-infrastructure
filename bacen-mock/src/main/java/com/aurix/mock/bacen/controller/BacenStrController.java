package com.aurix.mock.bacen.controller;

import com.aurix.mock.bacen.service.BacenMockService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/bacen/str")
@CrossOrigin(origins = "*")
public class BacenStrController {
    private static final Logger log = LoggerFactory.getLogger(BacenStrController.class);
    private final BacenMockService bacenMockService;

    public BacenStrController(BacenMockService bacenMockService) {
        this.bacenMockService = bacenMockService;
    }

    @PostMapping("/liquidar")
    public ResponseEntity<Map<String, Object>> liquidarStr(@RequestBody Map<String, Object> requisicao) {
        log.info("[BACEN-STR] Recebida requisição de liquidação STR");
        Map<String, Object> resultado = bacenMockService.processarLiquidacaoStr(requisicao);
        return ResponseEntity.status(HttpStatus.CREATED).body(resultado);
    }

    @GetMapping("/{id}/status")
    public ResponseEntity<Map<String, Object>> consultarStatusStr(@PathVariable String id) {
        log.info("[BACEN-STR] Consultando status STR. id={}", id);
        Map<String, Object> resultado = bacenMockService.consultarStatusStr(id);
        return ResponseEntity.ok(resultado);
    }
}
