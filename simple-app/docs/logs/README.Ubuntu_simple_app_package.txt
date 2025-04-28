
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

sre@ubuntu:~/java_projects/simple_app/myapp$ mvn package
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
18:45:38.304 [main] INFO org.springframework.test.context.support.AnnotationConfigContextLoaderUtils -- Could not detect default configuration classes for test class [com.simple.apps.myapp.MyappApplicationTests]: MyappApplicationTests does not declare any static, non-private, non-final, nested classes annotated with @Configuration.
18:45:38.459 [main] INFO org.springframework.boot.test.context.SpringBootTestContextBootstrapper -- Found @SpringBootConfiguration com.simple.apps.myapp.MyappApplication for test class com.simple.apps.myapp.MyappApplicationTests

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.2)

2025-02-12T18:45:39.011Z  INFO 28969 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : Starting MyappApplicationTests using Java 21.0.6 with PID 28969 (started by sre in /home/sre/java_projects/simple_app/myapp)
2025-02-12T18:45:39.014Z  INFO 28969 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : No active profile set, falling back to 1 default profile: "default"
2025-02-12T18:45:39.974Z  INFO 28969 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Bootstrapping Spring Data JPA repositories in DEFAULT mode.
2025-02-12T18:45:39.996Z  INFO 28969 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 10 ms. Found 0 JPA repository interfaces.
2025-02-12T18:45:40.650Z  INFO 28969 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2025-02-12T18:45:41.366Z  INFO 28969 --- [myapp] [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection com.mysql.cj.jdbc.ConnectionImpl@7418d76e
2025-02-12T18:45:41.368Z  INFO 28969 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
2025-02-12T18:45:41.450Z  INFO 28969 --- [myapp] [           main] o.hibernate.jpa.internal.util.LogHelper  : HHH000204: Processing PersistenceUnitInfo [name: default]
2025-02-12T18:45:41.539Z  INFO 28969 --- [myapp] [           main] org.hibernate.Version                    : HHH000412: Hibernate ORM core version 6.6.5.Final
2025-02-12T18:45:41.587Z  INFO 28969 --- [myapp] [           main] o.h.c.internal.RegionFactoryInitiator    : HHH000026: Second-level cache disabled
2025-02-12T18:45:41.947Z  INFO 28969 --- [myapp] [           main] o.s.o.j.p.SpringPersistenceUnitInfo      : No LoadTimeWeaver setup: ignoring JPA class transformer
2025-02-12T18:45:42.069Z  INFO 28969 --- [myapp] [           main] org.hibernate.orm.connections.pooling    : HHH10001005: Database info:
	Database JDBC URL [Connecting through datasource 'HikariDataSource (HikariPool-1)']
	Database driver: undefined/unknown
	Database version: 8.0.40
	Autocommit mode: undefined/unknown
	Isolation level: undefined/unknown
	Minimum pool size: undefined/unknown
	Maximum pool size: undefined/unknown
2025-02-12T18:45:42.485Z  INFO 28969 --- [myapp] [           main] o.h.e.t.j.p.i.JtaPlatformInitiator       : HHH000489: No JTA platform available (set 'hibernate.transaction.jta.platform' to enable JTA platform integration)
2025-02-12T18:45:42.490Z  INFO 28969 --- [myapp] [           main] j.LocalContainerEntityManagerFactoryBean : Initialized JPA EntityManagerFactory for persistence unit 'default'
2025-02-12T18:45:42.704Z  WARN 28969 --- [myapp] [           main] JpaBaseConfiguration$JpaWebConfiguration : spring.jpa.open-in-view is enabled by default. Therefore, database queries may be performed during view rendering. Explicitly configure spring.jpa.open-in-view to disable this warning
2025-02-12T18:45:43.212Z  INFO 28969 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : Started MyappApplicationTests in 4.617 seconds (process running for 5.77)
Mockito is currently self-attaching to enable the inline-mock-maker. This will no longer work in future releases of the JDK. Please add Mockito as an agent to your build what is described in Mockito's documentation: https://javadoc.io/doc/org.mockito/mockito-core/latest/org/mockito/Mockito.html#0.3
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
WARNING: A Java agent has been loaded dynamically (/home/sre/.m2/repository/net/bytebuddy/byte-buddy-agent/1.15.11/byte-buddy-agent-1.15.11.jar)
WARNING: If a serviceability tool is in use, please run with -XX:+EnableDynamicAgentLoading to hide this warning
WARNING: If a serviceability tool is not in use, please run with -Djdk.instrument.traceUsage for more information
WARNING: Dynamic loading of agents will be disallowed by default in a future release
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 6.232 s -- in com.simple.apps.myapp.MyappApplicationTests
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] 
[INFO] --- maven-jar-plugin:3.4.2:jar (default-jar) @ myapp ---
[INFO] Building jar: /home/sre/java_projects/simple_app/myapp/target/myapp-0.0.1-SNAPSHOT.jar
[INFO] 
[INFO] --- spring-boot-maven-plugin:3.4.2:repackage (repackage) @ myapp ---
[INFO] Replacing main artifact /home/sre/java_projects/simple_app/myapp/target/myapp-0.0.1-SNAPSHOT.jar with repackaged archive, adding nested dependencies in BOOT-INF/.
[INFO] The original artifact has been renamed to /home/sre/java_projects/simple_app/myapp/target/myapp-0.0.1-SNAPSHOT.jar.original
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  12.966 s
[INFO] Finished at: 2025-02-12T18:45:46Z
[INFO] ------------------------------------------------------------------------
sre@ubuntu:~/java_projects/simple_app/myapp$ 

