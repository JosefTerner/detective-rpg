package com.game.gateway.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.web.server.SecurityWebFilterChain;

/**
 * WebFlux security configuration for the API Gateway.
 *
 * JWT authentication and header propagation are handled by {@link JwtAuthenticationFilter}
 * (a GlobalFilter that runs before routing). This config's responsibility is limited to:
 *   - disabling unused Spring Security features (form-login, HTTP basic, CSRF)
 *   - declaring which paths are public vs. protected (mirroring the filter's public-path list)
 *   - permitting the OPTIONS pre-flight requests that browsers send before every CORS request
 *
 * CORS is configured in application.yml via spring.cloud.gateway.globalcors so that the
 * Gateway's built-in CORS handling applies before Spring Security sees the request.
 */
@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        return http
                .csrf(ServerHttpSecurity.CsrfSpec::disable)
                .httpBasic(ServerHttpSecurity.HttpBasicSpec::disable)
                .formLogin(ServerHttpSecurity.FormLoginSpec::disable)
                .authorizeExchange(auth -> auth
                        // Pre-flight requests must always pass
                        .pathMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        // Public endpoints — no JWT required
                        .pathMatchers(HttpMethod.POST, "/players/register", "/players/login").permitAll()
                        .pathMatchers("/actuator/**").permitAll()
                        // Fallback endpoint used by circuit breakers
                        .pathMatchers("/fallback").permitAll()
                        // Everything else is handled by JwtAuthenticationFilter;
                        // Spring Security defers to it by permitting all here
                        .anyExchange().permitAll()
                )
                .build();
    }
}
