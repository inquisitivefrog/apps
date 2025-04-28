
sre@ubuntu:~/java_projects/simple_app$ docker build -t myapp-webapp .
[+] Building 53.4s (7/7) FINISHED                                                                           docker:default
 => [internal] load build definition from Dockerfile                                                                  0.0s
 => => transferring dockerfile: 158B                                                                                  0.0s
 => [internal] load metadata for docker.io/library/openjdk:21-jdk-slim                                                1.3s
 => [internal] load .dockerignore                                                                                     0.0s
 => => transferring context: 2B                                                                                       0.0s
 => [internal] load build context                                                                                     1.3s
 => => transferring context: 56.42MB                                                                                  1.3s
 => [1/2] FROM docker.io/library/openjdk:21-jdk-slim@sha256:7072053847a8a05d7f3a14ebc778a90b38c50ce7e8f199382128a53  51.2s
 => => resolve docker.io/library/openjdk:21-jdk-slim@sha256:7072053847a8a05d7f3a14ebc778a90b38c50ce7e8f199382128a533  0.1s
 => => sha256:7072053847a8a05d7f3a14ebc778a90b38c50ce7e8f199382128a53385160688 547B / 547B                            0.0s
 => => sha256:e088daf5e2873f2880c7242c6f0efaa68da81f560783e3e1049ba57ca152e20a 953B / 953B                            0.0s
 => => sha256:a48f4cb737303e18b873b859fa7b779610a67a01e2d33c0b453d05fc1a4bb7b0 4.77kB / 4.77kB                        0.0s
 => => sha256:a803e7c4b030119420574a882a52b6431e160fceb7620f61b525d49bc2d58886 29.12MB / 29.12MB                     12.9s
 => => sha256:b4972576c83dad66aa1e4f6d08e74f9e551e721a7cb2dc5370fe8da1af5b11e8 4.01MB / 4.01MB                        2.2s
 => => sha256:af800cd8441e394f9ec3832393ff933c52e165c0965089937e3fb16ea395ea19 204.31MB / 204.31MB                   45.8s
 => => extracting sha256:a803e7c4b030119420574a882a52b6431e160fceb7620f61b525d49bc2d58886                             3.8s
 => => extracting sha256:b4972576c83dad66aa1e4f6d08e74f9e551e721a7cb2dc5370fe8da1af5b11e8                             0.6s
 => => extracting sha256:af800cd8441e394f9ec3832393ff933c52e165c0965089937e3fb16ea395ea19                             5.2s
 => [2/2] COPY target/*.jar webapp.jar                                                                                0.4s
 => exporting to image                                                                                                0.3s
 => => exporting layers                                                                                               0.3s
 => => writing image sha256:b679034e98f1ff8a5e7dff4560e845fc3ce417a32bef991bd328aaf028c15580                          0.0s
 => => naming to docker.io/library/myapp-webapp                                                                       0.0s
sre@ubuntu:~/java_projects/simple_app$ docker images
REPOSITORY     TAG       IMAGE ID       CREATED          SIZE
myapp-webapp   latest    b679034e98f1   26 seconds ago   495MB
sre@ubuntu:~/java_projects/simple_app$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
sre@ubuntu:~/java_projects/simple_app$ docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
sre@ubuntu:~/java_projects/simple_app$ docker run --rm --name webapp -p 8080:8080 myapp-webapp

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.2)

2025-02-12T21:40:50.576Z  INFO 1 --- [myapp] [           main] com.simple.apps.myapp.MyappApplication   : Starting MyappApplication v0.0.1-SNAPSHOT using Java 21 with PID 1 (/webapp.jar started by root in /)
2025-02-12T21:40:50.592Z  INFO 1 --- [myapp] [           main] com.simple.apps.myapp.MyappApplication   : No active profile set, falling back to 1 default profile: "default"
2025-02-12T21:40:52.012Z  INFO 1 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Bootstrapping Spring Data JPA repositories in DEFAULT mode.
2025-02-12T21:40:52.042Z  INFO 1 --- [myapp] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 12 ms. Found 0 JPA repository interfaces.
2025-02-12T21:40:52.801Z  INFO 1 --- [myapp] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port 8080 (http)
2025-02-12T21:40:52.819Z  INFO 1 --- [myapp] [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2025-02-12T21:40:52.819Z  INFO 1 --- [myapp] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/10.1.34]
2025-02-12T21:40:52.856Z  INFO 1 --- [myapp] [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2025-02-12T21:40:52.859Z  INFO 1 --- [myapp] [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 2134 ms
2025-02-12T21:40:53.024Z  INFO 1 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2025-02-12T21:40:53.668Z  INFO 1 --- [myapp] [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection com.mysql.cj.jdbc.ConnectionImpl@262a1fad
2025-02-12T21:40:53.672Z  INFO 1 --- [myapp] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
2025-02-12T21:40:53.751Z  INFO 1 --- [myapp] [           main] o.hibernate.jpa.internal.util.LogHelper  : HHH000204: Processing PersistenceUnitInfo [name: default]
2025-02-12T21:40:53.863Z  INFO 1 --- [myapp] [           main] org.hibernate.Version                    : HHH000412: Hibernate ORM core version 6.6.5.Final
2025-02-12T21:40:53.913Z  INFO 1 --- [myapp] [           main] o.h.c.internal.RegionFactoryInitiator    : HHH000026: Second-level cache disabled
2025-02-12T21:40:54.450Z  INFO 1 --- [myapp] [           main] o.s.o.j.p.SpringPersistenceUnitInfo      : No LoadTimeWeaver setup: ignoring JPA class transformer
2025-02-12T21:40:54.617Z  INFO 1 --- [myapp] [           main] org.hibernate.orm.connections.pooling    : HHH10001005: Database info:
	Database JDBC URL [Connecting through datasource 'HikariDataSource (HikariPool-1)']
	Database driver: undefined/unknown
	Database version: 8.0.40
	Autocommit mode: undefined/unknown
	Isolation level: undefined/unknown
	Minimum pool size: undefined/unknown
	Maximum pool size: undefined/unknown
2025-02-12T21:40:55.098Z  INFO 1 --- [myapp] [           main] o.h.e.t.j.p.i.JtaPlatformInitiator       : HHH000489: No JTA platform available (set 'hibernate.transaction.jta.platform' to enable JTA platform integration)
2025-02-12T21:40:55.105Z  INFO 1 --- [myapp] [           main] j.LocalContainerEntityManagerFactoryBean : Initialized JPA EntityManagerFactory for persistence unit 'default'
2025-02-12T21:40:55.199Z  WARN 1 --- [myapp] [           main] JpaBaseConfiguration$JpaWebConfiguration : spring.jpa.open-in-view is enabled by default. Therefore, database queries may be performed during view rendering. Explicitly configure spring.jpa.open-in-view to disable this warning
2025-02-12T21:40:55.763Z  INFO 1 --- [myapp] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 8080 (http) with context path '/'
2025-02-12T21:40:55.788Z  INFO 1 --- [myapp] [           main] com.simple.apps.myapp.MyappApplication   : Started MyappApplication in 5.932 seconds (process running for 6.87)

2025-02-12T21:41:38.909Z  INFO 1 --- [myapp] [nio-8080-exec-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring DispatcherServlet 'dispatcherServlet'
2025-02-12T21:41:38.909Z  INFO 1 --- [myapp] [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
2025-02-12T21:41:38.915Z  INFO 1 --- [myapp] [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 5 ms

sre@ubuntu:~$ curl http://localhost:8080/
Hello, Docker Compose!


