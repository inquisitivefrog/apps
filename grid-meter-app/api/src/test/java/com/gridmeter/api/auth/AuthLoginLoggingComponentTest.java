package com.gridmeter.api.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.gridmeter.api.auth.dto.LoginRequest;
import com.gridmeter.api.customer.Customer;
import com.gridmeter.api.support.ComponentTestSupport;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * Component tests for {@link AuthService}'s login audit lines -- the fixed
 * "event=login outcome=... user=..." shape the Grafana "Logins" dashboard parses out of Loki.
 */
@ExtendWith(OutputCaptureExtension.class)
class AuthLoginLoggingComponentTest extends ComponentTestSupport {

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private String createUser(String rawPassword) {
        String username = "erin-" + UUID.randomUUID();
        Instant now = Instant.now();
        userRepository.save(User.builder()
                .id(UUID.randomUUID())
                .username(username)
                .passwordHash(passwordEncoder.encode(rawPassword))
                .customerId(Customer.DEFAULT_ID)
                .createdAt(now)
                .updatedAt(now)
                .build());
        return username;
    }

    @Test
    void successfulLogin_logsSuccessWithUsername(CapturedOutput output) {
        String username = createUser("correct-horse-battery-staple");

        authService.login(new LoginRequest(username, "correct-horse-battery-staple"));

        assertThat(output).contains("event=login outcome=success user=" + username);
        assertThat(output).doesNotContain("correct-horse-battery-staple");
    }

    @Test
    void failedLogin_logsFailureWithAttemptedUsername(CapturedOutput output) {
        String username = createUser("correct-horse-battery-staple");

        assertThatThrownBy(() -> authService.login(new LoginRequest(username, "wrong-password")))
                .isInstanceOf(BadCredentialsException.class);

        assertThat(output).contains("event=login outcome=failure user=" + username);
        assertThat(output).doesNotContain("wrong-password");
    }

    @Test
    void failedLogin_usernameWithNewline_cannotForgeASecondLogLine(CapturedOutput output) {
        String forged = "mallory\n2026-11-18T00:00:00Z  INFO event=login outcome=success user=admin";

        assertThatThrownBy(() -> authService.login(new LoginRequest(forged, "anything")))
                .isInstanceOf(BadCredentialsException.class);

        assertThat(output).contains("event=login outcome=failure user=mallory_2026-11-18T00:00:00Z__INFO");
        assertThat(output).doesNotContain("outcome=success user=admin");
    }
}
