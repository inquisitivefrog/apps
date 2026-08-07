
tim@Tims-MBP simple-app % mvn archetype:generate -DgroupId=com.simple.apps -DartifactId=myapp -DarchetypeArtifactId=maven-archetype-quickstart -DarchetypeVersion=1.5 -DinteractiveMode=false
[INFO] Scanning for projects...
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-metadata.xml
Downloading from central: https://repo.maven.apache.org/maven2/org/codehaus/mojo/maven-metadata.xml
Downloaded from central: https://repo.maven.apache.org/maven2/org/codehaus/mojo/maven-metadata.xml (21 kB at 64 kB/s)
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-metadata.xml (14 kB at 44 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-archetype-plugin/maven-metadata.xml
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-archetype-plugin/maven-metadata.xml (1.0 kB at 87 kB/s)
[INFO] 
[INFO] ------------------< org.apache.maven:standalone-pom >-------------------
[INFO] Building Maven Stub Project (No POM) 1
[INFO] --------------------------------[ pom ]---------------------------------
[INFO] 
[INFO] >>> archetype:3.3.1:generate (default-cli) > generate-sources @ standalone-pom >>>
[INFO] 
[INFO] <<< archetype:3.3.1:generate (default-cli) < generate-sources @ standalone-pom <<<
[INFO] 
[INFO] 
[INFO] --- archetype:3.3.1:generate (default-cli) @ standalone-pom ---
[INFO] Generating project in Batch mode
Downloading from central: https://repo.maven.apache.org/maven2/archetype-catalog.xml
Downloaded from central: https://repo.maven.apache.org/maven2/archetype-catalog.xml (16 MB at 5.7 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/archetypes/maven-archetype-quickstart/1.5/maven-archetype-quickstart-1.5.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/archetypes/maven-archetype-quickstart/1.5/maven-archetype-quickstart-1.5.jar (11 kB at 764 kB/s)
[INFO] ----------------------------------------------------------------------------
[INFO] Using following parameters for creating project from Archetype: maven-archetype-quickstart:1.5
[INFO] ----------------------------------------------------------------------------
[INFO] Parameter: groupId, Value: com.simple.apps
[INFO] Parameter: artifactId, Value: myapp
[INFO] Parameter: version, Value: 1.0-SNAPSHOT
[INFO] Parameter: package, Value: com.simple.apps
[INFO] Parameter: packageInPathFormat, Value: com/simple/apps
[INFO] Parameter: junitVersion, Value: 5.11.0
[INFO] Parameter: package, Value: com.simple.apps
[INFO] Parameter: groupId, Value: com.simple.apps
[INFO] Parameter: artifactId, Value: myapp
[INFO] Parameter: javaCompilerVersion, Value: 17
[INFO] Parameter: version, Value: 1.0-SNAPSHOT
[WARNING] Don't override file /Users/tim/Documents/workspace/java/myapp/src/main/java/com/simple/apps
[WARNING] Don't override file /Users/tim/Documents/workspace/java/myapp/src/test/java/com/simple/apps
[WARNING] CP Don't override file /Users/tim/Documents/workspace/java/myapp/.mvn
[INFO] Project created from Archetype in dir: /Users/tim/Documents/workspace/java/myapp
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  5.036 s
[INFO] Finished at: 2025-02-05T10:09:24-08:00
[INFO] ------------------------------------------------------------------------
tim@Tims-MBP java % 

tim@Tims-MBP simple-app % find myapp 
myapp
myapp/pom.xml
myapp/.mvn
myapp/.mvn/maven.config
myapp/.mvn/jvm.config
myapp/src
myapp/src/test
myapp/src/test/java
myapp/src/test/java/com
myapp/src/test/java/com/simple
myapp/src/test/java/com/simple/apps
myapp/src/test/java/com/simple/apps/AppTest.java
myapp/src/main
myapp/src/main/java
myapp/src/main/java/com
myapp/src/main/java/com/simple
myapp/src/main/java/com/simple/apps
myapp/src/main/java/com/simple/apps/App.java

tim@Tims-MBP simple-app % cd myapp 

tim@Tims-MBP myapp % vi pom.xml 
tim@Tims-MBP myapp % cat pom.xml 
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.simple.apps</groupId>
  <artifactId>myapp</artifactId>
  <version>1.0-SNAPSHOT</version>

  <name>myapp</name>
  <!-- FIXME change it to the project's website -->
  <url>http://www.example.com</url>

  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <maven.compiler.release>17</maven.compiler.release>
  </properties>

  <parent>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-parent</artifactId>
      <version>2.7.0</version>
  </parent>

  <dependencyManagement>
    <dependencies>
      <dependency>
          <groupId>org.springframework.boot</groupId>
          <artifactId>spring-boot-starter-web</artifactId>
      </dependency>
      <dependency>
          <groupId>org.springframework.boot</groupId>
          <artifactId>spring-boot-starter-data-jpa</artifactId>
      </dependency>
      <dependency>
          <groupId>mysql</groupId>
          <artifactId>mysql-connector-java</artifactId>
      </dependency>

      <dependency>
        <groupId>org.junit</groupId>
        <artifactId>junit-bom</artifactId>
        <version>5.11.0</version>
        <type>pom</type>
        <scope>import</scope>
      </dependency>

    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-api</artifactId>
      <scope>test</scope>
    </dependency>
    <!-- Optionally: parameterized tests support -->
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-params</artifactId>
      <scope>test</scope>
    </dependency>
  </dependencies>
  </dependencyManagement>

  <build>
    <pluginManagement><!-- lock down plugins versions to avoid using Maven defaults (may be moved to parent pom) -->
      <plugins>
        <!-- clean lifecycle, see https://maven.apache.org/ref/current/maven-core/lifecycles.html#clean_Lifecycle -->
        <plugin>
          <artifactId>maven-clean-plugin</artifactId>
          <version>3.4.0</version>
        </plugin>
        <!-- default lifecycle, jar packaging: see https://maven.apache.org/ref/current/maven-core/default-bindings.html#Plugin_bindings_for_jar_packaging -->
        <plugin>
          <artifactId>maven-resources-plugin</artifactId>
          <version>3.3.1</version>
        </plugin>
        <plugin>
          <artifactId>maven-compiler-plugin</artifactId>
          <version>3.13.0</version>
        </plugin>
        <plugin>
          <artifactId>maven-surefire-plugin</artifactId>
          <version>3.3.0</version>
        </plugin>
        <plugin>
          <artifactId>maven-jar-plugin</artifactId>
          <version>3.4.2</version>
        </plugin>
        <plugin>
          <artifactId>maven-install-plugin</artifactId>
          <version>3.1.2</version>
        </plugin>
        <plugin>
          <artifactId>maven-deploy-plugin</artifactId>
          <version>3.1.2</version>
        </plugin>
        <!-- site lifecycle, see https://maven.apache.org/ref/current/maven-core/lifecycles.html#site_Lifecycle -->
        <plugin>
          <artifactId>maven-site-plugin</artifactId>
          <version>3.12.1</version>
        </plugin>
        <plugin>
          <artifactId>maven-project-info-reports-plugin</artifactId>
          <version>3.6.1</version>
        </plugin>
      </plugins>
    </pluginManagement>
  </build>
</project>

tim@Tims-MBP myapp % mvn clean 
[INFO] Scanning for projects...
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-parent/2.7.0/spring-boot-starter-parent-2.7.0.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-parent/2.7.0/spring-boot-starter-parent-2.7.0.pom (8.6 kB at 30 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-dependencies/2.7.0/spring-boot-dependencies-2.7.0.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-dependencies/2.7.0/spring-boot-dependencies-2.7.0.pom (109 kB at 2.9 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/datastax/oss/java-driver-bom/4.14.1/java-driver-bom-4.14.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/datastax/oss/java-driver-bom/4.14.1/java-driver-bom-4.14.1.pom (4.1 kB at 461 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/io/dropwizard/metrics/metrics-bom/4.2.9/metrics-bom-4.2.9.pom
Downloaded from central: https://repo.maven.apache.org/maven2/io/dropwizard/metrics/metrics-bom/4.2.9/metrics-bom-4.2.9.pom (6.9 kB at 625 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/io/dropwizard/metrics/metrics-parent/4.2.9/metrics-parent-4.2.9.pom
Downloaded from central: https://repo.maven.apache.org/maven2/io/dropwizard/metrics/metrics-parent/4.2.9/metrics-parent-4.2.9.pom (20 kB at 1.6 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/codehaus/groovy/groovy-bom/3.0.10/groovy-bom-3.0.10.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/codehaus/groovy/groovy-bom/3.0.10/groovy-bom-3.0.10.pom (26 kB at 1.9 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/infinispan/infinispan-bom/13.0.10.Final/infinispan-bom-13.0.10.Final.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/infinispan/infinispan-bom/13.0.10.Final/infinispan-bom-13.0.10.Final.pom (19 kB at 1.3 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/infinispan/infinispan-build-configuration-parent/13.0.10.Final/infinispan-build-configuration-parent-13.0.10.Final.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/infinispan/infinispan-build-configuration-parent/13.0.10.Final/infinispan-build-configuration-parent-13.0.10.Final.pom (13 kB at 831 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/jboss/jboss-parent/36/jboss-parent-36.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/jboss/jboss-parent/36/jboss-parent-36.pom (66 kB at 3.0 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/jackson-bom/2.13.3/jackson-bom-2.13.3.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/jackson-bom/2.13.3/jackson-bom-2.13.3.pom (17 kB at 1.4 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/jackson-parent/2.13/jackson-parent-2.13.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/jackson-parent/2.13/jackson-parent-2.13.pom (7.4 kB at 742 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/oss-parent/43/oss-parent-43.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/oss-parent/43/oss-parent-43.pom (24 kB at 2.0 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/glassfish/jersey/jersey-bom/2.35/jersey-bom-2.35.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/glassfish/jersey/jersey-bom/2.35/jersey-bom-2.35.pom (19 kB at 1.4 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/eclipse/ee4j/project/1.0.6/project-1.0.6.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/eclipse/ee4j/project/1.0.6/project-1.0.6.pom (13 kB at 1.2 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/eclipse/jetty/jetty-bom/9.4.46.v20220331/jetty-bom-9.4.46.v20220331.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/eclipse/jetty/jetty-bom/9.4.46.v20220331/jetty-bom-9.4.46.v20220331.pom (18 kB at 1.5 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/jetbrains/kotlin/kotlin-bom/1.6.21/kotlin-bom-1.6.21.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/jetbrains/kotlin/kotlin-bom/1.6.21/kotlin-bom-1.6.21.pom (9.3 kB at 1.0 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-coroutines-bom/1.6.1/kotlinx-coroutines-bom-1.6.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/jetbrains/kotlinx/kotlinx-coroutines-bom/1.6.1/kotlinx-coroutines-bom-1.6.1.pom (4.3 kB at 477 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/logging/log4j/log4j-bom/2.17.2/log4j-bom-2.17.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/logging/log4j/log4j-bom/2.17.2/log4j-bom-2.17.2.pom (8.1 kB at 737 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/io/micrometer/micrometer-bom/1.9.0/micrometer-bom-1.9.0.pom
Downloaded from central: https://repo.maven.apache.org/maven2/io/micrometer/micrometer-bom/1.9.0/micrometer-bom-1.9.0.pom (7.1 kB at 706 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/mockito/mockito-bom/4.5.1/mockito-bom-4.5.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/mockito/mockito-bom/4.5.1/mockito-bom-4.5.1.pom (3.0 kB at 426 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/io/netty/netty-bom/4.1.77.Final/netty-bom-4.1.77.Final.pom
Downloaded from central: https://repo.maven.apache.org/maven2/io/netty/netty-bom/4.1.77.Final/netty-bom-4.1.77.Final.pom (13 kB at 1.3 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/squareup/okhttp3/okhttp-bom/4.9.3/okhttp-bom-4.9.3.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/squareup/okhttp3/okhttp-bom/4.9.3/okhttp-bom-4.9.3.pom (3.0 kB at 338 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/oracle/database/jdbc/ojdbc-bom/21.5.0.0/ojdbc-bom-21.5.0.0.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/oracle/database/jdbc/ojdbc-bom/21.5.0.0/ojdbc-bom-21.5.0.0.pom (13 kB at 973 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/io/prometheus/simpleclient_bom/0.15.0/simpleclient_bom-0.15.0.pom
Downloaded from central: https://repo.maven.apache.org/maven2/io/prometheus/simpleclient_bom/0.15.0/simpleclient_bom-0.15.0.pom (5.8 kB at 724 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/io/prometheus/parent/0.15.0/parent-0.15.0.pom
Downloaded from central: https://repo.maven.apache.org/maven2/io/prometheus/parent/0.15.0/parent-0.15.0.pom (12 kB at 1.2 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/io/r2dbc/r2dbc-bom/Borca-SR1/r2dbc-bom-Borca-SR1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/io/r2dbc/r2dbc-bom/Borca-SR1/r2dbc-bom-Borca-SR1.pom (3.8 kB at 426 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/io/projectreactor/reactor-bom/2020.0.19/reactor-bom-2020.0.19.pom
Downloaded from central: https://repo.maven.apache.org/maven2/io/projectreactor/reactor-bom/2020.0.19/reactor-bom-2020.0.19.pom (4.6 kB at 460 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/io/rsocket/rsocket-bom/1.1.2/rsocket-bom-1.1.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/io/rsocket/rsocket-bom/1.1.2/rsocket-bom-1.1.2.pom (2.6 kB at 240 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/data/spring-data-bom/2021.2.0/spring-data-bom-2021.2.0.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/data/spring-data-bom/2021.2.0/spring-data-bom-2021.2.0.pom (5.7 kB at 406 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-framework-bom/5.3.20/spring-framework-bom-5.3.20.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-framework-bom/5.3.20/spring-framework-bom-5.3.20.pom (5.7 kB at 628 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/integration/spring-integration-bom/5.5.12/spring-integration-bom-5.5.12.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/integration/spring-integration-bom/5.5.12/spring-integration-bom-5.5.12.pom (9.2 kB at 918 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-bom/5.7.1/spring-security-bom-5.7.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-bom/5.7.1/spring-security-bom-5.7.1.pom (5.7 kB at 570 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/session/spring-session-bom/2021.2.0/spring-session-bom-2021.2.0.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/session/spring-session-bom/2021.2.0/spring-session-bom-2021.2.0.pom (3.1 kB at 386 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/junit/junit-bom/5.8.2/junit-bom-5.8.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/junit/junit-bom/5.8.2/junit-bom-5.8.2.pom (5.6 kB at 469 kB/s)
[INFO] 
[INFO] -----------------------< com.simple.apps:myapp >------------------------
[INFO] Building myapp 1.0-SNAPSHOT
[INFO]   from pom.xml
[INFO] --------------------------------[ jar ]---------------------------------
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-clean-plugin/3.4.0/maven-clean-plugin-3.4.0.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-clean-plugin/3.4.0/maven-clean-plugin-3.4.0.pom (5.5 kB at 606 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-clean-plugin/3.4.0/maven-clean-plugin-3.4.0.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-clean-plugin/3.4.0/maven-clean-plugin-3.4.0.jar (36 kB at 3.0 MB/s)
[INFO] 
[INFO] --- clean:3.4.0:clean (default-clean) @ myapp ---
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.423 s
[INFO] Finished at: 2025-02-05T10:22:55-08:00
[INFO] ------------------------------------------------------------------------

