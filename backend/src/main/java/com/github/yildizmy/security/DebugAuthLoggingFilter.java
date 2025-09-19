package com.github.yildizmy.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.annotation.Order;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * Temporary debug filter to trace Authorization header and resolved authentication.
 * Remove or disable after diagnosing signup wallet auth issues.
 */
@Slf4j
@Component
@Order(0) // Run early
public class DebugAuthLoggingFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        final String path = request.getRequestURI();
        if (path.startsWith("/api/v1/wallets") || path.startsWith("/api/v1/auth/me")) {
            String authHeader = request.getHeader("Authorization");
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            log.debug("[AUTH-TRACE] Path={} HeaderPresent={} Principal={} Authorities={}",
                    path,
                    authHeader != null,
                    auth != null ? auth.getName() : null,
                    auth != null ? auth.getAuthorities() : null);
        }
        filterChain.doFilter(request, response);
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return false; // we decide inside instead
    }
}
