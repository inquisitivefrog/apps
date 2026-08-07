tim@Tims-MBP houseprice % mvn package
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------------------< com.example:houseprice >-----------------------
[INFO] Building houseprice 0.0.1-SNAPSHOT
[INFO]   from pom.xml
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- resources:3.3.1:resources (default-resources) @ houseprice ---
[INFO] Copying 1 resource from src/main/resources to target/classes
[INFO] Copying 0 resource from src/main/resources to target/classes
[INFO] 
[INFO] --- compiler:3.13.0:compile (default-compile) @ houseprice ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- resources:3.3.1:testResources (default-testResources) @ houseprice ---
[INFO] skip non existing resourceDirectory /Users/tim/Documents/workspace/java/houseprice/src/test/resources
[INFO] 
[INFO] --- compiler:3.13.0:testCompile (default-testCompile) @ houseprice ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- surefire:3.5.2:test (default-test) @ houseprice ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.example.houseprice.HousepriceApplicationTests
16:16:53.218 [main] INFO org.springframework.test.context.support.AnnotationConfigContextLoaderUtils -- Could not detect default configuration classes for test class [com.example.houseprice.HousepriceApplicationTests]: HousepriceApplicationTests does not declare any static, non-private, non-final, nested classes annotated with @Configuration.
16:16:53.305 [main] INFO org.springframework.boot.test.context.SpringBootTestContextBootstrapper -- Found @SpringBootConfiguration com.example.houseprice.HousepriceApplication for test class com.example.houseprice.HousepriceApplicationTests

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.4)

2025-04-21T16:16:53.700-07:00  INFO 12082 --- [houseprice] [           main] c.e.h.HousepriceApplicationTests         : Starting HousepriceApplicationTests using Java 17.0.15 with PID 12082 (started by tim in /Users/tim/Documents/workspace/java/houseprice)
2025-04-21T16:16:53.701-07:00  INFO 12082 --- [houseprice] [           main] c.e.h.HousepriceApplicationTests         : No active profile set, falling back to 1 default profile: "default"
2025-04-21T16:16:54.752-07:00  INFO 12082 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : RMSE: 14445.524238521559
2025-04-21T16:16:55.140-07:00  INFO 12082 --- [houseprice] [           main] c.e.h.HousepriceApplicationTests         : Started HousepriceApplicationTests in 1.693 seconds (process running for 2.537)
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 2.700 s -- in com.example.houseprice.HousepriceApplicationTests
[INFO] Running com.example.houseprice.controller.PricePredictionControllerTest
2025-04-21T16:16:55.798-07:00  INFO 12082 --- [houseprice] [           main] t.c.s.AnnotationConfigContextLoaderUtils : Could not detect default configuration classes for test class [com.example.houseprice.controller.PricePredictionControllerTest]: PricePredictionControllerTest does not declare any static, non-private, non-final, nested classes annotated with @Configuration.
2025-04-21T16:16:55.820-07:00  INFO 12082 --- [houseprice] [           main] .b.t.c.SpringBootTestContextBootstrapper : Found @SpringBootConfiguration com.example.houseprice.HousepriceApplication for test class com.example.houseprice.controller.PricePredictionControllerTest

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.4)

