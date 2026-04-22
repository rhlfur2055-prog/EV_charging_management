package com.example.ev_charging_system1.security;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /**
     * Stateless API. CORS is handled by WebMvcConfig#addCorsMappings.
     *
     * Endpoints that must remain reachable without a token (frontend bootstrap,
     * detector posting back results, healthcheck, static images) are listed
     * permitAll. Other endpoints currently default to permitAll as well to keep
     * existing pages working during the JWT rollout — switch to authenticated()
     * once the frontend wires the Authorization header on every call.
     */
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .cors(c -> {})
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .formLogin(AbstractHttpConfigurer::disable)
            .httpBasic(AbstractHttpConfigurer::disable)
            .authorizeHttpRequests(reg -> reg
                .requestMatchers(
                        "/api/users/login",
                        "/api/users/signup",
                        "/api/detection/yolo/detect",   // python worker → spring callback
                        "/actuator/health",
                        "/actuator/info",
                        "/images/**",
                        "/error"
                ).permitAll()
                // Phase 1: keep legacy endpoints open. Flip to .authenticated()
                // per-controller as the frontend migrates to Bearer headers.
                .anyRequest().permitAll()
            )
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
}