sre@ubuntu:~/java_projects/simple_app/myapp$ ls -l target/
total 55116
drwxrwxr-x 3 sre sre     4096 Feb 12 18:44 classes
drwxrwxr-x 3 sre sre     4096 Feb 12 18:44 generated-sources
drwxrwxr-x 3 sre sre     4096 Feb 12 18:45 generated-test-sources
drwxrwxr-x 2 sre sre     4096 Feb 12 18:45 maven-archiver
drwxrwxr-x 3 sre sre     4096 Feb 12 18:44 maven-status
-rw-rw-r-- 1 sre sre 56405433 Feb 12 18:45 myapp-0.0.1-SNAPSHOT.jar
-rw-rw-r-- 1 sre sre     3334 Feb 12 18:45 myapp-0.0.1-SNAPSHOT.jar.original
drwxrwxr-x 2 sre sre     4096 Feb 12 18:46 surefire-reports
drwxrwxr-x 3 sre sre     4096 Feb 12 18:45 test-classes

sre@ubuntu:~/java_projects/simple_app$ mvn package
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
22:58:09.293 [main] INFO org.springframework.test.context.support.AnnotationConfigContextLoaderUtils -- Could not detect default configuration classes for test class [com.simple.apps.myapp.MyappApplicationTests]: MyappApplicationTests does not declare any static, non-private, non-final, nested classes annotated with @Configuration.
22:58:09.492 [main] INFO org.springframework.boot.test.context.SpringBootTestContextBootstrapper -- Found @SpringBootConfiguration com.simple.apps.myapp.MyappApplication for test class com.simple.apps.myapp.MyappApplicationTests

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.2)

