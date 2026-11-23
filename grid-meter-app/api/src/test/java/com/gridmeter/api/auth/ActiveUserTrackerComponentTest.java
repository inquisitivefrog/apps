package com.gridmeter.api.auth;

import static org.assertj.core.api.Assertions.assertThat;

import com.gridmeter.api.auth.dto.LoginRequest;
import com.gridmeter.api.customer.Customer;
import com.gridmeter.api.support.ComponentTestSupport;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * Component tests for {@link ActiveUserTracker} against a real Redis (see ComponentTestSupport):
 * distinct-user counting and the token-lifetime window, which a mocked sorted set can't prove.
 */
class ActiveUserTrackerComponentTest extends ComponentTestSupport {

    @Autowired
    private StringRedisTemplate redis;

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    // A fixed clock per tracker lets one test step through time. Each tracker registers its own
    // gauge, so each gets a fresh registry; the Redis key is the real one, shared with other test
    // classes' logins, so the counting test clears it before and after.
    private ActiveUserTracker trackerAt(Instant now, SimpleMeterRegistry registry) {
        return new ActiveUserTracker(redis, Duration.ofHours(1), registry, Clock.fixed(now, ZoneOffset.UTC));
    }

    @Test
    void repeatLoginsBySameUser_countOnce_andLoginsOlderThanTheWindow_dropOut() {
        redis.delete(ActiveUserTracker.KEY);
        Instant start = Instant.parse("2026-11-17T12:00:00Z");

        trackerAt(start, new SimpleMeterRegistry()).recordLogin("alice");
        trackerAt(start.plusSeconds(60), new SimpleMeterRegistry()).recordLogin("alice");
        trackerAt(start.plusSeconds(120), new SimpleMeterRegistry()).recordLogin("bob");

        SimpleMeterRegistry registry = new SimpleMeterRegistry();
        ActiveUserTracker withinWindow = trackerAt(start.plusSeconds(600), registry);
        withinWindow.refresh();
        assertThat(registry.get("auth.active.users").gauge().value()).isEqualTo(2.0);

        // 61 minutes after alice's last login (at +60s) but only 59 after bob's (at +120s).
        SimpleMeterRegistry laterRegistry = new SimpleMeterRegistry();
        ActiveUserTracker later = trackerAt(start.plusSeconds(60 + 61 * 60), laterRegistry);
        later.refresh();
        assertThat(laterRegistry.get("auth.active.users").gauge().value()).isEqualTo(1.0);

        redis.delete(ActiveUserTracker.KEY);
    }

    @Test
    void successfulLogin_isRecorded() {
        String username = "dave-" + UUID.randomUUID();
        Instant now = Instant.now();
        userRepository.save(User.builder()
                .id(UUID.randomUUID())
                .username(username)
                .passwordHash(passwordEncoder.encode("correct-horse-battery-staple"))
                .customerId(Customer.DEFAULT_ID)
                .createdAt(now)
                .updatedAt(now)
                .build());

        authService.login(new LoginRequest(username, "correct-horse-battery-staple"));

        assertThat(redis.opsForZSet().score(ActiveUserTracker.KEY, username)).isNotNull();
    }
}
