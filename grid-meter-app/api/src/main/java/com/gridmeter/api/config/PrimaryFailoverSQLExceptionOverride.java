package com.gridmeter.api.config;

import com.zaxxer.hikari.SQLExceptionOverride;
import java.sql.SQLException;

/**
 * Forces HikariCP to evict a pooled connection the moment a write against it fails with Postgres'
 * "25006" (read_only_sql_transaction) SQLState.
 *
 * <p>{@code SPRING_DATASOURCE_URL} now points at Traefik's {@code :55432} entrypoint
 * (docs/postgres-ha-scope.md's "Patroni deployment model" §4), which routes each new TCP
 * connection to whichever Patroni node is currently primary -- but a connection already
 * established before a failover keeps talking to that same node for its entire lifetime; Traefik
 * has no way to migrate an open TCP connection. Without this override, a pooled connection to a
 * node that Patroni has since demoted to a replica looks perfectly healthy to HikariCP's own
 * {@code Connection.isValid()} check (the TCP session and Postgres backend are both still alive
 * -- only writes are now rejected), so the pool would keep handing it out and every write through
 * it would keep failing with the same read-only error until that connection happened to be
 * recycled by {@code max-lifetime} rather than by anything failure-aware. Instructed via
 * {@code spring.datasource.hikari.exception-override-class-name}, and instantiated directly by
 * HikariCP via reflection -- deliberately has no Spring dependencies of its own.
 */
public class PrimaryFailoverSQLExceptionOverride implements SQLExceptionOverride {

    private static final String READ_ONLY_SQL_TRANSACTION = "25006";

    // No @Override annotation here: SQLExceptionOverride's own nested enum is also named
    // "Override", and its return type below resolves to that nested type rather than
    // java.lang.annotation.Override, so the annotation form doesn't compile.
    public SQLExceptionOverride.Override adjudicate(SQLException sqlException) {
        if (READ_ONLY_SQL_TRANSACTION.equals(sqlException.getSQLState())) {
            return SQLExceptionOverride.Override.MUST_EVICT;
        }
        return SQLExceptionOverride.Override.CONTINUE_EVICT;
    }
}
