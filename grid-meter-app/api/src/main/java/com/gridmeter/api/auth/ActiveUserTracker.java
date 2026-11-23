package com.gridmeter.api.auth;

import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Clock;
import java.time.Duration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Backs the "active users" panel on the Service Health dashboard: how many distinct users hold a
 * still-valid token, i.e. logged in within the last JWT lifetime.
 *
 * <p>JWTs are stateless (docs/architecture.md's "Authentication"), so there's no session list to
 * count. Instead each successful login is recorded in a Redis sorted set (member = username,
 * score = login time), so a user who logs in repeatedly counts once, and every API replica reports
 * the same shared number rather than its own partial view -- the dashboard takes max() across
 * replicas, not sum().
 *
 * <p>The gauge reads a cached value refreshed in the background, never Redis directly: even with
 * the 2s command timeout (spring.data.redis.timeout, application.yml), a gauge that queried Redis
 * on every scrape would add that stall to /actuator/prometheus during a Redis hang and could make
 * the "API is down" alert fire for an API that is actually up. If a refresh fails, the gauge reports NaN (a gap on
 * the panel) rather than a stale number that looks current.
 */
@Component
public class ActiveUserTracker {

    private static final Logger log = LoggerFactory.getLogger(ActiveUserTracker.class);
    static final String KEY = "auth:active-users";

    private final StringRedisTemplate redis;
    private final Duration window;
    private final Clock clock;
    private volatile double activeUsers = Double.NaN;

    // @Autowired picks this one for Spring; the package-private constructor below exists so tests
    // can pin the window and clock.
    @Autowired
    public ActiveUserTracker(StringRedisTemplate redis, JwtService jwtService, MeterRegistry meterRegistry) {
        this(redis, Duration.ofSeconds(jwtService.getExpirationSeconds()), meterRegistry, Clock.systemUTC());
    }

    ActiveUserTracker(StringRedisTemplate redis, Duration window, MeterRegistry meterRegistry, Clock clock) {
        this.redis = redis;
        this.window = window;
        this.clock = clock;
        Gauge.builder("auth.active.users", this, tracker -> tracker.activeUsers)
                .description("Distinct users who logged in within the JWT lifetime (hold a still-valid token)")
                .register(meterRegistry);
    }

    // Fails open, same as ReadingService's idempotency check: Redis being down must never turn a
    // successful login into a failed one -- the cost is only an undercount on a dashboard panel.
    public void recordLogin(String username) {
        long now = clock.millis();
        try {
            redis.opsForZSet().add(KEY, username, now);
            // Prune here (once per login) rather than on every refresh, keeping refresh read-only.
            redis.opsForZSet().removeRangeByScore(KEY, Double.NEGATIVE_INFINITY, now - window.toMillis());
        } catch (DataAccessException ex) {
            log.warn("Redis unavailable while recording login for active-user count -- login "
                    + "proceeds, count will undercount", ex);
        }
    }

    @Scheduled(fixedDelay = 15_000)
    void refresh() {
        long now = clock.millis();
        try {
            Long count = redis.opsForZSet().count(KEY, now - window.toMillis(), Double.POSITIVE_INFINITY);
            activeUsers = count == null ? Double.NaN : count;
        } catch (DataAccessException ex) {
            log.warn("Redis unavailable while refreshing active-user count -- reporting NaN", ex);
            activeUsers = Double.NaN;
        }
    }
}
