
sre@ubuntu:~/java_projects/simple_app/myapp$ which java
/usr/bin/java
sre@ubuntu:~/java_projects/simple_app/myapp$ java -version
openjdk version "21.0.6" 2025-01-21
OpenJDK Runtime Environment (build 21.0.6+7-Ubuntu-124.04.1)
OpenJDK 64-Bit Server VM (build 21.0.6+7-Ubuntu-124.04.1, mixed mode, sharing)
sre@ubuntu:~/java_projects/simple_app/myapp$ echo $JAVA_HOME
/usr/lib/jvm/java-21-openjdk-amd64
sre@ubuntu:~/java_projects/simple_app/myapp$ which mvn
/usr/bin/mvn
sre@ubuntu:~/java_projects/simple_app/myapp$ mvn -version
Apache Maven 3.8.7
Maven home: /usr/share/maven
Java version: 21.0.6, vendor: Ubuntu, runtime: /usr/lib/jvm/java-21-openjdk-amd64
Default locale: en_US, platform encoding: UTF-8
OS name: "linux", version: "6.8.0-53-generic", arch: "amd64", family: "unix"
sre@ubuntu:~/java_projects/simple_app/myapp$ mvn test
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
[INFO] skip non existing resourceDirectory /home/sre/java_projects/simple_app/myapp/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.13.0:testCompile (default-testCompile) @ myapp ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- maven-surefire-plugin:3.5.2:test (default-test) @ myapp ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.simple.apps.myapp.MyappApplicationTests
18:46:25.199 [main] INFO org.springframework.test.context.support.AnnotationConfigContextLoaderUtils -- Could not detect default configuration classes for test class [com.simple.apps.myapp.MyappApplicationTests]: MyappApplicationTests does not declare any static, non-private, non-final, nested classes annotated with @Configuration.
18:46:25.355 [main] INFO org.springframework.boot.test.context.SpringBootTestContextBootstrapper -- Found @SpringBootConfiguration com.simple.apps.myapp.MyappApplication for test class com.simple.apps.myapp.MyappApplicationTests

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.2)

2025-02-12T18:46:25.855Z  INFO 29160 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : Starting MyappApplicationTests using Java 21.0.6 with PID 29160 (started by sre in /home/sre/java_projects/simple_app/myapp)
2025-02-12T18:46:25.857Z  INFO 29160 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : No active profile set, falling back to 1 default profile: "default"
2025-02-12T18:46:26.821Z  INFO 29160 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Bootstrapping Spring Data JPA repositories in DEFAULT mode.
2025-02-12T18:46:26.853Z  INFO 29160 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 17 ms. Found 0 JPA repository interfaces.
2025-02-12T18:46:27.352Z  INFO 29160 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2025-02-12T18:46:27.822Z  INFO 29160 --- [myapp] [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection com.mysql.cj.jdbc.ConnectionImpl@78d23d6a
2025-02-12T18:46:27.824Z  INFO 29160 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
2025-02-12T18:46:28.020Z  INFO 29160 --- [myapp] [           main] o.hibernate.jpa.internal.util.LogHelper  : HHH000204: Processing PersistenceUnitInfo [name: default]
2025-02-12T18:46:28.124Z  INFO 29160 --- [myapp] [           main] org.hibernate.Version                    : HHH000412: Hibernate ORM core version 6.6.5.Final
2025-02-12T18:46:28.196Z  INFO 29160 --- [myapp] [           main] o.h.c.internal.RegionFactoryInitiator    : HHH000026: Second-level cache disabled
2025-02-12T18:46:28.671Z  INFO 29160 --- [myapp] [           main] o.s.o.j.p.SpringPersistenceUnitInfo      : No LoadTimeWeaver setup: ignoring JPA class transformer
2025-02-12T18:46:28.814Z  INFO 29160 --- [myapp] [           main] org.hibernate.orm.connections.pooling    : HHH10001005: Database info:
	Database JDBC URL [Connecting through datasource 'HikariDataSource (HikariPool-1)']
	Database driver: undefined/unknown
	Database version: 8.0.40
	Autocommit mode: undefined/unknown
	Isolation level: undefined/unknown
	Minimum pool size: undefined/unknown
	Maximum pool size: undefined/unknown
2025-02-12T18:46:29.119Z  INFO 29160 --- [myapp] [           main] o.h.e.t.j.p.i.JtaPlatformInitiator       : HHH000489: No JTA platform available (set 'hibernate.transaction.jta.platform' to enable JTA platform integration)
2025-02-12T18:46:29.123Z  INFO 29160 --- [myapp] [           main] j.LocalContainerEntityManagerFactoryBean : Initialized JPA EntityManagerFactory for persistence unit 'default'
2025-02-12T18:46:29.359Z  WARN 29160 --- [myapp] [           main] JpaBaseConfiguration$JpaWebConfiguration : spring.jpa.open-in-view is enabled by default. Therefore, database queries may be performed during view rendering. Explicitly configure spring.jpa.open-in-view to disable this warning
2025-02-12T18:46:29.921Z  INFO 29160 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : Started MyappApplicationTests in 4.428 seconds (process running for 5.523)
Mockito is currently self-attaching to enable the inline-mock-maker. This will no longer work in future releases of the JDK. Please add Mockito as an agent to your build what is described in Mockito's documentation: https://javadoc.io/doc/org.mockito/mockito-core/latest/org/mockito/Mockito.html#0.3
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
WARNING: A Java agent has been loaded dynamically (/home/sre/.m2/repository/net/bytebuddy/byte-buddy-agent/1.15.11/byte-buddy-agent-1.15.11.jar)
WARNING: If a serviceability tool is in use, please run with -XX:+EnableDynamicAgentLoading to hide this warning
WARNING: If a serviceability tool is not in use, please run with -Djdk.instrument.traceUsage for more information
WARNING: Dynamic loading of agents will be disallowed by default in a future release
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 5.820 s -- in com.simple.apps.myapp.MyappApplicationTests
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  8.245 s
[INFO] Finished at: 2025-02-12T18:46:31Z
[INFO] ------------------------------------------------------------------------
sre@ubuntu:~/java_projects/simple_app/myapp$ 

sre@ubuntu:~/java_projects/simple_app$ mvn test
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
[INFO] skip non existing resourceDirectory /home/sre/java_projects/simple_app/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.13.0:testCompile (default-testCompile) @ myapp ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- maven-surefire-plugin:3.5.2:test (default-test) @ myapp ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.simple.apps.myapp.MyappApplicationTests
22:58:27.522 [main] INFO org.springframework.test.context.support.AnnotationConfigContextLoaderUtils -- Could not detect default configuration classes for test class [com.simple.apps.myapp.MyappApplicationTests]: MyappApplicationTests does not declare any static, non-private, non-final, nested classes annotated with @Configuration.
22:58:27.722 [main] INFO org.springframework.boot.test.context.SpringBootTestContextBootstrapper -- Found @SpringBootConfiguration com.simple.apps.myapp.MyappApplication for test class com.simple.apps.myapp.MyappApplicationTests

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.2)

