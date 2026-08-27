package com.gridmeter.api.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.gridmeter.api.auth.dto.LoginRequest;
import com.gridmeter.api.customer.Customer;
import com.gridmeter.api.customer.CustomerRepository;
import com.gridmeter.api.support.ComponentTestSupport;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;

/** Component tests for {@link AuthService} against a real Postgres (see ComponentTestSupport). */
class AuthComponentTest extends ComponentTestSupport {

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private CustomerRepository customerRepository;

    private User createUser(String username, String rawPassword, UUID customerId) {
        Instant now = Instant.now();
        return userRepository.save(User.builder()
                .id(UUID.randomUUID())
                .username(username)
                .passwordHash(passwordEncoder.encode(rawPassword))
                .customerId(customerId)
                .createdAt(now)
                .updatedAt(now)
                .build());
    }

    private User createUser(String username, String rawPassword) {
        return createUser(username, rawPassword, Customer.DEFAULT_ID);
    }

    @Test
    void login_validCredentials_returnsToken() {
        String username = "alice-" + UUID.randomUUID();
        createUser(username, "correct-horse-battery-staple");

        var response = authService.login(new LoginRequest(username, "correct-horse-battery-staple"));

        assertThat(response.accessToken()).isNotBlank();
        assertThat(response.tokenType()).isEqualTo("Bearer");
        assertThat(response.expiresInSeconds()).isEqualTo(3600);
    }

    @Test
    void login_embedsTheUsersOwnCustomerIdInTheToken() {
        String username = "carol-" + UUID.randomUUID();
        Instant now = Instant.now();
        Customer otherCustomer = customerRepository.save(Customer.builder()
                .id(UUID.randomUUID())
                .name("Other Customer " + UUID.randomUUID())
                .createdAt(now)
                .updatedAt(now)
                .build());
        createUser(username, "correct-horse-battery-staple", otherCustomer.getId());

        var response = authService.login(new LoginRequest(username, "correct-horse-battery-staple"));

        assertThat(jwtService.extractCustomerId(response.accessToken())).isEqualTo(otherCustomer.getId());
    }

    @Test
    void login_wrongPassword_throwsBadCredentials() {
        String username = "bob-" + UUID.randomUUID();
        createUser(username, "correct-horse-battery-staple");

        assertThatThrownBy(() -> authService.login(new LoginRequest(username, "wrong-password")))
                .isInstanceOf(BadCredentialsException.class);
    }

    // Unknown-username and wrong-password intentionally surface as the SAME exception type —
    // Spring Security's DaoAuthenticationProvider anti-enumeration behavior — asserted here as a
    // deliberate decision, not incidental, mirroring how ReadingComponentTest documents scope
    // boundaries inline.
    @Test
    void login_unknownUsername_throwsSameExceptionTypeAsWrongPassword() {
        assertThatThrownBy(() -> authService.login(new LoginRequest("no-such-user-" + UUID.randomUUID(), "whatever")))
                .isInstanceOf(BadCredentialsException.class);
    }

    @Test
    void login_flywaySeededDemoUser_authenticatesWithDocumentedPassword() {
        var response = authService.login(new LoginRequest("demo", "GridMeter!Demo2026"));

        assertThat(response.accessToken()).isNotBlank();
    }
}
