tim@Tims-MBP houseprice % mvn test
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
16:18:31.245 [main] INFO org.springframework.test.context.support.AnnotationConfigContextLoaderUtils -- Could not detect default configuration classes for test class [com.example.houseprice.HousepriceApplicationTests]: HousepriceApplicationTests does not declare any static, non-private, non-final, nested classes annotated with @Configuration.
16:18:31.347 [main] INFO org.springframework.boot.test.context.SpringBootTestContextBootstrapper -- Found @SpringBootConfiguration com.example.houseprice.HousepriceApplication for test class com.example.houseprice.HousepriceApplicationTests

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.4)

2025-04-21T16:18:31.731-07:00  INFO 12134 --- [houseprice] [           main] c.e.h.HousepriceApplicationTests         : Starting HousepriceApplicationTests using Java 17.0.15 with PID 12134 (started by tim in /Users/tim/Documents/workspace/java/houseprice)
2025-04-21T16:18:31.732-07:00  INFO 12134 --- [houseprice] [           main] c.e.h.HousepriceApplicationTests         : No active profile set, falling back to 1 default profile: "default"
2025-04-21T16:18:32.813-07:00  INFO 12134 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : RMSE: 14445.524238521559
2025-04-21T16:18:33.191-07:00  INFO 12134 --- [houseprice] [           main] c.e.h.HousepriceApplicationTests         : Started HousepriceApplicationTests in 1.714 seconds (process running for 2.605)
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 2.746 s -- in com.example.houseprice.HousepriceApplicationTests
[INFO] Running com.example.houseprice.controller.PricePredictionControllerTest
2025-04-21T16:18:33.868-07:00  INFO 12134 --- [houseprice] [           main] t.c.s.AnnotationConfigContextLoaderUtils : Could not detect default configuration classes for test class [com.example.houseprice.controller.PricePredictionControllerTest]: PricePredictionControllerTest does not declare any static, non-private, non-final, nested classes annotated with @Configuration.
2025-04-21T16:18:33.890-07:00  INFO 12134 --- [houseprice] [           main] .b.t.c.SpringBootTestContextBootstrapper : Found @SpringBootConfiguration com.example.houseprice.HousepriceApplication for test class com.example.houseprice.controller.PricePredictionControllerTest

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.4)

2025-04-21T16:18:33.923-07:00  INFO 12134 --- [houseprice] [           main] c.e.h.c.PricePredictionControllerTest    : Starting PricePredictionControllerTest using Java 17.0.15 with PID 12134 (started by tim in /Users/tim/Documents/workspace/java/houseprice)
2025-04-21T16:18:33.923-07:00  INFO 12134 --- [houseprice] [           main] c.e.h.c.PricePredictionControllerTest    : No active profile set, falling back to 1 default profile: "default"
2025-04-21T16:18:34.097-07:00  INFO 12134 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : RMSE: 10416.148020248533
2025-04-21T16:18:34.241-07:00  INFO 12134 --- [houseprice] [           main] o.s.b.t.m.w.SpringBootMockServletContext : Initializing Spring TestDispatcherServlet ''
2025-04-21T16:18:34.241-07:00  INFO 12134 --- [houseprice] [           main] o.s.t.web.servlet.TestDispatcherServlet  : Initializing Servlet ''
2025-04-21T16:18:34.244-07:00  INFO 12134 --- [houseprice] [           main] o.s.t.web.servlet.TestDispatcherServlet  : Completed initialization in 1 ms
2025-04-21T16:18:34.258-07:00  INFO 12134 --- [houseprice] [           main] c.e.h.c.PricePredictionControllerTest    : Started PricePredictionControllerTest in 0.363 seconds (process running for 3.672)
2025-04-21T16:18:34.265-07:00  INFO 12134 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Predicting for size=1800.75, bedrooms=3
2025-04-21T16:18:34.266-07:00  INFO 12134 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Prediction: 273977.51335867355
2025-04-21T16:18:34.337-07:00  INFO 12134 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Predicting for size=1800.75, bedrooms=3
2025-04-21T16:18:34.337-07:00  INFO 12134 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Prediction: 273977.51335867355
2025-04-21T16:18:34.451-07:00  INFO 12134 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Predicting for size=-100.0, bedrooms=3
2025-04-21T16:18:34.451-07:00 ERROR 12134 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Invalid input: size=-100.0, bedrooms=3
2025-04-21T16:18:34.471-07:00  INFO 12134 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Predicting for size=3000.0, bedrooms=-2
2025-04-21T16:18:34.471-07:00 ERROR 12134 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Invalid input: size=3000.0, bedrooms=-2
[INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.612 s -- in com.example.houseprice.controller.PricePredictionControllerTest
[INFO] Running com.example.houseprice.service.PricePredictionServiceTest
2025-04-21T16:18:34.481-07:00  INFO 12134 --- [houseprice] [           main] t.c.s.AnnotationConfigContextLoaderUtils : Could not detect default configuration classes for test class [com.example.houseprice.service.PricePredictionServiceTest]: PricePredictionServiceTest does not declare any static, non-private, non-final, nested classes annotated with @Configuration.
2025-04-21T16:18:34.490-07:00  INFO 12134 --- [houseprice] [           main] .b.t.c.SpringBootTestContextBootstrapper : Found @SpringBootConfiguration com.example.houseprice.HousepriceApplication for test class com.example.houseprice.service.PricePredictionServiceTest
2025-04-21T16:18:34.499-07:00  INFO 12134 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Predicting for size=1800.75, bedrooms=3
2025-04-21T16:18:34.500-07:00  INFO 12134 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Prediction: 273977.51335867355
Predicted price: 273977.51335867355
RMSE: 14445.52
2025-04-21T16:18:34.517-07:00  INFO 12134 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Predicting for size=-100.0, bedrooms=3
2025-04-21T16:18:34.517-07:00 ERROR 12134 --- [houseprice] [           main] c.e.h.service.PricePredictionService     : Invalid input: size=-100.0, bedrooms=3
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.045 s -- in com.example.houseprice.service.PricePredictionServiceTest
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 8, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  5.371 s
[INFO] Finished at: 2025-04-21T16:18:34-07:00
[INFO] ------------------------------------------------------------------------

