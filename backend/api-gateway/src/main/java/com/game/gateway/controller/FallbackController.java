package com.game.gateway.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.util.Map;

@RestController
public class FallbackController {

    /**
     * Circuit-breaker fallback for all downstream services.
     * Routes in application.yml point their fallbackUri here when a service is unavailable.
     */
    @RequestMapping("/fallback")
    public Mono<Map<String, String>> fallback(ServerWebExchange exchange) {
        exchange.getResponse().setStatusCode(HttpStatus.SERVICE_UNAVAILABLE);
        exchange.getResponse().getHeaders().setContentType(MediaType.APPLICATION_JSON);
        return Mono.just(Map.of("error", "Service temporarily unavailable. Please try again later."));
    }
}
