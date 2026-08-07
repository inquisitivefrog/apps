tim@Tims-MBP houseprice % mvn clean install
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------------------< com.example:houseprice >-----------------------
[INFO] Building houseprice 0.0.1-SNAPSHOT
[INFO]   from pom.xml
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- clean:3.4.1:clean (default-clean) @ houseprice ---
[INFO] 
[INFO] --- resources:3.3.1:resources (default-resources) @ houseprice ---
[INFO] Copying 1 resource from src/main/resources to target/classes
[INFO] Copying 0 resource from src/main/resources to target/classes
[INFO] 
[INFO] --- compiler:3.13.0:compile (default-compile) @ houseprice ---
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 3 source files with javac [debug parameters release 17] to target/classes
[INFO] 
[INFO] --- resources:3.3.1:testResources (default-testResources) @ houseprice ---
[INFO] skip non existing resourceDirectory /Users/tim/Documents/workspace/java/houseprice/src/test/resources
[INFO] 
[INFO] --- compiler:3.13.0:testCompile (default-testCompile) @ houseprice ---
[INFO] Recompiling the module because of changed dependency.
[INFO] Compiling 3 source files with javac [debug parameters release 17] to target/test-classes
[INFO] 
[INFO] --- surefire:3.5.2:test (default-test) @ houseprice ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.example.houseprice.HousepriceApplicationTests
16:11:15.628 [main] INFO org.springframework.test.context.support.AnnotationConfigContextLoaderUtils -- Could not detect default configuration classes for test class [com.example.houseprice.HousepriceApplicationTests]: HousepriceApplicationTests does not declare any static, non-private, non-final, nested classes annotated with @Configuration.
16:11:15.725 [main] INFO org.springframework.boot.test.context.SpringBootTestContextBootstrapper -- Found @SpringBootConfiguration com.example.houseprice.HousepriceApplication for test class com.example.houseprice.HousepriceApplicationTests

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.4)

2025-04-21T16:11:16.201-07:00  INFO 11977 --- [houseprice] [           main] c.e.h.HousepriceApplicationTests         : Starting HousepriceApplicationTests using Java 17.0.15 with PID 11977 (started by tim in /Users/tim/Documents/workspace/java/houseprice)
2025-04-21T16:11:16.202-07:00  INFO 11977 --- [houseprice] [           main] c.e.h.HousepriceApplicationTests         : No active profile set, falling back to 1 default profile: "default"
2025-04-21T16:11:17.629-07:00  INFO 11977 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : RMSE: 14445.524238521559
2025-04-21T16:11:18.112-07:00  INFO 11977 --- [houseprice] [           main] c.e.h.HousepriceApplicationTests         : Started HousepriceApplicationTests in 2.216 seconds (process running for 3.192)
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 3.304 s -- in com.example.houseprice.HousepriceApplicationTests
[INFO] Running com.example.houseprice.controller.PricePredictionControllerTest
2025-04-21T16:11:18.796-07:00  INFO 11977 --- [houseprice] [           main] t.c.s.AnnotationConfigContextLoaderUtils : Could not detect default configuration classes for test class [com.example.houseprice.controller.PricePredictionControllerTest]: PricePredictionControllerTest does not declare any static, non-private, non-final, nested classes annotated with @Configuration.
2025-04-21T16:11:18.818-07:00  INFO 11977 --- [houseprice] [           main] .b.t.c.SpringBootTestContextBootstrapper : Found @SpringBootConfiguration com.example.houseprice.HousepriceApplication for test class com.example.houseprice.controller.PricePredictionControllerTest

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.4)