2025-02-12T22:58:10.059Z  INFO 2265 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : Starting MyappApplicationTests using Java 21.0.6 with PID 2265 (started by sre in /home/sre/java_projects/simple_app)
2025-02-12T22:58:10.068Z  INFO 2265 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : No active profile set, falling back to 1 default profile: "default"
2025-02-12T22:58:11.095Z  INFO 2265 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Bootstrapping Spring Data JPA repositories in DEFAULT mode.
2025-02-12T22:58:11.118Z  INFO 2265 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 12 ms. Found 0 JPA repository interfaces.
2025-02-12T22:58:11.885Z  INFO 2265 --- [myapp] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port 0 (http)
2025-02-12T22:58:11.905Z  INFO 2265 --- [myapp] [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2025-02-12T22:58:11.906Z  INFO 2265 --- [myapp] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/10.1.34]
2025-02-12T22:58:11.953Z  INFO 2265 --- [myapp] [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2025-02-12T22:58:11.954Z  INFO 2265 --- [myapp] [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 1832 ms
2025-02-12T22:58:12.096Z  INFO 2265 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2025-02-12T22:58:12.709Z  INFO 2265 --- [myapp] [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection com.mysql.cj.jdbc.ConnectionImpl@537b3b2e
2025-02-12T22:58:12.711Z  INFO 2265 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
2025-02-12T22:58:12.789Z  INFO 2265 --- [myapp] [           main] o.hibernate.jpa.internal.util.LogHelper  : HHH000204: Processing PersistenceUnitInfo [name: default]
2025-02-12T22:58:12.854Z  INFO 2265 --- [myapp] [           main] org.hibernate.Version                    : HHH000412: Hibernate ORM core version 6.6.5.Final
2025-02-12T22:58:12.940Z  INFO 2265 --- [myapp] [           main] o.h.c.internal.RegionFactoryInitiator    : HHH000026: Second-level cache disabled
2025-02-12T22:58:13.314Z  INFO 2265 --- [myapp] [           main] o.s.o.j.p.SpringPersistenceUnitInfo      : No LoadTimeWeaver setup: ignoring JPA class transformer
2025-02-12T22:58:13.459Z  INFO 2265 --- [myapp] [           main] org.hibernate.orm.connections.pooling    : HHH10001005: Database info:
	Database JDBC URL [Connecting through datasource 'HikariDataSource (HikariPool-1)']
	Database driver: undefined/unknown
	Database version: 8.0.40
	Autocommit mode: undefined/unknown
	Isolation level: undefined/unknown
	Minimum pool size: undefined/unknown
	Maximum pool size: undefined/unknown
2025-02-12T22:58:13.886Z  INFO 2265 --- [myapp] [           main] o.h.e.t.j.p.i.JtaPlatformInitiator       : HHH000489: No JTA platform available (set 'hibernate.transaction.jta.platform' to enable JTA platform integration)
2025-02-12T22:58:13.893Z  INFO 2265 --- [myapp] [           main] j.LocalContainerEntityManagerFactoryBean : Initialized JPA EntityManagerFactory for persistence unit 'default'
2025-02-12T22:58:13.959Z  WARN 2265 --- [myapp] [           main] JpaBaseConfiguration$JpaWebConfiguration : spring.jpa.open-in-view is enabled by default. Therefore, database queries may be performed during view rendering. Explicitly configure spring.jpa.open-in-view to disable this warning
2025-02-12T22:58:14.737Z  INFO 2265 --- [myapp] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 41811 (http) with context path '/'
2025-02-12T22:58:14.756Z  INFO 2265 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : Started MyappApplicationTests in 5.085 seconds (process running for 6.423)
Mockito is currently self-attaching to enable the inline-mock-maker. This will no longer work in future releases of the JDK. Please add Mockito as an agent to your build what is described in Mockito's documentation: https://javadoc.io/doc/org.mockito/mockito-core/latest/org/mockito/Mockito.html#0.3
WARNING: A Java agent has been loaded dynamically (/home/sre/.m2/repository/net/bytebuddy/byte-buddy-agent/1.15.11/byte-buddy-agent-1.15.11.jar)
WARNING: If a serviceability tool is in use, please run with -XX:+EnableDynamicAgentLoading to hide this warning
WARNING: If a serviceability tool is not in use, please run with -Djdk.instrument.traceUsage for more information
WARNING: Dynamic loading of agents will be disallowed by default in a future release
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
2025-02-12T22:58:15.703Z  INFO 2265 --- [myapp] [o-auto-1-exec-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring DispatcherServlet 'dispatcherServlet'
2025-02-12T22:58:15.703Z  INFO 2265 --- [myapp] [o-auto-1-exec-1] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
2025-02-12T22:58:15.705Z  INFO 2265 --- [myapp] [o-auto-1-exec-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 1 ms
[INFO] Tests run: 7, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 6.947 s -- in com.simple.apps.myapp.MyappApplicationTests
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 7, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] 
[INFO] --- maven-jar-plugin:3.4.2:jar (default-jar) @ myapp ---
[INFO] 
[INFO] --- spring-boot-maven-plugin:3.4.2:repackage (repackage) @ myapp ---
[INFO] Replacing main artifact /home/sre/java_projects/simple_app/target/myapp-0.0.1-SNAPSHOT.jar with repackaged archive, adding nested dependencies in BOOT-INF/.
[INFO] The original artifact has been renamed to /home/sre/java_projects/simple_app/target/myapp-0.0.1-SNAPSHOT.jar.original
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  12.863 s
[INFO] Finished at: 2025-02-12T22:58:17Z
[INFO] ------------------------------------------------------------------------

sre@ubuntu:~/java_projects/simple_app$ ls -l target/myapp-0.0.1-SNAPSHOT.jar
-rw-rw-r-- 1 sre sre 56406195 Feb 12 22:55 target/myapp-0.0.1-SNAPSHOT.jar

sre@ubuntu:~/java_projects/simple_app$ mvn package
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
23:05:03.230 [main] INFO org.springframework.test.context.support.AnnotationConfigContextLoaderUtils -- Could not detect default configuration classes for test class [com.simple.apps.myapp.MyappApplicationTests]: MyappApplicationTests does not declare any static, non-private, non-final, nested classes annotated with @Configuration.
23:05:03.413 [main] INFO org.springframework.boot.test.context.SpringBootTestContextBootstrapper -- Found @SpringBootConfiguration com.simple.apps.myapp.MyappApplication for test class com.simple.apps.myapp.MyappApplicationTests

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.2)

2025-02-12T23:05:03.972Z  INFO 2603 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : Starting MyappApplicationTests using Java 21.0.6 with PID 2603 (started by sre in /home/sre/java_projects/simple_app)
2025-02-12T23:05:03.974Z  INFO 2603 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : No active profile set, falling back to 1 default profile: "default"
2025-02-12T23:05:04.964Z  INFO 2603 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Bootstrapping Spring Data JPA repositories in DEFAULT mode.
2025-02-12T23:05:04.996Z  INFO 2603 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 12 ms. Found 0 JPA repository interfaces.
2025-02-12T23:05:05.602Z  INFO 2603 --- [myapp] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port 0 (http)
2025-02-12T23:05:05.617Z  INFO 2603 --- [myapp] [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2025-02-12T23:05:05.619Z  INFO 2603 --- [myapp] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/10.1.34]
2025-02-12T23:05:05.674Z  INFO 2603 --- [myapp] [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2025-02-12T23:05:05.676Z  INFO 2603 --- [myapp] [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 1657 ms
2025-02-12T23:05:05.902Z  INFO 2603 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2025-02-12T23:05:06.444Z  INFO 2603 --- [myapp] [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection com.mysql.cj.jdbc.ConnectionImpl@773eca84
2025-02-12T23:05:06.446Z  INFO 2603 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
2025-02-12T23:05:06.508Z  INFO 2603 --- [myapp] [           main] o.hibernate.jpa.internal.util.LogHelper  : HHH000204: Processing PersistenceUnitInfo [name: default]
2025-02-12T23:05:06.565Z  INFO 2603 --- [myapp] [           main] org.hibernate.Version                    : HHH000412: Hibernate ORM core version 6.6.5.Final
2025-02-12T23:05:06.625Z  INFO 2603 --- [myapp] [           main] o.h.c.internal.RegionFactoryInitiator    : HHH000026: Second-level cache disabled
2025-02-12T23:05:06.987Z  INFO 2603 --- [myapp] [           main] o.s.o.j.p.SpringPersistenceUnitInfo      : No LoadTimeWeaver setup: ignoring JPA class transformer
2025-02-12T23:05:07.119Z  INFO 2603 --- [myapp] [           main] org.hibernate.orm.connections.pooling    : HHH10001005: Database info:
	Database JDBC URL [Connecting through datasource 'HikariDataSource (HikariPool-1)']
	Database driver: undefined/unknown
	Database version: 8.0.40
	Autocommit mode: undefined/unknown
	Isolation level: undefined/unknown
	Minimum pool size: undefined/unknown
	Maximum pool size: undefined/unknown
2025-02-12T23:05:07.503Z  INFO 2603 --- [myapp] [           main] o.h.e.t.j.p.i.JtaPlatformInitiator       : HHH000489: No JTA platform available (set 'hibernate.transaction.jta.platform' to enable JTA platform integration)
2025-02-12T23:05:07.509Z  INFO 2603 --- [myapp] [           main] j.LocalContainerEntityManagerFactoryBean : Initialized JPA EntityManagerFactory for persistence unit 'default'
2025-02-12T23:05:07.587Z  WARN 2603 --- [myapp] [           main] JpaBaseConfiguration$JpaWebConfiguration : spring.jpa.open-in-view is enabled by default. Therefore, database queries may be performed during view rendering. Explicitly configure spring.jpa.open-in-view to disable this warning
2025-02-12T23:05:08.393Z  INFO 2603 --- [myapp] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 42657 (http) with context path '/'
2025-02-12T23:05:08.405Z  INFO 2603 --- [myapp] [           main] c.s.apps.myapp.MyappApplicationTests     : Started MyappApplicationTests in 4.849 seconds (process running for 6.07)
Mockito is currently self-attaching to enable the inline-mock-maker. This will no longer work in future releases of the JDK. Please add Mockito as an agent to your build what is described in Mockito's documentation: https://javadoc.io/doc/org.mockito/mockito-core/latest/org/mockito/Mockito.html#0.3
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
WARNING: A Java agent has been loaded dynamically (/home/sre/.m2/repository/net/bytebuddy/byte-buddy-agent/1.15.11/byte-buddy-agent-1.15.11.jar)
WARNING: If a serviceability tool is in use, please run with -XX:+EnableDynamicAgentLoading to hide this warning
WARNING: If a serviceability tool is not in use, please run with -Djdk.instrument.traceUsage for more information
WARNING: Dynamic loading of agents will be disallowed by default in a future release
2025-02-12T23:05:09.380Z  INFO 2603 --- [myapp] [o-auto-1-exec-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring DispatcherServlet 'dispatcherServlet'
2025-02-12T23:05:09.380Z  INFO 2603 --- [myapp] [o-auto-1-exec-1] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
2025-02-12T23:05:09.382Z  INFO 2603 --- [myapp] [o-auto-1-exec-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 1 ms
[INFO] Tests run: 7, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 6.616 s -- in com.simple.apps.myapp.MyappApplicationTests
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 7, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] 
[INFO] --- maven-jar-plugin:3.4.2:jar (default-jar) @ myapp ---
[INFO] Building jar: /home/sre/java_projects/simple_app/target/myapp-0.0.1-SNAPSHOT.jar
[INFO] 
[INFO] --- spring-boot-maven-plugin:3.4.2:repackage (repackage) @ myapp ---
[INFO] Replacing main artifact /home/sre/java_projects/simple_app/target/myapp-0.0.1-SNAPSHOT.jar with repackaged archive, adding nested dependencies in BOOT-INF/.
[INFO] The original artifact has been renamed to /home/sre/java_projects/simple_app/target/myapp-0.0.1-SNAPSHOT.jar.original
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  10.494 s
[INFO] Finished at: 2025-02-12T23:05:11Z
[INFO] ------------------------------------------------------------------------
sre@ubuntu:~/java_projects/simple_app$ 

sre@ubuntu:~/java_projects/simple_app$ ls -l target/myapp-0.0.1-SNAPSHOT.jar
-rw-rw-r-- 1 sre sre 56406276 Feb 12 23:05 target/myapp-0.0.1-SNAPSHOT.jar
sre@ubuntu:~/java_projects/simple_app$ date
Wed Feb 12 23:06:06 UTC 2025

