
sre@ubuntu:~/java_projects/book-order-app$ mvn test
[INFO] Scanning for projects...
[INFO] 
[INFO] ---------------------< com.example:book-order-app >---------------------
[INFO] Building book-order-app 0.0.1-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[WARNING] The artifact mysql:mysql-connector-java:jar:8.0.33 has been relocated to com.mysql:mysql-connector-j:jar:8.0.33: MySQL Connector/J artifacts moved to reverse-DNS compliant Maven 2+ coordinates.
[INFO] 
[INFO] --- maven-resources-plugin:3.3.1:resources (default-resources) @ book-order-app ---
[INFO] Copying 1 resource from src/main/resources to target/classes
[INFO] Copying 3 resources from src/main/resources to target/classes
[INFO] 
[INFO] --- maven-compiler-plugin:3.13.0:compile (default-compile) @ book-order-app ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- maven-resources-plugin:3.3.1:testResources (default-testResources) @ book-order-app ---
[INFO] skip non existing resourceDirectory /home/sre/java_projects/book-order-app/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.13.0:testCompile (default-testCompile) @ book-order-app ---
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 3 source files with javac [forked debug parameters release 21] to target/test-classes
[WARNING] /home/sre/java_projects/book-order-app/src/test/java/com/example/bookorderapp/controller/BookControllerTest.java:[25,5] [removal] MockBean in org.springframework.boot.test.mock.mockito has been deprecated and marked for removal
[INFO] 
[INFO] --- maven-surefire-plugin:3.5.2:test (default-test) @ book-order-app ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.example.bookorderapp.service.BookServiceTest
Mockito is currently self-attaching to enable the inline-mock-maker. This will no longer work in future releases of the JDK. Please add Mockito as an agent to your build what is described in Mockito's documentation: https://javadoc.io/doc/org.mockito/mockito-core/latest/org/mockito/Mockito.html#0.3
WARNING: A Java agent has been loaded dynamically (/home/sre/.m2/repository/net/bytebuddy/byte-buddy-agent/1.15.11/byte-buddy-agent-1.15.11.jar)
WARNING: If a serviceability tool is in use, please run with -XX:+EnableDynamicAgentLoading to hide this warning
WARNING: If a serviceability tool is not in use, please run with -Djdk.instrument.traceUsage for more information
WARNING: Dynamic loading of agents will be disallowed by default in a future release
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
[INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.522 s -- in com.example.bookorderapp.service.BookServiceTest
[INFO] Running com.example.bookorderapp.controller.BookControllerTest
00:05:24.271 [main] INFO org.springframework.test.context.support.AnnotationConfigContextLoaderUtils -- Could not detect default configuration classes for test class [com.example.bookorderapp.controller.BookControllerTest]: BookControllerTest does not declare any static, non-private, non-final, nested classes annotated with @Configuration.
00:05:24.448 [main] INFO org.springframework.boot.test.context.SpringBootTestContextBootstrapper -- Found @SpringBootConfiguration com.example.bookorderapp.BookOrderApplication for test class com.example.bookorderapp.controller.BookControllerTest

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.2)

