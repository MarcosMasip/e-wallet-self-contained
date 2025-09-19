package com.github.yildizmy.config;

import com.github.yildizmy.domain.entity.User;
import com.github.yildizmy.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Ensures deterministic demo credentials in H2 profile regardless of seed drift.
 */
@Slf4j
@Profile("h2")
@Component
@RequiredArgsConstructor
public class H2PasswordResetRunner implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    private static final String DEMO_PASSWORD = "password123";

    @Override
    public void run(String... args) {
        final String encoded = passwordEncoder.encode(DEMO_PASSWORD);
        userRepository.findAll().forEach(u -> updateIfDifferent(u, encoded));
    }

    private void updateIfDifferent(User user, String encoded) {
        // Always reset to guarantee consistency (simpler than hash comparison)
        user.setPassword(encoded);
        userRepository.save(user);
        log.debug("[h2-demo] Reset password for user {}", user.getUsername());
    }
}
