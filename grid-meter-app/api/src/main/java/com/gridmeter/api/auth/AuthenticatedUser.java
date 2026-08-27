package com.gridmeter.api.auth;

import java.util.UUID;

/**
 * The security principal {@link JwtAuthenticationFilter} attaches to the request's Authentication
 * once a token is validated -- carries customerId alongside username so controllers can resolve
 * "which customer does this request belong to" via {@code @AuthenticationPrincipal} without a
 * per-request DB lookup (see docs/multi-tenancy-scope.md).
 */
public record AuthenticatedUser(String username, UUID customerId) {

    @Override
    public String toString() {
        return username;
    }
}
