
sre@ubuntu:~/java_projects/simple_app$ docker run --rm --name webapp -p 8080:8080 myapp-webapp

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.2)

2025-02-13T00:26:15.316Z  INFO 1 --- [myapp] [           main] com.simple.apps.myapp.MyappApplication   : Starting MyappApplication v0.0.1-SNAPSHOT using Java 21 with PID 1 (/webapp.jar started by root in /)
2025-02-13T00:26:15.321Z  INFO 1 --- [myapp] [           main] com.simple.apps.myapp.MyappApplication   : No active profile set, falling back to 1 default profile: "default"
2025-02-13T00:26:16.687Z  INFO 1 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Bootstrapping Spring Data JPA repositories in DEFAULT mode.
2025-02-13T00:26:16.715Z  INFO 1 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 16 ms. Found 0 JPA repository interfaces.
2025-02-13T00:26:17.428Z  INFO 1 --- [myapp] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port 8080 (http)
2025-02-13T00:26:17.458Z  INFO 1 --- [myapp] [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2025-02-13T00:26:17.460Z  INFO 1 --- [myapp] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/10.1.34]
2025-02-13T00:26:17.511Z  INFO 1 --- [myapp] [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2025-02-13T00:26:17.514Z  INFO 1 --- [myapp] [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 2060 ms
2025-02-13T00:26:17.730Z  INFO 1 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2025-02-13T00:26:18.607Z  INFO 1 --- [myapp] [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection com.mysql.cj.jdbc.ConnectionImpl@590765c4
2025-02-13T00:26:18.612Z  INFO 1 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
2025-02-13T00:26:18.688Z  INFO 1 --- [myapp] [           main] o.hibernate.jpa.internal.util.LogHelper  : HHH000204: Processing PersistenceUnitInfo [name: default]
2025-02-13T00:26:18.781Z  INFO 1 --- [myapp] [           main] org.hibernate.Version                    : HHH000412: Hibernate ORM core version 6.6.5.Final
2025-02-13T00:26:18.841Z  INFO 1 --- [myapp] [           main] o.h.c.internal.RegionFactoryInitiator    : HHH000026: Second-level cache disabled
2025-02-13T00:26:19.331Z  INFO 1 --- [myapp] [           main] o.s.o.j.p.SpringPersistenceUnitInfo      : No LoadTimeWeaver setup: ignoring JPA class transformer
2025-02-13T00:26:19.496Z  INFO 1 --- [myapp] [           main] org.hibernate.orm.connections.pooling    : HHH10001005: Database info:
	Database JDBC URL [Connecting through datasource 'HikariDataSource (HikariPool-1)']
	Database driver: undefined/unknown
	Database version: 8.0.40
	Autocommit mode: undefined/unknown
	Isolation level: undefined/unknown
	Minimum pool size: undefined/unknown
	Maximum pool size: undefined/unknown
2025-02-13T00:26:19.985Z  INFO 1 --- [myapp] [           main] o.h.e.t.j.p.i.JtaPlatformInitiator       : HHH000489: No JTA platform available (set 'hibernate.transaction.jta.platform' to enable JTA platform integration)
2025-02-13T00:26:19.992Z  INFO 1 --- [myapp] [           main] j.LocalContainerEntityManagerFactoryBean : Initialized JPA EntityManagerFactory for persistence unit 'default'
2025-02-13T00:26:20.063Z  WARN 1 --- [myapp] [           main] JpaBaseConfiguration$JpaWebConfiguration : spring.jpa.open-in-view is enabled by default. Therefore, database queries may be performed during view rendering. Explicitly configure spring.jpa.open-in-view to disable this warning
2025-02-13T00:26:20.546Z  INFO 1 --- [myapp] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 8080 (http) with context path '/'
2025-02-13T00:26:20.596Z  INFO 1 --- [myapp] [           main] com.simple.apps.myapp.MyappApplication   : Started MyappApplication in 6.173 seconds (process running for 7.363)
2025-02-13T00:26:45.966Z  INFO 1 --- [myapp] [nio-8080-exec-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring DispatcherServlet 'dispatcherServlet'
2025-02-13T00:26:45.967Z  INFO 1 --- [myapp] [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
2025-02-13T00:26:45.968Z  INFO 1 --- [myapp] [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 1 ms
2025-02-13T00:27:52.526Z  WARN 1 --- [myapp] [nio-8080-exec-3] .w.s.m.s.DefaultHandlerExceptionResolver : Resolved [org.springframework.web.HttpRequestMethodNotSupportedException: Request method 'GET' is not supported]
2025-02-13T00:28:01.495Z  WARN 1 --- [myapp] [nio-8080-exec-6] .w.s.m.s.DefaultHandlerExceptionResolver : Resolved [org.springframework.web.HttpRequestMethodNotSupportedException: Request method 'GET' is not supported]
2025-02-13T00:28:11.525Z  WARN 1 --- [myapp] [io-8080-exec-10] .w.s.m.s.DefaultHandlerExceptionResolver : Resolved [org.springframework.web.HttpRequestMethodNotSupportedException: Request method 'GET' is not supported]
2025-02-13T00:28:24.328Z  WARN 1 --- [myapp] [nio-8080-exec-1] .w.s.m.s.DefaultHandlerExceptionResolver : Resolved [org.springframework.web.HttpRequestMethodNotSupportedException: Request method 'GET' is not supported]

sre@ubuntu:~$ curl http://localhost:8080/
Hello, Docker Compose!
sre@ubuntu:~$ 
sre@ubuntu:~$ curl http://localhost:8080/post
{"timestamp":"2025-02-13T00:27:52.546+00:00","status":405,"error":"Method Not Allowed","path":"/post"}
sre@ubuntu:~$ 
sre@ubuntu:~$ curl http://localhost:8080/put/1
{"timestamp":"2025-02-13T00:28:01.496+00:00","status":405,"error":"Method Not Allowed","path":"/put/1"}
sre@ubuntu:~$ 
sre@ubuntu:~$ curl http://localhost:8080/delete
{"timestamp":"2025-02-13T00:28:08.858+00:00","status":404,"error":"Not Found","path":"/delete"}
sre@ubuntu:~$ 
sre@ubuntu:~$ curl http://localhost:8080/delete/1
{"timestamp":"2025-02-13T00:28:11.527+00:00","status":405,"error":"Method Not Allowed","path":"/delete/1"}
sre@ubuntu:~$ 
sre@ubuntu:~$ curl http://localhost:8080/patch/1
{"timestamp":"2025-02-13T00:28:24.329+00:00","status":405,"error":"Method Not Allowed","path":"/patch/1"}
sre@ubuntu:~$ 

sre@ubuntu:~$ curl --data '{"hello": "world"}' http://localhost:8080/post
{"timestamp":"2025-02-13T00:32:30.650+00:00","status":415,"error":"Unsupported Media Type","path":"/post"}

