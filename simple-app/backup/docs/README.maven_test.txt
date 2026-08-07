
sre@ubuntu:~/simple_app/myapp$ mvn test
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------------------< com.simple.apps:myapp >------------------------
[INFO] Building myapp 0.0.1-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-resources-plugin:3.3.1:resources (default-resources) @ myapp ---
[INFO] Copying 1 resource from src/main/resources to target/classes
[INFO] Copying 0 resource from src/main/resources to target/classes
[INFO] 
[INFO] --- maven-compiler-plugin:3.13.0:compile (default-compile) @ myapp ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- maven-resources-plugin:3.3.1:testResources (default-testResources) @ myapp ---
[INFO] skip non existing resourceDirectory /home/sre/simple_app/myapp/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.13.0:testCompile (default-testCompile) @ myapp ---
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 1 source file with javac [forked debug parameters release 21] to target/test-classes
[INFO] 
[INFO] --- maven-surefire-plugin:3.5.2:test (default-test) @ myapp ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.simple.apps.myapp.MyappApplicationTests
01:09:47.281 [main] INFO org.springframework.test.context.support.AnnotationConfigContextLoaderUtils -- Could not detect default configuration classes for test class [com.simple.apps.myapp.MyappApplicationTests]: MyappApplicationTests does not declare any static, non-private, non-final, nested classes annotated with @Configuration.
01:09:47.583 [main] INFO org.springframework.boot.test.context.SpringBootTestContextBootstrapper -- Found @SpringBootConfiguration com.simple.apps.myapp.MyappApplication for test class com.simple.apps.myapp.MyappApplicationTests

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.2)

2025-02-07T01:09:48.629Z  INFO 32309 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : Starting MyappApplicationTests using Java 21.0.6 with PID 32309 (started by sre in /home/sre/simple_app/myapp)
2025-02-07T01:09:48.631Z  INFO 32309 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : No active profile set, falling back to 1 default profile: "default"
2025-02-07T01:09:50.377Z  INFO 32309 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Bootstrapping Spring Data JPA repositories in DEFAULT mode.
2025-02-07T01:09:50.440Z  INFO 32309 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 37 ms. Found 0 JPA repository interfaces.
2025-02-07T01:09:51.689Z  INFO 32309 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2025-02-07T01:09:53.165Z  INFO 32309 --- [myapp] [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection com.mysql.cj.jdbc.ConnectionImpl@13cc0b90
2025-02-07T01:09:53.171Z  INFO 32309 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
2025-02-07T01:09:53.384Z  INFO 32309 --- [myapp] [           main] o.hibernate.jpa.internal.util.LogHelper  : HHH000204: Processing PersistenceUnitInfo [name: default]
2025-02-07T01:09:53.654Z  INFO 32309 --- [myapp] [           main] org.hibernate.Version                    : HHH000412: Hibernate ORM core version 6.6.5.Final
2025-02-07T01:09:53.843Z  INFO 32309 --- [myapp] [           main] o.h.c.internal.RegionFactoryInitiator    : HHH000026: Second-level cache disabled
2025-02-07T01:09:54.961Z  INFO 32309 --- [myapp] [           main] o.s.o.j.p.SpringPersistenceUnitInfo      : No LoadTimeWeaver setup: ignoring JPA class transformer
2025-02-07T01:09:55.304Z  INFO 32309 --- [myapp] [           main] org.hibernate.orm.connections.pooling    : HHH10001005: Database info:
	Database JDBC URL [Connecting through datasource 'HikariDataSource (HikariPool-1)']
	Database driver: undefined/unknown
	Database version: 8.0.40
	Autocommit mode: undefined/unknown
	Isolation level: undefined/unknown
	Minimum pool size: undefined/unknown
	Maximum pool size: undefined/unknown
2025-02-07T01:09:56.925Z  INFO 32309 --- [myapp] [           main] o.h.e.t.j.p.i.JtaPlatformInitiator       : HHH000489: No JTA platform available (set 'hibernate.transaction.jta.platform' to enable JTA platform integration)
2025-02-07T01:09:56.943Z  INFO 32309 --- [myapp] [           main] j.LocalContainerEntityManagerFactoryBean : Initialized JPA EntityManagerFactory for persistence unit 'default'
2025-02-07T01:09:57.505Z  WARN 32309 --- [myapp] [           main] JpaBaseConfiguration$JpaWebConfiguration : spring.jpa.open-in-view is enabled by default. Therefore, database queries may be performed during view rendering. Explicitly configure spring.jpa.open-in-view to disable this warning
2025-02-07T01:09:59.186Z  INFO 32309 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : Started MyappApplicationTests in 11.187 seconds (process running for 13.964)
Mockito is currently self-attaching to enable the inline-mock-maker. This will no longer work in future releases of the JDK. Please add Mockito as an agent to your build what is described in Mockito's documentation: https://javadoc.io/doc/org.mockito/mockito-core/latest/org/mockito/Mockito.html#0.3
WARNING: A Java agent has been loaded dynamically (/home/sre/.m2/repository/net/bytebuddy/byte-buddy-agent/1.15.11/byte-buddy-agent-1.15.11.jar)
WARNING: If a serviceability tool is in use, please run with -XX:+EnableDynamicAgentLoading to hide this warning
WARNING: If a serviceability tool is not in use, please run with -Djdk.instrument.traceUsage for more information
WARNING: Dynamic loading of agents will be disallowed by default in a future release
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 14.31 s -- in com.simple.apps.myapp.MyappApplicationTests
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  23.853 s
[INFO] Finished at: 2025-02-07T01:10:01Z
[INFO] ------------------------------------------------------------------------
sre@ubuntu:~/simple_app/myapp$ 