2025-02-14 00:05:25.143 [main] INFO  c.e.b.controller.BookControllerTest - Starting BookControllerTest using Java 21.0.6 with PID 6050 (started by sre in /home/sre/java_projects/book-order-app)
2025-02-14 00:05:25.146 [main] INFO  c.e.b.controller.BookControllerTest - No active profile set, falling back to 1 default profile: "default"
2025-02-14 00:05:25.165 [main] DEBUG o.s.w.c.s.GenericWebApplicationContext - Refreshing org.springframework.web.context.support.GenericWebApplicationContext@13e5d243
2025-02-14 00:05:26.461 [main] DEBUG o.s.w.s.m.m.a.RequestMappingHandlerMapping - 8 mappings in 'requestMappingHandlerMapping'
2025-02-14 00:05:26.588 [main] DEBUG o.s.w.s.h.SimpleUrlHandlerMapping - Patterns [/webjars/**, /**] in 'resourceHandlerMapping'
2025-02-14 00:05:26.647 [main] DEBUG o.s.w.s.m.m.a.RequestMappingHandlerAdapter - ControllerAdvice beans: 0 @ModelAttribute, 0 @InitBinder, 1 RequestBodyAdvice, 1 ResponseBodyAdvice
2025-02-14 00:05:26.737 [main] DEBUG o.s.w.s.m.m.a.ExceptionHandlerExceptionResolver - ControllerAdvice beans: 1 @ExceptionHandler, 1 ResponseBodyAdvice
2025-02-14 00:05:26.792 [main] INFO  o.s.b.t.m.w.SpringBootMockServletContext - Initializing Spring TestDispatcherServlet ''
2025-02-14 00:05:26.793 [main] INFO  o.s.t.w.s.TestDispatcherServlet - Initializing Servlet ''
2025-02-14 00:05:26.802 [main] INFO  o.s.t.w.s.TestDispatcherServlet - Completed initialization in 8 ms
2025-02-14 00:05:26.879 [main] INFO  c.e.b.controller.BookControllerTest - Started BookControllerTest in 2.362 seconds (process running for 5.142)
2025-02-14 00:05:26.953 [main] DEBUG o.s.w.s.m.m.a.RequestMappingHandlerMapping - Mapped to com.example.bookorderapp.controller.BookController#addBook(Book)
2025-02-14 00:05:27.004 [main] DEBUG o.s.web.servlet.view.RedirectView - View name [redirect:], model {}
2025-02-14 00:05:27.028 [main] DEBUG o.s.w.s.m.m.a.RequestMappingHandlerMapping - Mapped to com.example.bookorderapp.controller.BookController#showAddForm(Model)
2025-02-14 00:05:27.035 [main] DEBUG o.s.w.s.v.ContentNegotiatingViewResolver - Selected '*/*' given [*/*]
2025-02-14 00:05:27.315 [main] DEBUG o.s.w.s.m.m.a.RequestMappingHandlerMapping - Mapped to com.example.bookorderapp.controller.BookController#showUpdateForm(long, Model)
2025-02-14 00:05:27.320 [main] DEBUG o.s.w.s.m.m.a.ExceptionHandlerExceptionResolver - Using @ExceptionHandler com.example.bookorderapp.exceptions.GlobalExceptionHandler#handleBookNotFoundException(BookNotFoundException)
2025-02-14 00:05:27.382 [main] DEBUG o.s.w.s.m.m.a.HttpEntityMethodProcessor - Using 'application/json', given [*/*] and supported [application/json, application/*+json]
2025-02-14 00:05:27.384 [main] DEBUG o.s.w.s.m.m.a.HttpEntityMethodProcessor - Writing [com.example.bookorderapp.exceptions.ErrorResponse@2aa811f9]
2025-02-14 00:05:27.393 [main] DEBUG o.s.w.s.m.m.a.ExceptionHandlerExceptionResolver - Resolved [com.example.bookorderapp.exceptions.BookNotFoundException: Book with ID:1 not found]
2025-02-14 00:05:27.406 [main] DEBUG o.s.w.s.m.m.a.RequestMappingHandlerMapping - Mapped to com.example.bookorderapp.controller.BookController#updateBook(long, Book)
2025-02-14 00:05:27.409 [main] DEBUG o.s.web.servlet.view.RedirectView - View name [redirect:], model {}
2025-02-14 00:05:27.418 [main] DEBUG o.s.w.s.m.m.a.RequestMappingHandlerMapping - Mapped to com.example.bookorderapp.controller.BookController#listBooks(Model)
2025-02-14 00:05:27.420 [main] DEBUG o.s.w.s.v.ContentNegotiatingViewResolver - Selected '*/*' given [*/*]
2025-02-14 00:05:27.482 [main] DEBUG o.s.w.s.m.m.a.RequestMappingHandlerMapping - Mapped to com.example.bookorderapp.controller.BookController#showUpdateForm(long, Model)
2025-02-14 00:05:27.484 [main] DEBUG o.s.w.s.v.ContentNegotiatingViewResolver - Selected '*/*' given [*/*]
2025-02-14 00:05:27.503 [main] DEBUG o.s.w.s.m.m.a.RequestMappingHandlerMapping - Mapped to com.example.bookorderapp.controller.BookController#deleteBook(long)
2025-02-14 00:05:27.505 [main] DEBUG o.s.web.servlet.view.RedirectView - View name [redirect:], model {}
[INFO] Tests run: 7, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 3.466 s -- in com.example.bookorderapp.controller.BookControllerTest
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 11, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  10.088 s
[INFO] Finished at: 2025-02-14T00:05:27Z
[INFO] ------------------------------------------------------------------------

