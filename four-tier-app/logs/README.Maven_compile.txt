
sre@ubuntu:~/java_projects/book-order-app$ mvn compile
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
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 3 source files with javac [debug parameters release 21] to target/classes
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.556 s
[INFO] Finished at: 2025-02-13T19:58:43Z
[INFO] ------------------------------------------------------------------------
sre@ubuntu:~/java_projects/book-order-app$ 

sre@ubuntu:~/java_projects/book-order-app$ mvn compile
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
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 7 source files with javac [forked debug parameters release 21] to target/classes
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  3.277 s
[INFO] Finished at: 2025-02-13T21:46:27Z
[INFO] ------------------------------------------------------------------------
sre@ubuntu:~/java_projects/book-order-app$ 

sre@ubuntu:~/java_projects/book-order-app$ mvn compile
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
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.227 s
[INFO] Finished at: 2025-02-14T00:05:13Z
[INFO] ------------------------------------------------------------------------

sre@ubuntu:~/java_projects/book-order-app$ mvn compile
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
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 9 source files with javac [forked debug parameters release 21] to target/classes
[WARNING] /home/sre/java_projects/book-order-app/src/main/java/com/example/bookorderapp/config/SecurityConfig.java:[23,12] [removal] httpBasic() in HttpSecurity has been deprecated and marked for removal
[WARNING] /home/sre/java_projects/book-order-app/src/main/java/com/example/bookorderapp/config/SecurityConfig.java:[24,12] [removal] and() in SecurityConfigurerAdapter has been deprecated and marked for removal
  where B,O are type-variables:
    B extends SecurityBuilder<O> declared in class SecurityConfigurerAdapter
    O extends Object declared in class SecurityConfigurerAdapter
[WARNING] /home/sre/java_projects/book-order-app/src/main/java/com/example/bookorderapp/config/SecurityConfig.java:[25,12] [removal] formLogin() in HttpSecurity has been deprecated and marked for removal
[WARNING] /home/sre/java_projects/book-order-app/src/main/java/com/example/bookorderapp/config/SecurityConfig.java:[26,12] [removal] csrf() in HttpSecurity has been deprecated and marked for removal
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  4.658 s
[INFO] Finished at: 2025-02-17T18:46:32Z
[INFO] ------------------------------------------------------------------------

sre@ubuntu:~/java_projects/book-order-app$ mvn clean compile test-compile
[INFO] Scanning for projects...
[INFO] 
[INFO] ---------------------< com.example:book-order-app >---------------------
[INFO] Building book-order-app 0.0.1-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[WARNING] The artifact mysql:mysql-connector-java:jar:8.0.33 has been relocated to com.mysql:mysql-connector-j:jar:8.0.33: MySQL Connector/J artifacts moved to reverse-DNS compliant Maven 2+ coordinates.
[INFO] 
[INFO] --- maven-clean-plugin:3.4.0:clean (default-clean) @ book-order-app ---
[INFO] Deleting /home/sre/java_projects/book-order-app/target
[INFO] 
[INFO] --- maven-resources-plugin:3.3.1:resources (default-resources) @ book-order-app ---
[INFO] Copying 1 resource from src/main/resources to target/classes
[INFO] Copying 3 resources from src/main/resources to target/classes
[INFO] 
[INFO] --- maven-compiler-plugin:3.13.0:compile (default-compile) @ book-order-app ---
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 9 source files with javac [forked debug parameters release 21] to target/classes
[WARNING] /home/sre/java_projects/book-order-app/src/main/java/com/example/bookorderapp/config/SecurityConfig.java:[23,12] [removal] httpBasic() in HttpSecurity has been deprecated and marked for removal
[WARNING] /home/sre/java_projects/book-order-app/src/main/java/com/example/bookorderapp/config/SecurityConfig.java:[24,12] [removal] and() in SecurityConfigurerAdapter has been deprecated and marked for removal
  where B,O are type-variables:
    B extends SecurityBuilder<O> declared in class SecurityConfigurerAdapter
    O extends Object declared in class SecurityConfigurerAdapter
[WARNING] /home/sre/java_projects/book-order-app/src/main/java/com/example/bookorderapp/config/SecurityConfig.java:[25,12] [removal] formLogin() in HttpSecurity has been deprecated and marked for removal
[WARNING] /home/sre/java_projects/book-order-app/src/main/java/com/example/bookorderapp/config/SecurityConfig.java:[26,12] [removal] csrf() in HttpSecurity has been deprecated and marked for removal
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
[INFO] Recompiling the module because of changed dependency.
[INFO] Compiling 3 source files with javac [forked debug parameters release 21] to target/test-classes
[WARNING] /home/sre/java_projects/book-order-app/src/test/java/com/example/bookorderapp/controller/BookControllerTest.java:[30,5] [removal] MockBean in org.springframework.boot.test.mock.mockito has been deprecated and marked for removal
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  5.780 s
[INFO] Finished at: 2025-02-17T19:28:38Z
[INFO] ------------------------------------------------------------------------
sre@ubuntu:~/java_projects/book-order-app$ 

sre@ubuntu:~/java_projects/book-order-app$ mvn compile
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
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.460 s
[INFO] Finished at: 2025-02-17T22:04:20Z
[INFO] ------------------------------------------------------------------------

