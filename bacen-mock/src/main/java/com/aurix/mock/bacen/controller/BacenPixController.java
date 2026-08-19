package com.aurix.mock.bacen.controller;

import com.aurix.mock.bacen.service.BacenMockService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/bacen/pix")
@CrossOrigin(origins = "*")
public class BacenPixController {
    private static final Logger log = LoggerFactory.getLogger(BacenPixController.class);
    private final BacenMockService bacenMockService;

    public BacenPixController(BacenMockService bacenMockService) {
        this.bacenMockService = bacenMockService;
    }

    @PostMapping("/spi")
    public ResponseEntity<Map<String, Object>> liquidarPix(@RequestBody Map<String, Object> requisicao) {
        log.info("[BACEN-PIX] Recebida requisição de liquidação SPI");
        Map<String, Object> resultado = bacenMockService.processarLiquidacaoPix(requisicao);
        return ResponseEntity.status(HttpStatus.CREATED).body(resultado);
    }

    @GetMapping("/{e2eId}/status")
    public ResponseEntity<Map<String, Object>> consultarStatusPix(@PathVariable String e2eId) {
        log.info("[BACEN-PIX] Consultando status PIX. e2eId={}", e2eId);
        Map<String, Object> resultado = bacenMockService.consultarStatusPix(e2eId);
        return ResponseEntity.ok(resultado);
    }

    @PostMapping("/chave/validar")
    public ResponseEntity<Map<String, Object>> validarChavePix(@RequestBody Map<String, Object> requisicao) {
        log.info("[BACEN-PIX] Validando chave PIX");
        Map<String, Object> resultado = bacenMockService.validarChavePix(requisicao);
        return ResponseEntity.ok(resultado);
    }
}
