package com.example.ev_charging_system1.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;

/**
 * Issues / parses JWT access tokens. HS256 with a base64-encoded secret.
 * Secret MUST be at least 256 bits (32 bytes raw). Configure via JWT_SECRET env.
 */
@Slf4j
@Component
public class JwtUtil {

    @Value("${app.jwt.secret}")
    private String secret;

    @Value("${app.jwt.expiration-ms:86400000}") // 24h default
    private long expirationMs;

    private SecretKey key;

    @PostConstruct
    public void init() {
        try {
            byte[] decoded = Decoders.BASE64.decode(secret);
            this.key = Keys.hmacShaKeyFor(decoded);
        } catch (IllegalArgumentException e) {
            // fallback: treat raw string as bytes (dev convenience). Still requires 32+ chars.
            this.key = Keys.hmacShaKeyFor(secret.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        }
    }

    public String issue(Long userPk, String loginId, String role) {
        Date now = new Date();
        return Jwts.builder()
                .subject(String.valueOf(userPk))
                .claim("loginId", loginId)
                .claim("role", role)
                .issuedAt(now)
                .expiration(new Date(now.getTime() + expirationMs))
                .signWith(key)
                .compact();
    }

    public Claims parse(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public long getExpirationMs() {
        return expirationMs;
    }
}