2025-02-12T22:58:28.284Z  INFO 2392 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : Starting MyappApplicationTests using Java 21.0.6 with PID 2392 (started by sre in /home/sre/java_projects/simple_app)
2025-02-12T22:58:28.288Z  INFO 2392 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : No active profile set, falling back to 1 default profile: "default"
2025-02-12T22:58:29.321Z  INFO 2392 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Bootstrapping Spring Data JPA repositories in DEFAULT mode.
2025-02-12T22:58:29.343Z  INFO 2392 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 12 ms. Found 0 JPA repository interfaces.
2025-02-12T22:58:29.894Z  INFO 2392 --- [myapp] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port 0 (http)
2025-02-12T22:58:29.910Z  INFO 2392 --- [myapp] [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2025-02-12T22:58:29.910Z  INFO 2392 --- [myapp] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/10.1.34]
2025-02-12T22:58:29.961Z  INFO 2392 --- [myapp] [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2025-02-12T22:58:29.981Z  INFO 2392 --- [myapp] [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 1622 ms
2025-02-12T22:58:30.123Z  INFO 2392 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2025-02-12T22:58:30.685Z  INFO 2392 --- [myapp] [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection com.mysql.cj.jdbc.ConnectionImpl@4df7d9ee
2025-02-12T22:58:30.687Z  INFO 2392 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
2025-02-12T22:58:30.776Z  INFO 2392 --- [myapp] [           main] o.hibernate.jpa.internal.util.LogHelper  : HHH000204: Processing PersistenceUnitInfo [name: default]
2025-02-12T22:58:30.856Z  INFO 2392 --- [myapp] [           main] org.hibernate.Version                    : HHH000412: Hibernate ORM core version 6.6.5.Final
2025-02-12T22:58:30.921Z  INFO 2392 --- [myapp] [           main] o.h.c.internal.RegionFactoryInitiator    : HHH000026: Second-level cache disabled
2025-02-12T22:58:31.309Z  INFO 2392 --- [myapp] [           main] o.s.o.j.p.SpringPersistenceUnitInfo      : No LoadTimeWeaver setup: ignoring JPA class transformer
2025-02-12T22:58:31.469Z  INFO 2392 --- [myapp] [           main] org.hibernate.orm.connections.pooling    : HHH10001005: Database info:
	Database JDBC URL [Connecting through datasource 'HikariDataSource (HikariPool-1)']
	Database driver: undefined/unknown
	Database version: 8.0.40
	Autocommit mode: undefined/unknown
	Isolation level: undefined/unknown
	Minimum pool size: undefined/unknown
	Maximum pool size: undefined/unknown
2025-02-12T22:58:31.842Z  INFO 2392 --- [myapp] [           main] o.h.e.t.j.p.i.JtaPlatformInitiator       : HHH000489: No JTA platform available (set 'hibernate.transaction.jta.platform' to enable JTA platform integration)
2025-02-12T22:58:31.846Z  INFO 2392 --- [myapp] [           main] j.LocalContainerEntityManagerFactoryBean : Initialized JPA EntityManagerFactory for persistence unit 'default'
2025-02-12T22:58:31.917Z  WARN 2392 --- [myapp] [           main] JpaBaseConfiguration$JpaWebConfiguration : spring.jpa.open-in-view is enabled by default. Therefore, database queries may be performed during view rendering. Explicitly configure spring.jpa.open-in-view to disable this warning
2025-02-12T22:58:32.567Z  INFO 2392 --- [myapp] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 34733 (http) with context path '/'
2025-02-12T22:58:32.583Z  INFO 2392 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : Started MyappApplicationTests in 4.714 seconds (process running for 6.21)
Mockito is currently self-attaching to enable the inline-mock-maker. This will no longer work in future releases of the JDK. Please add Mockito as an agent to your build what is described in Mockito's documentation: https://javadoc.io/doc/org.mockito/mockito-core/latest/org/mockito/Mockito.html#0.3
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
WARNING: A Java agent has been loaded dynamically (/home/sre/.m2/repository/net/bytebuddy/byte-buddy-agent/1.15.11/byte-buddy-agent-1.15.11.jar)
WARNING: If a serviceability tool is in use, please run with -XX:+EnableDynamicAgentLoading to hide this warning
WARNING: If a serviceability tool is not in use, please run with -Djdk.instrument.traceUsage for more information
WARNING: Dynamic loading of agents will be disallowed by default in a future release
2025-02-12T22:58:33.497Z  INFO 2392 --- [myapp] [o-auto-1-exec-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring DispatcherServlet 'dispatcherServlet'
2025-02-12T22:58:33.497Z  INFO 2392 --- [myapp] [o-auto-1-exec-1] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
2025-02-12T22:58:33.500Z  INFO 2392 --- [myapp] [o-auto-1-exec-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 1 ms
[INFO] Tests run: 7, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 6.416 s -- in com.simple.apps.myapp.MyappApplicationTests
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 7, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  9.615 s
[INFO] Finished at: 2025-02-12T22:58:34Z
[INFO] ------------------------------------------------------------------------

sre@ubuntu:~/java_projects/simple_app$ mvn test
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
[INFO] skip non existing resourceDirectory /home/sre/java_projects/simple_app/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.13.0:testCompile (default-testCompile) @ myapp ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- maven-surefire-plugin:3.5.2:test (default-test) @ myapp ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.simple.apps.myapp.MyappApplicationTests
23:06:31.434 [main] INFO org.springframework.test.context.support.AnnotationConfigContextLoaderUtils -- Could not detect default configuration classes for test class [com.simple.apps.myapp.MyappApplicationTests]: MyappApplicationTests does not declare any static, non-private, non-final, nested classes annotated with @Configuration.
23:06:31.605 [main] INFO org.springframework.boot.test.context.SpringBootTestContextBootstrapper -- Found @SpringBootConfiguration com.simple.apps.myapp.MyappApplication for test class com.simple.apps.myapp.MyappApplicationTests

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.2)

2025-02-12T23:06:32.261Z  INFO 2737 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : Starting MyappApplicationTests using Java 21.0.6 with PID 2737 (started by sre in /home/sre/java_projects/simple_app)
2025-02-12T23:06:32.262Z  INFO 2737 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : No active profile set, falling back to 1 default profile: "default"
2025-02-12T23:06:33.293Z  INFO 2737 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Bootstrapping Spring Data JPA repositories in DEFAULT mode.
2025-02-12T23:06:33.317Z  INFO 2737 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 12 ms. Found 0 JPA repository interfaces.
2025-02-12T23:06:33.953Z  INFO 2737 --- [myapp] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port 0 (http)
2025-02-12T23:06:33.969Z  INFO 2737 --- [myapp] [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2025-02-12T23:06:33.969Z  INFO 2737 --- [myapp] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/10.1.34]
2025-02-12T23:06:34.034Z  INFO 2737 --- [myapp] [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2025-02-12T23:06:34.035Z  INFO 2737 --- [myapp] [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 1755 ms
2025-02-12T23:06:34.192Z  INFO 2737 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2025-02-12T23:06:34.766Z  INFO 2737 --- [myapp] [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection com.mysql.cj.jdbc.ConnectionImpl@3a38e4dc
2025-02-12T23:06:34.768Z  INFO 2737 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
2025-02-12T23:06:34.834Z  INFO 2737 --- [myapp] [           main] o.hibernate.jpa.internal.util.LogHelper  : HHH000204: Processing PersistenceUnitInfo [name: default]
2025-02-12T23:06:34.920Z  INFO 2737 --- [myapp] [           main] org.hibernate.Version                    : HHH000412: Hibernate ORM core version 6.6.5.Final
2025-02-12T23:06:34.958Z  INFO 2737 --- [myapp] [           main] o.h.c.internal.RegionFactoryInitiator    : HHH000026: Second-level cache disabled
2025-02-12T23:06:35.297Z  INFO 2737 --- [myapp] [           main] o.s.o.j.p.SpringPersistenceUnitInfo      : No LoadTimeWeaver setup: ignoring JPA class transformer
2025-02-12T23:06:35.424Z  INFO 2737 --- [myapp] [           main] org.hibernate.orm.connections.pooling    : HHH10001005: Database info:
	Database JDBC URL [Connecting through datasource 'HikariDataSource (HikariPool-1)']
	Database driver: undefined/unknown
	Database version: 8.0.40
	Autocommit mode: undefined/unknown
	Isolation level: undefined/unknown
	Minimum pool size: undefined/unknown
	Maximum pool size: undefined/unknown
2025-02-12T23:06:35.778Z  INFO 2737 --- [myapp] [           main] o.h.e.t.j.p.i.JtaPlatformInitiator       : HHH000489: No JTA platform available (set 'hibernate.transaction.jta.platform' to enable JTA platform integration)
2025-02-12T23:06:35.784Z  INFO 2737 --- [myapp] [           main] j.LocalContainerEntityManagerFactoryBean : Initialized JPA EntityManagerFactory for persistence unit 'default'
2025-02-12T23:06:35.844Z  WARN 2737 --- [myapp] [           main] JpaBaseConfiguration$JpaWebConfiguration : spring.jpa.open-in-view is enabled by default. Therefore, database queries may be performed during view rendering. Explicitly configure spring.jpa.open-in-view to disable this warning
2025-02-12T23:06:36.529Z  INFO 2737 --- [myapp] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 42035 (http) with context path '/'
2025-02-12T23:06:36.546Z  INFO 2737 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : Started MyappApplicationTests in 4.725 seconds (process running for 6.034)
Mockito is currently self-attaching to enable the inline-mock-maker. This will no longer work in future releases of the JDK. Please add Mockito as an agent to your build what is described in Mockito's documentation: https://javadoc.io/doc/org.mockito/mockito-core/latest/org/mockito/Mockito.html#0.3
WARNING: A Java agent has been loaded dynamically (/home/sre/.m2/repository/net/bytebuddy/byte-buddy-agent/1.15.11/byte-buddy-agent-1.15.11.jar)
WARNING: If a serviceability tool is in use, please run with -XX:+EnableDynamicAgentLoading to hide this warning
WARNING: If a serviceability tool is not in use, please run with -Djdk.instrument.traceUsage for more information
WARNING: Dynamic loading of agents will be disallowed by default in a future release
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
2025-02-12T23:06:37.441Z  INFO 2737 --- [myapp] [o-auto-1-exec-2] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring DispatcherServlet 'dispatcherServlet'
2025-02-12T23:06:37.441Z  INFO 2737 --- [myapp] [o-auto-1-exec-2] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
2025-02-12T23:06:37.443Z  INFO 2737 --- [myapp] [o-auto-1-exec-2] o.s.web.servlet.DispatcherServlet        : Completed initialization in 1 ms
[INFO] Tests run: 7, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 6.529 s -- in com.simple.apps.myapp.MyappApplicationTests
2025-02-12T23:06:37.809Z  INFO 2737 --- [myapp] [ionShutdownHook] o.s.b.w.e.tomcat.GracefulShutdown        : Commencing graceful shutdown. Waiting for active requests to complete
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 7, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  9.209 s
[INFO] Finished at: 2025-02-12T23:06:38Z
[INFO] ------------------------------------------------------------------------
sre@ubuntu:~/java_projects/simple_app$ 

sre@ubuntu:~/java_projects/simple_app$ mvn test -Dtest=MyappApplicationTests
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
[INFO] skip non existing resourceDirectory /home/sre/java_projects/simple_app/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.13.0:testCompile (default-testCompile) @ myapp ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- maven-surefire-plugin:3.5.2:test (default-test) @ myapp ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.simple.apps.myapp.MyappApplicationTests
23:08:36.888 [main] INFO org.springframework.test.context.support.AnnotationConfigContextLoaderUtils -- Could not detect default configuration classes for test class [com.simple.apps.myapp.MyappApplicationTests]: MyappApplicationTests does not declare any static, non-private, non-final, nested classes annotated with @Configuration.
23:08:37.052 [main] INFO org.springframework.boot.test.context.SpringBootTestContextBootstrapper -- Found @SpringBootConfiguration com.simple.apps.myapp.MyappApplication for test class com.simple.apps.myapp.MyappApplicationTests

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.2)

2025-02-12T23:08:37.575Z  INFO 2872 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : Starting MyappApplicationTests using Java 21.0.6 with PID 2872 (started by sre in /home/sre/java_projects/simple_app)
2025-02-12T23:08:37.588Z  INFO 2872 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : No active profile set, falling back to 1 default profile: "default"
2025-02-12T23:08:38.704Z  INFO 2872 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Bootstrapping Spring Data JPA repositories in DEFAULT mode.
2025-02-12T23:08:38.729Z  INFO 2872 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 14 ms. Found 0 JPA repository interfaces.
2025-02-12T23:08:39.339Z  INFO 2872 --- [myapp] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port 0 (http)
2025-02-12T23:08:39.356Z  INFO 2872 --- [myapp] [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2025-02-12T23:08:39.357Z  INFO 2872 --- [myapp] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/10.1.34]
2025-02-12T23:08:39.481Z  INFO 2872 --- [myapp] [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2025-02-12T23:08:39.483Z  INFO 2872 --- [myapp] [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 1855 ms
2025-02-12T23:08:39.649Z  INFO 2872 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2025-02-12T23:08:40.199Z  INFO 2872 --- [myapp] [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection com.mysql.cj.jdbc.ConnectionImpl@4df7d9ee
2025-02-12T23:08:40.208Z  INFO 2872 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
2025-02-12T23:08:40.288Z  INFO 2872 --- [myapp] [           main] o.hibernate.jpa.internal.util.LogHelper  : HHH000204: Processing PersistenceUnitInfo [name: default]
2025-02-12T23:08:40.361Z  INFO 2872 --- [myapp] [           main] org.hibernate.Version                    : HHH000412: Hibernate ORM core version 6.6.5.Final
2025-02-12T23:08:40.404Z  INFO 2872 --- [myapp] [           main] o.h.c.internal.RegionFactoryInitiator    : HHH000026: Second-level cache disabled
2025-02-12T23:08:40.744Z  INFO 2872 --- [myapp] [           main] o.s.o.j.p.SpringPersistenceUnitInfo      : No LoadTimeWeaver setup: ignoring JPA class transformer
2025-02-12T23:08:40.856Z  INFO 2872 --- [myapp] [           main] org.hibernate.orm.connections.pooling    : HHH10001005: Database info:
	Database JDBC URL [Connecting through datasource 'HikariDataSource (HikariPool-1)']
	Database driver: undefined/unknown
	Database version: 8.0.40
	Autocommit mode: undefined/unknown
	Isolation level: undefined/unknown
	Minimum pool size: undefined/unknown
	Maximum pool size: undefined/unknown
2025-02-12T23:08:41.213Z  INFO 2872 --- [myapp] [           main] o.h.e.t.j.p.i.JtaPlatformInitiator       : HHH000489: No JTA platform available (set 'hibernate.transaction.jta.platform' to enable JTA platform integration)
2025-02-12T23:08:41.218Z  INFO 2872 --- [myapp] [           main] j.LocalContainerEntityManagerFactoryBean : Initialized JPA EntityManagerFactory for persistence unit 'default'
2025-02-12T23:08:41.304Z  WARN 2872 --- [myapp] [           main] JpaBaseConfiguration$JpaWebConfiguration : spring.jpa.open-in-view is enabled by default. Therefore, database queries may be performed during view rendering. Explicitly configure spring.jpa.open-in-view to disable this warning
2025-02-12T23:08:41.984Z  INFO 2872 --- [myapp] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 35585 (http) with context path '/'
2025-02-12T23:08:42.012Z  INFO 2872 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : Started MyappApplicationTests in 4.818 seconds (process running for 6.065)
Mockito is currently self-attaching to enable the inline-mock-maker. This will no longer work in future releases of the JDK. Please add Mockito as an agent to your build what is described in Mockito's documentation: https://javadoc.io/doc/org.mockito/mockito-core/latest/org/mockito/Mockito.html#0.3
WARNING: A Java agent has been loaded dynamically (/home/sre/.m2/repository/net/bytebuddy/byte-buddy-agent/1.15.11/byte-buddy-agent-1.15.11.jar)
WARNING: If a serviceability tool is in use, please run with -XX:+EnableDynamicAgentLoading to hide this warning
WARNING: If a serviceability tool is not in use, please run with -Djdk.instrument.traceUsage for more information
WARNING: Dynamic loading of agents will be disallowed by default in a future release
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
2025-02-12T23:08:43.043Z  INFO 2872 --- [myapp] [o-auto-1-exec-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring DispatcherServlet 'dispatcherServlet'
2025-02-12T23:08:43.044Z  INFO 2872 --- [myapp] [o-auto-1-exec-1] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
2025-02-12T23:08:43.047Z  INFO 2872 --- [myapp] [o-auto-1-exec-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 1 ms
[INFO] Tests run: 7, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 6.670 s -- in com.simple.apps.myapp.MyappApplicationTests
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 7, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  9.432 s
[INFO] Finished at: 2025-02-12T23:08:43Z
[INFO] ------------------------------------------------------------------------
sre@ubuntu:~/java_projects/simple_app$ 

sre@ubuntu:~/java_projects/simple_app$ xmllint --format target/surefire-reports/TEST-com.simple.apps.myapp.MyappApplicationTests.xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuite xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://maven.apache.org/surefire/maven-surefire-plugin/xsd/surefire-test-report.xsd" version="3.0.2" name="com.simple.apps.myapp.MyappApplicationTests" time="6.439" tests="7" errors="0" skipped="0" failures="0">
  <properties>
    <property name="java.specification.version" value="21"/>
    <property name="sun.jnu.encoding" value="UTF-8"/>
    <property name="java.class.path" value="/home/sre/java_projects/simple_app/target/test-classes:/home/sre/java_projects/simple_app/target/classes:/home/sre/.m2/repository/org/springframework/boot/spring-boot-starter-web/3.4.2/spring-boot-starter-web-3.4.2.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-starter/3.4.2/spring-boot-starter-3.4.2.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot/3.4.2/spring-boot-3.4.2.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-autoconfigure/3.4.2/spring-boot-autoconfigure-3.4.2.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-starter-logging/3.4.2/spring-boot-starter-logging-3.4.2.jar:/home/sre/.m2/repository/ch/qos/logback/logback-classic/1.5.16/logback-classic-1.5.16.jar:/home/sre/.m2/repository/ch/qos/logback/logback-core/1.5.16/logback-core-1.5.16.jar:/home/sre/.m2/repository/org/apache/logging/log4j/log4j-to-slf4j/2.24.3/log4j-to-slf4j-2.24.3.jar:/home/sre/.m2/repository/org/apache/logging/log4j/log4j-api/2.24.3/log4j-api-2.24.3.jar:/home/sre/.m2/repository/org/slf4j/jul-to-slf4j/2.0.16/jul-to-slf4j-2.0.16.jar:/home/sre/.m2/repository/jakarta/annotation/jakarta.annotation-api/2.1.1/jakarta.annotation-api-2.1.1.jar:/home/sre/.m2/repository/org/yaml/snakeyaml/2.3/snakeyaml-2.3.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-starter-json/3.4.2/spring-boot-starter-json-3.4.2.jar:/home/sre/.m2/repository/com/fasterxml/jackson/core/jackson-databind/2.18.2/jackson-databind-2.18.2.jar:/home/sre/.m2/repository/com/fasterxml/jackson/core/jackson-annotations/2.18.2/jackson-annotations-2.18.2.jar:/home/sre/.m2/repository/com/fasterxml/jackson/core/jackson-core/2.18.2/jackson-core-2.18.2.jar:/home/sre/.m2/repository/com/fasterxml/jackson/datatype/jackson-datatype-jdk8/2.18.2/jackson-datatype-jdk8-2.18.2.jar:/home/sre/.m2/repository/com/fasterxml/jackson/datatype/jackson-datatype-jsr310/2.18.2/jackson-datatype-jsr310-2.18.2.jar:/home/sre/.m2/repository/com/fasterxml/jackson/module/jackson-module-parameter-names/2.18.2/jackson-module-parameter-names-2.18.2.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-starter-tomcat/3.4.2/spring-boot-starter-tomcat-3.4.2.jar:/home/sre/.m2/repository/org/apache/tomcat/embed/tomcat-embed-core/10.1.34/tomcat-embed-core-10.1.34.jar:/home/sre/.m2/repository/org/apache/tomcat/embed/tomcat-embed-websocket/10.1.34/tomcat-embed-websocket-10.1.34.jar:/home/sre/.m2/repository/org/springframework/spring-web/6.2.2/spring-web-6.2.2.jar:/home/sre/.m2/repository/org/springframework/spring-beans/6.2.2/spring-beans-6.2.2.jar:/home/sre/.m2/repository/io/micrometer/micrometer-observation/1.14.3/micrometer-observation-1.14.3.jar:/home/sre/.m2/repository/io/micrometer/micrometer-commons/1.14.3/micrometer-commons-1.14.3.jar:/home/sre/.m2/repository/org/springframework/spring-webmvc/6.2.2/spring-webmvc-6.2.2.jar:/home/sre/.m2/repository/org/springframework/spring-aop/6.2.2/spring-aop-6.2.2.jar:/home/sre/.m2/repository/org/springframework/spring-context/6.2.2/spring-context-6.2.2.jar:/home/sre/.m2/repository/org/springframework/spring-expression/6.2.2/spring-expression-6.2.2.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-starter-validation/3.4.2/spring-boot-starter-validation-3.4.2.jar:/home/sre/.m2/repository/org/apache/tomcat/embed/tomcat-embed-el/10.1.34/tomcat-embed-el-10.1.34.jar:/home/sre/.m2/repository/org/hibernate/validator/hibernate-validator/8.0.2.Final/hibernate-validator-8.0.2.Final.jar:/home/sre/.m2/repository/jakarta/validation/jakarta.validation-api/3.0.2/jakarta.validation-api-3.0.2.jar:/home/sre/.m2/repository/org/jboss/logging/jboss-logging/3.6.1.Final/jboss-logging-3.6.1.Final.jar:/home/sre/.m2/repository/com/fasterxml/classmate/1.7.0/classmate-1.7.0.jar:/home/sre/.m2/repository/org/projectlombok/lombok/1.18.36/lombok-1.18.36.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-starter-data-jpa/3.4.2/spring-boot-starter-data-jpa-3.4.2.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-starter-jdbc/3.4.2/spring-boot-starter-jdbc-3.4.2.jar:/home/sre/.m2/repository/com/zaxxer/HikariCP/5.1.0/HikariCP-5.1.0.jar:/home/sre/.m2/repository/org/springframework/spring-jdbc/6.2.2/spring-jdbc-6.2.2.jar:/home/sre/.m2/repository/org/hibernate/orm/hibernate-core/6.6.5.Final/hibernate-core-6.6.5.Final.jar:/home/sre/.m2/repository/jakarta/persistence/jakarta.persistence-api/3.1.0/jakarta.persistence-api-3.1.0.jar:/home/sre/.m2/repository/jakarta/transaction/jakarta.transaction-api/2.0.1/jakarta.transaction-api-2.0.1.jar:/home/sre/.m2/repository/org/hibernate/common/hibernate-commons-annotations/7.0.3.Final/hibernate-commons-annotations-7.0.3.Final.jar:/home/sre/.m2/repository/io/smallrye/jandex/3.2.0/jandex-3.2.0.jar:/home/sre/.m2/repository/net/bytebuddy/byte-buddy/1.15.11/byte-buddy-1.15.11.jar:/home/sre/.m2/repository/org/glassfish/jaxb/jaxb-runtime/4.0.5/jaxb-runtime-4.0.5.jar:/home/sre/.m2/repository/org/glassfish/jaxb/jaxb-core/4.0.5/jaxb-core-4.0.5.jar:/home/sre/.m2/repository/org/eclipse/angus/angus-activation/2.0.2/angus-activation-2.0.2.jar:/home/sre/.m2/repository/org/glassfish/jaxb/txw2/4.0.5/txw2-4.0.5.jar:/home/sre/.m2/repository/com/sun/istack/istack-commons-runtime/4.1.2/istack-commons-runtime-4.1.2.jar:/home/sre/.m2/repository/jakarta/inject/jakarta.inject-api/2.0.1/jakarta.inject-api-2.0.1.jar:/home/sre/.m2/repository/org/antlr/antlr4-runtime/4.13.0/antlr4-runtime-4.13.0.jar:/home/sre/.m2/repository/org/springframework/data/spring-data-jpa/3.4.2/spring-data-jpa-3.4.2.jar:/home/sre/.m2/repository/org/springframework/data/spring-data-commons/3.4.2/spring-data-commons-3.4.2.jar:/home/sre/.m2/repository/org/springframework/spring-orm/6.2.2/spring-orm-6.2.2.jar:/home/sre/.m2/repository/org/springframework/spring-tx/6.2.2/spring-tx-6.2.2.jar:/home/sre/.m2/repository/org/slf4j/slf4j-api/2.0.16/slf4j-api-2.0.16.jar:/home/sre/.m2/repository/org/springframework/spring-aspects/6.2.2/spring-aspects-6.2.2.jar:/home/sre/.m2/repository/org/aspectj/aspectjweaver/1.9.22.1/aspectjweaver-1.9.22.1.jar:/home/sre/.m2/repository/com/mysql/mysql-connector-j/9.1.0/mysql-connector-j-9.1.0.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-starter-test/3.4.2/spring-boot-starter-test-3.4.2.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-test/3.4.2/spring-boot-test-3.4.2.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-test-autoconfigure/3.4.2/spring-boot-test-autoconfigure-3.4.2.jar:/home/sre/.m2/repository/com/jayway/jsonpath/json-path/2.9.0/json-path-2.9.0.jar:/home/sre/.m2/repository/jakarta/xml/bind/jakarta.xml.bind-api/4.0.2/jakarta.xml.bind-api-4.0.2.jar:/home/sre/.m2/repository/jakarta/activation/jakarta.activation-api/2.1.3/jakarta.activation-api-2.1.3.jar:/home/sre/.m2/repository/net/minidev/json-smart/2.5.1/json-smart-2.5.1.jar:/home/sre/.m2/repository/net/minidev/accessors-smart/2.5.1/accessors-smart-2.5.1.jar:/home/sre/.m2/repository/org/ow2/asm/asm/9.6/asm-9.6.jar:/home/sre/.m2/repository/org/assertj/assertj-core/3.26.3/assertj-core-3.26.3.jar:/home/sre/.m2/repository/org/awaitility/awaitility/4.2.2/awaitility-4.2.2.jar:/home/sre/.m2/repository/org/hamcrest/hamcrest/2.2/hamcrest-2.2.jar:/home/sre/.m2/repository/org/junit/jupiter/junit-jupiter/5.11.4/junit-jupiter-5.11.4.jar:/home/sre/.m2/repository/org/junit/jupiter/junit-jupiter-api/5.11.4/junit-jupiter-api-5.11.4.jar:/home/sre/.m2/repository/org/opentest4j/opentest4j/1.3.0/opentest4j-1.3.0.jar:/home/sre/.m2/repository/org/junit/platform/junit-platform-commons/1.11.4/junit-platform-commons-1.11.4.jar:/home/sre/.m2/repository/org/apiguardian/apiguardian-api/1.1.2/apiguardian-api-1.1.2.jar:/home/sre/.m2/repository/org/junit/jupiter/junit-jupiter-params/5.11.4/junit-jupiter-params-5.11.4.jar:/home/sre/.m2/repository/org/junit/jupiter/junit-jupiter-engine/5.11.4/junit-jupiter-engine-5.11.4.jar:/home/sre/.m2/repository/org/junit/platform/junit-platform-engine/1.11.4/junit-platform-engine-1.11.4.jar:/home/sre/.m2/repository/org/mockito/mockito-core/5.14.2/mockito-core-5.14.2.jar:/home/sre/.m2/repository/net/bytebuddy/byte-buddy-agent/1.15.11/byte-buddy-agent-1.15.11.jar:/home/sre/.m2/repository/org/objenesis/objenesis/3.3/objenesis-3.3.jar:/home/sre/.m2/repository/org/mockito/mockito-junit-jupiter/5.14.2/mockito-junit-jupiter-5.14.2.jar:/home/sre/.m2/repository/org/skyscreamer/jsonassert/1.5.3/jsonassert-1.5.3.jar:/home/sre/.m2/repository/com/vaadin/external/google/android-json/0.0.20131108.vaadin1/android-json-0.0.20131108.vaadin1.jar:/home/sre/.m2/repository/org/springframework/spring-core/6.2.2/spring-core-6.2.2.jar:/home/sre/.m2/repository/org/springframework/spring-jcl/6.2.2/spring-jcl-6.2.2.jar:/home/sre/.m2/repository/org/springframework/spring-test/6.2.2/spring-test-6.2.2.jar:/home/sre/.m2/repository/org/xmlunit/xmlunit-core/2.10.0/xmlunit-core-2.10.0.jar:"/>
    <property name="java.vm.vendor" value="Ubuntu"/>
    <property name="sun.arch.data.model" value="64"/>
    <property name="catalina.useNaming" value="false"/>
    <property name="java.vendor.url" value="https://ubuntu.com/"/>
    <property name="user.timezone" value="Etc/UTC"/>
    <property name="org.jboss.logging.provider" value="slf4j"/>
    <property name="os.name" value="Linux"/>
    <property name="java.vm.specification.version" value="21"/>
    <property name="APPLICATION_NAME" value="myapp"/>
    <property name="sun.java.launcher" value="SUN_STANDARD"/>
    <property name="sun.boot.library.path" value="/usr/lib/jvm/java-21-openjdk-amd64/lib"/>
    <property name="sun.java.command" value="/home/sre/java_projects/simple_app/target/surefire/surefirebooter-20250212231336354_3.jar /home/sre/java_projects/simple_app/target/surefire 2025-02-12T23-13-36_256-jvmRun1 surefire-20250212231336354_1tmp surefire_0-20250212231336354_2tmp"/>
    <property name="jdk.debug" value="release"/>
    <property name="surefire.test.class.path" value="/home/sre/java_projects/simple_app/target/test-classes:/home/sre/java_projects/simple_app/target/classes:/home/sre/.m2/repository/org/springframework/boot/spring-boot-starter-web/3.4.2/spring-boot-starter-web-3.4.2.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-starter/3.4.2/spring-boot-starter-3.4.2.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot/3.4.2/spring-boot-3.4.2.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-autoconfigure/3.4.2/spring-boot-autoconfigure-3.4.2.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-starter-logging/3.4.2/spring-boot-starter-logging-3.4.2.jar:/home/sre/.m2/repository/ch/qos/logback/logback-classic/1.5.16/logback-classic-1.5.16.jar:/home/sre/.m2/repository/ch/qos/logback/logback-core/1.5.16/logback-core-1.5.16.jar:/home/sre/.m2/repository/org/apache/logging/log4j/log4j-to-slf4j/2.24.3/log4j-to-slf4j-2.24.3.jar:/home/sre/.m2/repository/org/apache/logging/log4j/log4j-api/2.24.3/log4j-api-2.24.3.jar:/home/sre/.m2/repository/org/slf4j/jul-to-slf4j/2.0.16/jul-to-slf4j-2.0.16.jar:/home/sre/.m2/repository/jakarta/annotation/jakarta.annotation-api/2.1.1/jakarta.annotation-api-2.1.1.jar:/home/sre/.m2/repository/org/yaml/snakeyaml/2.3/snakeyaml-2.3.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-starter-json/3.4.2/spring-boot-starter-json-3.4.2.jar:/home/sre/.m2/repository/com/fasterxml/jackson/core/jackson-databind/2.18.2/jackson-databind-2.18.2.jar:/home/sre/.m2/repository/com/fasterxml/jackson/core/jackson-annotations/2.18.2/jackson-annotations-2.18.2.jar:/home/sre/.m2/repository/com/fasterxml/jackson/core/jackson-core/2.18.2/jackson-core-2.18.2.jar:/home/sre/.m2/repository/com/fasterxml/jackson/datatype/jackson-datatype-jdk8/2.18.2/jackson-datatype-jdk8-2.18.2.jar:/home/sre/.m2/repository/com/fasterxml/jackson/datatype/jackson-datatype-jsr310/2.18.2/jackson-datatype-jsr310-2.18.2.jar:/home/sre/.m2/repository/com/fasterxml/jackson/module/jackson-module-parameter-names/2.18.2/jackson-module-parameter-names-2.18.2.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-starter-tomcat/3.4.2/spring-boot-starter-tomcat-3.4.2.jar:/home/sre/.m2/repository/org/apache/tomcat/embed/tomcat-embed-core/10.1.34/tomcat-embed-core-10.1.34.jar:/home/sre/.m2/repository/org/apache/tomcat/embed/tomcat-embed-websocket/10.1.34/tomcat-embed-websocket-10.1.34.jar:/home/sre/.m2/repository/org/springframework/spring-web/6.2.2/spring-web-6.2.2.jar:/home/sre/.m2/repository/org/springframework/spring-beans/6.2.2/spring-beans-6.2.2.jar:/home/sre/.m2/repository/io/micrometer/micrometer-observation/1.14.3/micrometer-observation-1.14.3.jar:/home/sre/.m2/repository/io/micrometer/micrometer-commons/1.14.3/micrometer-commons-1.14.3.jar:/home/sre/.m2/repository/org/springframework/spring-webmvc/6.2.2/spring-webmvc-6.2.2.jar:/home/sre/.m2/repository/org/springframework/spring-aop/6.2.2/spring-aop-6.2.2.jar:/home/sre/.m2/repository/org/springframework/spring-context/6.2.2/spring-context-6.2.2.jar:/home/sre/.m2/repository/org/springframework/spring-expression/6.2.2/spring-expression-6.2.2.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-starter-validation/3.4.2/spring-boot-starter-validation-3.4.2.jar:/home/sre/.m2/repository/org/apache/tomcat/embed/tomcat-embed-el/10.1.34/tomcat-embed-el-10.1.34.jar:/home/sre/.m2/repository/org/hibernate/validator/hibernate-validator/8.0.2.Final/hibernate-validator-8.0.2.Final.jar:/home/sre/.m2/repository/jakarta/validation/jakarta.validation-api/3.0.2/jakarta.validation-api-3.0.2.jar:/home/sre/.m2/repository/org/jboss/logging/jboss-logging/3.6.1.Final/jboss-logging-3.6.1.Final.jar:/home/sre/.m2/repository/com/fasterxml/classmate/1.7.0/classmate-1.7.0.jar:/home/sre/.m2/repository/org/projectlombok/lombok/1.18.36/lombok-1.18.36.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-starter-data-jpa/3.4.2/spring-boot-starter-data-jpa-3.4.2.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-starter-jdbc/3.4.2/spring-boot-starter-jdbc-3.4.2.jar:/home/sre/.m2/repository/com/zaxxer/HikariCP/5.1.0/HikariCP-5.1.0.jar:/home/sre/.m2/repository/org/springframework/spring-jdbc/6.2.2/spring-jdbc-6.2.2.jar:/home/sre/.m2/repository/org/hibernate/orm/hibernate-core/6.6.5.Final/hibernate-core-6.6.5.Final.jar:/home/sre/.m2/repository/jakarta/persistence/jakarta.persistence-api/3.1.0/jakarta.persistence-api-3.1.0.jar:/home/sre/.m2/repository/jakarta/transaction/jakarta.transaction-api/2.0.1/jakarta.transaction-api-2.0.1.jar:/home/sre/.m2/repository/org/hibernate/common/hibernate-commons-annotations/7.0.3.Final/hibernate-commons-annotations-7.0.3.Final.jar:/home/sre/.m2/repository/io/smallrye/jandex/3.2.0/jandex-3.2.0.jar:/home/sre/.m2/repository/net/bytebuddy/byte-buddy/1.15.11/byte-buddy-1.15.11.jar:/home/sre/.m2/repository/org/glassfish/jaxb/jaxb-runtime/4.0.5/jaxb-runtime-4.0.5.jar:/home/sre/.m2/repository/org/glassfish/jaxb/jaxb-core/4.0.5/jaxb-core-4.0.5.jar:/home/sre/.m2/repository/org/eclipse/angus/angus-activation/2.0.2/angus-activation-2.0.2.jar:/home/sre/.m2/repository/org/glassfish/jaxb/txw2/4.0.5/txw2-4.0.5.jar:/home/sre/.m2/repository/com/sun/istack/istack-commons-runtime/4.1.2/istack-commons-runtime-4.1.2.jar:/home/sre/.m2/repository/jakarta/inject/jakarta.inject-api/2.0.1/jakarta.inject-api-2.0.1.jar:/home/sre/.m2/repository/org/antlr/antlr4-runtime/4.13.0/antlr4-runtime-4.13.0.jar:/home/sre/.m2/repository/org/springframework/data/spring-data-jpa/3.4.2/spring-data-jpa-3.4.2.jar:/home/sre/.m2/repository/org/springframework/data/spring-data-commons/3.4.2/spring-data-commons-3.4.2.jar:/home/sre/.m2/repository/org/springframework/spring-orm/6.2.2/spring-orm-6.2.2.jar:/home/sre/.m2/repository/org/springframework/spring-tx/6.2.2/spring-tx-6.2.2.jar:/home/sre/.m2/repository/org/slf4j/slf4j-api/2.0.16/slf4j-api-2.0.16.jar:/home/sre/.m2/repository/org/springframework/spring-aspects/6.2.2/spring-aspects-6.2.2.jar:/home/sre/.m2/repository/org/aspectj/aspectjweaver/1.9.22.1/aspectjweaver-1.9.22.1.jar:/home/sre/.m2/repository/com/mysql/mysql-connector-j/9.1.0/mysql-connector-j-9.1.0.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-starter-test/3.4.2/spring-boot-starter-test-3.4.2.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-test/3.4.2/spring-boot-test-3.4.2.jar:/home/sre/.m2/repository/org/springframework/boot/spring-boot-test-autoconfigure/3.4.2/spring-boot-test-autoconfigure-3.4.2.jar:/home/sre/.m2/repository/com/jayway/jsonpath/json-path/2.9.0/json-path-2.9.0.jar:/home/sre/.m2/repository/jakarta/xml/bind/jakarta.xml.bind-api/4.0.2/jakarta.xml.bind-api-4.0.2.jar:/home/sre/.m2/repository/jakarta/activation/jakarta.activation-api/2.1.3/jakarta.activation-api-2.1.3.jar:/home/sre/.m2/repository/net/minidev/json-smart/2.5.1/json-smart-2.5.1.jar:/home/sre/.m2/repository/net/minidev/accessors-smart/2.5.1/accessors-smart-2.5.1.jar:/home/sre/.m2/repository/org/ow2/asm/asm/9.6/asm-9.6.jar:/home/sre/.m2/repository/org/assertj/assertj-core/3.26.3/assertj-core-3.26.3.jar:/home/sre/.m2/repository/org/awaitility/awaitility/4.2.2/awaitility-4.2.2.jar:/home/sre/.m2/repository/org/hamcrest/hamcrest/2.2/hamcrest-2.2.jar:/home/sre/.m2/repository/org/junit/jupiter/junit-jupiter/5.11.4/junit-jupiter-5.11.4.jar:/home/sre/.m2/repository/org/junit/jupiter/junit-jupiter-api/5.11.4/junit-jupiter-api-5.11.4.jar:/home/sre/.m2/repository/org/opentest4j/opentest4j/1.3.0/opentest4j-1.3.0.jar:/home/sre/.m2/repository/org/junit/platform/junit-platform-commons/1.11.4/junit-platform-commons-1.11.4.jar:/home/sre/.m2/repository/org/apiguardian/apiguardian-api/1.1.2/apiguardian-api-1.1.2.jar:/home/sre/.m2/repository/org/junit/jupiter/junit-jupiter-params/5.11.4/junit-jupiter-params-5.11.4.jar:/home/sre/.m2/repository/org/junit/jupiter/junit-jupiter-engine/5.11.4/junit-jupiter-engine-5.11.4.jar:/home/sre/.m2/repository/org/junit/platform/junit-platform-engine/1.11.4/junit-platform-engine-1.11.4.jar:/home/sre/.m2/repository/org/mockito/mockito-core/5.14.2/mockito-core-5.14.2.jar:/home/sre/.m2/repository/net/bytebuddy/byte-buddy-agent/1.15.11/byte-buddy-agent-1.15.11.jar:/home/sre/.m2/repository/org/objenesis/objenesis/3.3/objenesis-3.3.jar:/home/sre/.m2/repository/org/mockito/mockito-junit-jupiter/5.14.2/mockito-junit-jupiter-5.14.2.jar:/home/sre/.m2/repository/org/skyscreamer/jsonassert/1.5.3/jsonassert-1.5.3.jar:/home/sre/.m2/repository/com/vaadin/external/google/android-json/0.0.20131108.vaadin1/android-json-0.0.20131108.vaadin1.jar:/home/sre/.m2/repository/org/springframework/spring-core/6.2.2/spring-core-6.2.2.jar:/home/sre/.m2/repository/org/springframework/spring-jcl/6.2.2/spring-jcl-6.2.2.jar:/home/sre/.m2/repository/org/springframework/spring-test/6.2.2/spring-test-6.2.2.jar:/home/sre/.m2/repository/org/xmlunit/xmlunit-core/2.10.0/xmlunit-core-2.10.0.jar:"/>
    <property name="test" value="MyappApplicationTests"/>
    <property name="sun.cpu.endian" value="little"/>
    <property name="user.home" value="/home/sre"/>
    <property name="user.language" value="en"/>
    <property name="java.specification.vendor" value="Oracle Corporation"/>
    <property name="java.version.date" value="2025-01-21"/>
    <property name="java.home" value="/usr/lib/jvm/java-21-openjdk-amd64"/>
    <property name="file.separator" value="/"/>
    <property name="basedir" value="/home/sre/java_projects/simple_app"/>
    <property name="java.vm.compressedOopsMode" value="32-bit"/>
    <property name="line.separator" value="&#10;"/>
    <property name="java.specification.name" value="Java Platform API Specification"/>
    <property name="java.vm.specification.vendor" value="Oracle Corporation"/>
    <property name="FILE_LOG_CHARSET" value="UTF-8"/>
    <property name="java.awt.headless" value="true"/>
    <property name="surefire.real.class.path" value="/home/sre/java_projects/simple_app/target/surefire/surefirebooter-20250212231336354_3.jar"/>
    <property name="sun.management.compiler" value="HotSpot 64-Bit Tiered Compilers"/>
    <property name="java.runtime.version" value="21.0.6+7-Ubuntu-124.04.1"/>
    <property name="user.name" value="sre"/>
    <property name="stdout.encoding" value="UTF-8"/>
    <property name="path.separator" value=":"/>
    <property name="os.version" value="6.8.0-53-generic"/>
    <property name="java.runtime.name" value="OpenJDK Runtime Environment"/>
    <property name="file.encoding" value="UTF-8"/>
    <property name="java.vm.name" value="OpenJDK 64-Bit Server VM"/>
    <property name="localRepository" value="/home/sre/.m2/repository"/>
    <property name="java.vendor.url.bug" value="https://bugs.launchpad.net/ubuntu/+source/openjdk-21"/>
    <property name="java.io.tmpdir" value="/tmp"/>
    <property name="catalina.home" value="/tmp/tomcat.0.1053560291743747366"/>
    <property name="com.zaxxer.hikari.pool_number" value="1"/>
    <property name="java.version" value="21.0.6"/>
    <property name="user.dir" value="/home/sre/java_projects/simple_app"/>
    <property name="os.arch" value="amd64"/>
    <property name="java.vm.specification.name" value="Java Virtual Machine Specification"/>
    <property name="PID" value="3005"/>
    <property name="CONSOLE_LOG_CHARSET" value="UTF-8"/>
    <property name="catalina.base" value="/tmp/tomcat.0.1053560291743747366"/>
    <property name="native.encoding" value="UTF-8"/>
    <property name="java.library.path" value="/usr/java/packages/lib:/usr/lib/x86_64-linux-gnu/jni:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/usr/lib/jni:/lib:/usr/lib"/>
    <property name="stderr.encoding" value="UTF-8"/>
    <property name="java.vm.info" value="mixed mode, sharing"/>
    <property name="java.vendor" value="Ubuntu"/>
    <property name="java.vm.version" value="21.0.6+7-Ubuntu-124.04.1"/>
    <property name="sun.io.unicode.encoding" value="UnicodeLittle"/>
    <property name="java.class.version" value="65.0"/>
    <property name="LOGGED_APPLICATION_NAME" value="[myapp] "/>
  </properties>
  <testcase name="shouldAnswerWithTrue" classname="com.simple.apps.myapp.MyappApplicationTests" time="0.826">
    <system-out><![CDATA[23:13:37.401 [main] INFO org.springframework.test.context.support.AnnotationConfigContextLoaderUtils -- Could not detect default configuration classes for test class [com.simple.apps.myapp.MyappApplicationTests]: MyappApplicationTests does not declare any static, non-private, non-final, nested classes annotated with @Configuration.
23:13:37.576 [main] INFO org.springframework.boot.test.context.SpringBootTestContextBootstrapper -- Found @SpringBootConfiguration com.simple.apps.myapp.MyappApplication for test class com.simple.apps.myapp.MyappApplicationTests

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.2)

2025-02-12T23:13:38.139Z  INFO 3005 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : Starting MyappApplicationTests using Java 21.0.6 with PID 3005 (started by sre in /home/sre/java_projects/simple_app)
2025-02-12T23:13:38.141Z  INFO 3005 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : No active profile set, falling back to 1 default profile: "default"
2025-02-12T23:13:39.163Z  INFO 3005 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Bootstrapping Spring Data JPA repositories in DEFAULT mode.
2025-02-12T23:13:39.194Z  INFO 3005 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 12 ms. Found 0 JPA repository interfaces.
2025-02-12T23:13:39.813Z  INFO 3005 --- [myapp] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port 0 (http)
2025-02-12T23:13:39.831Z  INFO 3005 --- [myapp] [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2025-02-12T23:13:39.832Z  INFO 3005 --- [myapp] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/10.1.34]
2025-02-12T23:13:39.892Z  INFO 3005 --- [myapp] [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2025-02-12T23:13:39.894Z  INFO 3005 --- [myapp] [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 1722 ms
2025-02-12T23:13:40.081Z  INFO 3005 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2025-02-12T23:13:40.549Z  INFO 3005 --- [myapp] [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection com.mysql.cj.jdbc.ConnectionImpl@4df7d9ee
2025-02-12T23:13:40.552Z  INFO 3005 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
2025-02-12T23:13:40.620Z  INFO 3005 --- [myapp] [           main] o.hibernate.jpa.internal.util.LogHelper  : HHH000204: Processing PersistenceUnitInfo [name: default]
2025-02-12T23:13:40.720Z  INFO 3005 --- [myapp] [           main] org.hibernate.Version                    : HHH000412: Hibernate ORM core version 6.6.5.Final
2025-02-12T23:13:40.768Z  INFO 3005 --- [myapp] [           main] o.h.c.internal.RegionFactoryInitiator    : HHH000026: Second-level cache disabled
2025-02-12T23:13:41.127Z  INFO 3005 --- [myapp] [           main] o.s.o.j.p.SpringPersistenceUnitInfo      : No LoadTimeWeaver setup: ignoring JPA class transformer
2025-02-12T23:13:41.247Z  INFO 3005 --- [myapp] [           main] org.hibernate.orm.connections.pooling    : HHH10001005: Database info:
	Database JDBC URL [Connecting through datasource 'HikariDataSource (HikariPool-1)']
	Database driver: undefined/unknown
	Database version: 8.0.40
	Autocommit mode: undefined/unknown
	Isolation level: undefined/unknown
	Minimum pool size: undefined/unknown
	Maximum pool size: undefined/unknown
2025-02-12T23:13:41.591Z  INFO 3005 --- [myapp] [           main] o.h.e.t.j.p.i.JtaPlatformInitiator       : HHH000489: No JTA platform available (set 'hibernate.transaction.jta.platform' to enable JTA platform integration)
2025-02-12T23:13:41.596Z  INFO 3005 --- [myapp] [           main] j.LocalContainerEntityManagerFactoryBean : Initialized JPA EntityManagerFactory for persistence unit 'default'
2025-02-12T23:13:41.656Z  WARN 3005 --- [myapp] [           main] JpaBaseConfiguration$JpaWebConfiguration : spring.jpa.open-in-view is enabled by default. Therefore, database queries may be performed during view rendering. Explicitly configure spring.jpa.open-in-view to disable this warning
2025-02-12T23:13:42.399Z  INFO 3005 --- [myapp] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 37201 (http) with context path '/'
2025-02-12T23:13:42.413Z  INFO 3005 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : Started MyappApplicationTests in 4.697 seconds (process running for 5.971)
]]></system-out>
    <system-err><![CDATA[Mockito is currently self-attaching to enable the inline-mock-maker. This will no longer work in future releases of the JDK. Please add Mockito as an agent to your build what is described in Mockito's documentation: https://javadoc.io/doc/org.mockito/mockito-core/latest/org/mockito/Mockito.html#0.3
WARNING: A Java agent has been loaded dynamically (/home/sre/.m2/repository/net/bytebuddy/byte-buddy-agent/1.15.11/byte-buddy-agent-1.15.11.jar)
WARNING: If a serviceability tool is in use, please run with -XX:+EnableDynamicAgentLoading to hide this warning
WARNING: If a serviceability tool is not in use, please run with -Djdk.instrument.traceUsage for more information
WARNING: Dynamic loading of agents will be disallowed by default in a future release
]]></system-err>
  </testcase>
  <testcase name="testGet" classname="com.simple.apps.myapp.MyappApplicationTests" time="0.235">
    <system-out><![CDATA[2025-02-12T23:13:43.381Z  INFO 3005 --- [myapp] [o-auto-1-exec-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring DispatcherServlet 'dispatcherServlet'
2025-02-12T23:13:43.382Z  INFO 3005 --- [myapp] [o-auto-1-exec-1] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
2025-02-12T23:13:43.383Z  INFO 3005 --- [myapp] [o-auto-1-exec-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 1 ms
]]></system-out>
  </testcase>
  <testcase name="testPut" classname="com.simple.apps.myapp.MyappApplicationTests" time="0.079"/>
  <testcase name="testPatch" classname="com.simple.apps.myapp.MyappApplicationTests" time="0.013"/>
  <testcase name="testPost" classname="com.simple.apps.myapp.MyappApplicationTests" time="0.018"/>
  <testcase name="contextLoads" classname="com.simple.apps.myapp.MyappApplicationTests" time="0.004"/>
  <testcase name="testDelete" classname="com.simple.apps.myapp.MyappApplicationTests" time="0.012"/>
</testsuite>
sre@ubuntu:~/java_projects/simple_app$ 