2025-04-21T16:16:55.855-07:00  INFO 12082 --- [houseprice] [           main] c.e.h.c.PricePredictionControllerTest    : Starting PricePredictionControllerTest using Java 17.0.15 with PID 12082 (started by tim in /Users/tim/Documents/workspace/java/houseprice)
2025-04-21T16:16:55.855-07:00  INFO 12082 --- [houseprice] [           main] c.e.h.c.PricePredictionControllerTest    : No active profile set, falling back to 1 default profile: "default"
2025-04-21T16:16:56.021-07:00  INFO 12082 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : RMSE: 10416.148020248533
2025-04-21T16:16:56.149-07:00  INFO 12082 --- [houseprice] [           main] o.s.b.t.m.w.SpringBootMockServletContext : Initializing Spring TestDispatcherServlet ''
2025-04-21T16:16:56.149-07:00  INFO 12082 --- [houseprice] [           main] o.s.t.web.servlet.TestDispatcherServlet  : Initializing Servlet ''
2025-04-21T16:16:56.152-07:00  INFO 12082 --- [houseprice] [           main] o.s.t.web.servlet.TestDispatcherServlet  : Completed initialization in 1 ms
2025-04-21T16:16:56.164-07:00  INFO 12082 --- [houseprice] [           main] c.e.h.c.PricePredictionControllerTest    : Started PricePredictionControllerTest in 0.338 seconds (process running for 3.561)
2025-04-21T16:16:56.171-07:00  INFO 12082 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Predicting for size=1800.75, bedrooms=3
2025-04-21T16:16:56.172-07:00  INFO 12082 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Prediction: 273977.51335867355
2025-04-21T16:16:56.249-07:00  INFO 12082 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Predicting for size=1800.75, bedrooms=3
2025-04-21T16:16:56.258-07:00  INFO 12082 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Prediction: 273977.51335867355
2025-04-21T16:16:56.357-07:00  INFO 12082 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Predicting for size=-100.0, bedrooms=3
2025-04-21T16:16:56.358-07:00 ERROR 12082 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Invalid input: size=-100.0, bedrooms=3
2025-04-21T16:16:56.378-07:00  INFO 12082 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Predicting for size=3000.0, bedrooms=-2
2025-04-21T16:16:56.379-07:00 ERROR 12082 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Invalid input: size=3000.0, bedrooms=-2
[INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.597 s -- in com.example.houseprice.controller.PricePredictionControllerTest
[INFO] Running com.example.houseprice.service.PricePredictionServiceTest
2025-04-21T16:16:56.398-07:00  INFO 12082 --- [houseprice] [           main] t.c.s.AnnotationConfigContextLoaderUtils : Could not detect default configuration classes for test class [com.example.houseprice.service.PricePredictionServiceTest]: PricePredictionServiceTest does not declare any static, non-private, non-final, nested classes annotated with @Configuration.
2025-04-21T16:16:56.409-07:00  INFO 12082 --- [houseprice] [           main] .b.t.c.SpringBootTestContextBootstrapper : Found @SpringBootConfiguration com.example.houseprice.HousepriceApplication for test class com.example.houseprice.service.PricePredictionServiceTest
2025-04-21T16:16:56.416-07:00  INFO 12082 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Predicting for size=1800.75, bedrooms=3
2025-04-21T16:16:56.417-07:00  INFO 12082 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Prediction: 273977.51335867355
Predicted price: 273977.51335867355
RMSE: 14445.52
2025-04-21T16:16:56.434-07:00  INFO 12082 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Predicting for size=-100.0, bedrooms=3
2025-04-21T16:16:56.435-07:00 ERROR 12082 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Invalid input: size=-100.0, bedrooms=3
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.044 s -- in com.example.houseprice.service.PricePredictionServiceTest
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 8, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] 
[INFO] --- jar:3.4.2:jar (default-jar) @ houseprice ---
[INFO] 
[INFO] --- spring-boot:3.4.4:repackage (repackage) @ houseprice ---
[INFO] Replacing main artifact /Users/tim/Documents/workspace/java/houseprice/target/houseprice-0.0.1-SNAPSHOT.jar with repackaged archive, adding nested dependencies in BOOT-INF/.
[INFO] The original artifact has been renamed to /Users/tim/Documents/workspace/java/houseprice/target/houseprice-0.0.1-SNAPSHOT.jar.original
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  5.736 s
[INFO] Finished at: 2025-04-21T16:16:57-07:00
[INFO] ------------------------------------------------------------------------
tim@Tims-MBP houseprice % java -jar target/houseprice-0.0.1-SNAPSHOT.jar 

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.4)

2025-04-21T16:17:06.345-07:00  INFO 12084 --- [houseprice] [           main] c.e.houseprice.HousepriceApplication     : Starting HousepriceApplication v0.0.1-SNAPSHOT using Java 17.0.15 with PID 12084 (/Users/tim/Documents/workspace/java/houseprice/target/houseprice-0.0.1-SNAPSHOT.jar started by tim in /Users/tim/Documents/workspace/java/houseprice)
2025-04-21T16:17:06.350-07:00  INFO 12084 --- [houseprice] [           main] c.e.houseprice.HousepriceApplication     : No active profile set, falling back to 1 default profile: "default"
2025-04-21T16:17:07.356-07:00  INFO 12084 --- [houseprice] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port 8080 (http)
2025-04-21T16:17:07.372-07:00  INFO 12084 --- [houseprice] [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2025-04-21T16:17:07.372-07:00  INFO 12084 --- [houseprice] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/10.1.39]
2025-04-21T16:17:07.416-07:00  INFO 12084 --- [houseprice] [           main] o.a.c.c.C.[Tomcat].[localhost].[/api]    : Initializing Spring embedded WebApplicationContext
2025-04-21T16:17:07.418-07:00  INFO 12084 --- [houseprice] [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 987 ms
2025-04-21T16:17:08.478-07:00  INFO 12084 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : RMSE: 14445.524238521559
2025-04-21T16:17:08.837-07:00  INFO 12084 --- [houseprice] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 8080 (http) with context path '/api'
2025-04-21T16:17:08.857-07:00  INFO 12084 --- [houseprice] [           main] c.e.houseprice.HousepriceApplication     : Started HousepriceApplication in 3.013 seconds (process running for 3.476)
^C2025-04-21T16:17:16.141-07:00  INFO 12084 --- [houseprice] [ionShutdownHook] o.s.b.w.e.tomcat.GracefulShutdown        : Commencing graceful shutdown. Waiting for active requests to complete