2025-04-21T16:11:18.857-07:00  INFO 11977 --- [houseprice] [           main] c.e.h.c.PricePredictionControllerTest    : Starting PricePredictionControllerTest using Java 17.0.15 with PID 11977 (started by tim in /Users/tim/Documents/workspace/java/houseprice)
2025-04-21T16:11:18.857-07:00  INFO 11977 --- [houseprice] [           main] c.e.h.c.PricePredictionControllerTest    : No active profile set, falling back to 1 default profile: "default"
2025-04-21T16:11:19.101-07:00  INFO 11977 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : RMSE: 10416.148020248533
2025-04-21T16:11:19.231-07:00  INFO 11977 --- [houseprice] [           main] o.s.b.t.m.w.SpringBootMockServletContext : Initializing Spring TestDispatcherServlet ''
2025-04-21T16:11:19.232-07:00  INFO 11977 --- [houseprice] [           main] o.s.t.web.servlet.TestDispatcherServlet  : Initializing Servlet ''
2025-04-21T16:11:19.234-07:00  INFO 11977 --- [houseprice] [           main] o.s.t.web.servlet.TestDispatcherServlet  : Completed initialization in 1 ms
2025-04-21T16:11:19.260-07:00  INFO 11977 --- [houseprice] [           main] c.e.h.c.PricePredictionControllerTest    : Started PricePredictionControllerTest in 0.437 seconds (process running for 4.341)
2025-04-21T16:11:19.267-07:00  INFO 11977 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Predicting for size=1800.75, bedrooms=3
2025-04-21T16:11:19.268-07:00  INFO 11977 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Prediction: 273977.51335867355
2025-04-21T16:11:19.343-07:00  INFO 11977 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Predicting for size=1800.75, bedrooms=3
2025-04-21T16:11:19.344-07:00  INFO 11977 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Prediction: 273977.51335867355
2025-04-21T16:11:19.468-07:00  INFO 11977 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Predicting for size=-100.0, bedrooms=3
2025-04-21T16:11:19.469-07:00 ERROR 11977 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Invalid input: size=-100.0, bedrooms=3
2025-04-21T16:11:19.490-07:00  INFO 11977 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Predicting for size=3000.0, bedrooms=-2
2025-04-21T16:11:19.490-07:00 ERROR 11977 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Invalid input: size=3000.0, bedrooms=-2
[INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.702 s -- in com.example.houseprice.controller.PricePredictionControllerTest
[INFO] Running com.example.houseprice.service.PricePredictionServiceTest
2025-04-21T16:11:19.500-07:00  INFO 11977 --- [houseprice] [           main] t.c.s.AnnotationConfigContextLoaderUtils : Could not detect default configuration classes for test class [com.example.houseprice.service.PricePredictionServiceTest]: PricePredictionServiceTest does not declare any static, non-private, non-final, nested classes annotated with @Configuration.
2025-04-21T16:11:19.510-07:00  INFO 11977 --- [houseprice] [           main] .b.t.c.SpringBootTestContextBootstrapper : Found @SpringBootConfiguration com.example.houseprice.HousepriceApplication for test class com.example.houseprice.service.PricePredictionServiceTest
2025-04-21T16:11:19.522-07:00  INFO 11977 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Predicting for size=1800.75, bedrooms=3
2025-04-21T16:11:19.523-07:00  INFO 11977 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Prediction: 273977.51335867355
Predicted price: 273977.51335867355
RMSE: 14445.52
2025-04-21T16:11:19.546-07:00  INFO 11977 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Predicting for size=-100.0, bedrooms=3
2025-04-21T16:11:19.547-07:00 ERROR 11977 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Invalid input: size=-100.0, bedrooms=3
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.052 s -- in com.example.houseprice.service.PricePredictionServiceTest
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 8, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] 
[INFO] --- jar:3.4.2:jar (default-jar) @ houseprice ---
[INFO] Building jar: /Users/tim/Documents/workspace/java/houseprice/target/houseprice-0.0.1-SNAPSHOT.jar
[INFO] 
[INFO] --- spring-boot:3.4.4:repackage (repackage) @ houseprice ---
[INFO] Replacing main artifact /Users/tim/Documents/workspace/java/houseprice/target/houseprice-0.0.1-SNAPSHOT.jar with repackaged archive, adding nested dependencies in BOOT-INF/.
[INFO] The original artifact has been renamed to /Users/tim/Documents/workspace/java/houseprice/target/houseprice-0.0.1-SNAPSHOT.jar.original
[INFO] 
[INFO] --- install:3.1.4:install (default-install) @ houseprice ---
[INFO] Installing /Users/tim/Documents/workspace/java/houseprice/pom.xml to /Users/tim/.m2/repository/com/example/houseprice/0.0.1-SNAPSHOT/houseprice-0.0.1-SNAPSHOT.pom
[INFO] Installing /Users/tim/Documents/workspace/java/houseprice/target/houseprice-0.0.1-SNAPSHOT.jar to /Users/tim/.m2/repository/com/example/houseprice/0.0.1-SNAPSHOT/houseprice-0.0.1-SNAPSHOT.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  9.485 s
[INFO] Finished at: 2025-04-21T16:11:21-07:00
[INFO] ------------------------------------------------------------------------

