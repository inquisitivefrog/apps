
tim@Tims-MBP houseprice % mvn dependency:resolve
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------------------< com.example:houseprice >-----------------------
[INFO] Building houseprice 0.0.1-SNAPSHOT
[INFO]   from pom.xml
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- dependency:3.8.1:resolve (default-cli) @ houseprice ---
[INFO] 
[INFO] The following files have been resolved:
[INFO]    org.springframework.boot:spring-boot-starter:jar:3.4.4:compile -- module spring.boot.starter [auto]
[INFO]    org.springframework.boot:spring-boot:jar:3.4.4:compile -- module spring.boot [auto]
[INFO]    org.springframework:spring-context:jar:6.2.5:compile -- module spring.context [auto]
[INFO]    org.springframework.boot:spring-boot-autoconfigure:jar:3.4.4:compile -- module spring.boot.autoconfigure [auto]
[INFO]    org.springframework.boot:spring-boot-starter-logging:jar:3.4.4:compile -- module spring.boot.starter.logging [auto]
[INFO]    ch.qos.logback:logback-classic:jar:1.5.18:compile -- module ch.qos.logback.classic
[INFO]    ch.qos.logback:logback-core:jar:1.5.18:compile -- module ch.qos.logback.core
[INFO]    org.apache.logging.log4j:log4j-to-slf4j:jar:2.24.3:compile -- module org.apache.logging.log4j.to.slf4j
[INFO]    org.apache.logging.log4j:log4j-api:jar:2.24.3:compile -- module org.apache.logging.log4j
[INFO]    org.slf4j:jul-to-slf4j:jar:2.0.17:compile -- module jul.to.slf4j
[INFO]    jakarta.annotation:jakarta.annotation-api:jar:2.1.1:compile -- module jakarta.annotation
[INFO]    org.springframework:spring-core:jar:6.2.5:compile -- module spring.core [auto]
[INFO]    org.springframework:spring-jcl:jar:6.2.5:compile -- module spring.jcl [auto]
[INFO]    org.yaml:snakeyaml:jar:2.3:compile -- module org.yaml.snakeyaml
[INFO]    org.springframework.boot:spring-boot-starter-test:jar:3.4.4:test -- module spring.boot.starter.test [auto]
[INFO]    org.springframework.boot:spring-boot-test:jar:3.4.4:test -- module spring.boot.test [auto]
[INFO]    org.springframework.boot:spring-boot-test-autoconfigure:jar:3.4.4:test -- module spring.boot.test.autoconfigure [auto]
[INFO]    com.jayway.jsonpath:json-path:jar:2.9.0:test -- module json.path [auto]
[INFO]    jakarta.xml.bind:jakarta.xml.bind-api:jar:4.0.2:test -- module jakarta.xml.bind
[INFO]    jakarta.activation:jakarta.activation-api:jar:2.1.3:test -- module jakarta.activation
[INFO]    net.minidev:json-smart:jar:2.5.2:test -- module json.smart (auto)
[INFO]    net.minidev:accessors-smart:jar:2.5.2:test -- module accessors.smart (auto)
[INFO]    org.ow2.asm:asm:jar:9.7.1:test -- module org.objectweb.asm
[INFO]    org.assertj:assertj-core:jar:3.26.3:test -- module org.assertj.core
[INFO]    net.bytebuddy:byte-buddy:jar:1.15.11:test -- module net.bytebuddy
[INFO]    org.awaitility:awaitility:jar:4.2.2:test -- module awaitility (auto)
[INFO]    org.hamcrest:hamcrest:jar:2.2:test -- module org.hamcrest [auto]
[INFO]    org.junit.jupiter:junit-jupiter:jar:5.11.4:test -- module org.junit.jupiter
[INFO]    org.junit.jupiter:junit-jupiter-api:jar:5.11.4:test -- module org.junit.jupiter.api
[INFO]    org.opentest4j:opentest4j:jar:1.3.0:test -- module org.opentest4j
[INFO]    org.junit.platform:junit-platform-commons:jar:1.11.4:test -- module org.junit.platform.commons
[INFO]    org.apiguardian:apiguardian-api:jar:1.1.2:test -- module org.apiguardian.api
[INFO]    org.junit.jupiter:junit-jupiter-params:jar:5.11.4:test -- module org.junit.jupiter.params
[INFO]    org.junit.jupiter:junit-jupiter-engine:jar:5.11.4:test -- module org.junit.jupiter.engine
[INFO]    org.junit.platform:junit-platform-engine:jar:1.11.4:test -- module org.junit.platform.engine
[INFO]    org.mockito:mockito-core:jar:5.14.2:test -- module org.mockito [auto]
[INFO]    net.bytebuddy:byte-buddy-agent:jar:1.15.11:test -- module net.bytebuddy.agent
[INFO]    org.objenesis:objenesis:jar:3.3:test -- module org.objenesis [auto]
[INFO]    org.mockito:mockito-junit-jupiter:jar:5.14.2:test -- module org.mockito.junit.jupiter [auto]
[INFO]    org.skyscreamer:jsonassert:jar:1.5.3:test -- module jsonassert (auto)
[INFO]    com.vaadin.external.google:android-json:jar:0.0.20131108.vaadin1:test -- module android.json (auto)
[INFO]    org.springframework:spring-test:jar:6.2.5:test -- module spring.test [auto]
[INFO]    org.xmlunit:xmlunit-core:jar:2.10.0:test -- module org.xmlunit [auto]
[INFO]    org.springframework.boot:spring-boot-starter-web:jar:3.4.4:compile -- module spring.boot.starter.web [auto]
[INFO]    org.springframework.boot:spring-boot-starter-json:jar:3.4.4:compile -- module spring.boot.starter.json [auto]
[INFO]    com.fasterxml.jackson.core:jackson-databind:jar:2.18.3:compile -- module com.fasterxml.jackson.databind
[INFO]    com.fasterxml.jackson.core:jackson-annotations:jar:2.18.3:compile -- module com.fasterxml.jackson.annotation
[INFO]    com.fasterxml.jackson.core:jackson-core:jar:2.18.3:compile -- module com.fasterxml.jackson.core
[INFO]    com.fasterxml.jackson.datatype:jackson-datatype-jdk8:jar:2.18.3:compile -- module com.fasterxml.jackson.datatype.jdk8
[INFO]    com.fasterxml.jackson.datatype:jackson-datatype-jsr310:jar:2.18.3:compile -- module com.fasterxml.jackson.datatype.jsr310
[INFO]    com.fasterxml.jackson.module:jackson-module-parameter-names:jar:2.18.3:compile -- module com.fasterxml.jackson.module.paramnames
[INFO]    org.springframework.boot:spring-boot-starter-tomcat:jar:3.4.4:compile -- module spring.boot.starter.tomcat [auto]
[INFO]    org.apache.tomcat.embed:tomcat-embed-core:jar:10.1.39:compile -- module org.apache.tomcat.embed.core
[INFO]    org.apache.tomcat.embed:tomcat-embed-el:jar:10.1.39:compile -- module org.apache.tomcat.embed.el
[INFO]    org.apache.tomcat.embed:tomcat-embed-websocket:jar:10.1.39:compile -- module org.apache.tomcat.embed.websocket
[INFO]    org.springframework:spring-web:jar:6.2.5:compile -- module spring.web [auto]
[INFO]    org.springframework:spring-beans:jar:6.2.5:compile -- module spring.beans [auto]
[INFO]    io.micrometer:micrometer-observation:jar:1.14.5:compile -- module micrometer.observation [auto]
[INFO]    io.micrometer:micrometer-commons:jar:1.14.5:compile -- module micrometer.commons [auto]
[INFO]    org.springframework:spring-webmvc:jar:6.2.5:compile -- module spring.webmvc [auto]
[INFO]    org.springframework:spring-aop:jar:6.2.5:compile -- module spring.aop [auto]
[INFO]    org.springframework:spring-expression:jar:6.2.5:compile -- module spring.expression [auto]
[INFO]    com.github.haifengl:smile-core:jar:3.1.1:compile -- module smile.core [auto]
[INFO]    com.github.haifengl:smile-base:jar:3.1.1:compile -- module smile.base [auto]
[INFO]    org.bytedeco:javacpp:jar:linux-x86_64:1.5.10:compile -- module org.bytedeco.javacpp.linux.x86_64
[INFO]    org.bytedeco:javacpp:jar:windows-x86_64:1.5.10:compile -- module org.bytedeco.javacpp.windows.x86_64
[INFO]    org.bytedeco:javacpp:jar:macosx-x86_64:1.5.10:compile -- module org.bytedeco.javacpp.macosx.x86_64
[INFO]    org.bytedeco:javacpp:jar:macosx-arm64:1.5.10:compile -- module org.bytedeco.javacpp.macosx.arm64
[INFO]    org.bytedeco:openblas:jar:linux-x86_64:0.3.26-1.5.10:compile -- module org.bytedeco.openblas.linux.x86_64
[INFO]    org.bytedeco:javacpp:jar:1.5.10:compile -- module org.bytedeco.javacpp
[INFO]    org.bytedeco:openblas:jar:windows-x86_64:0.3.26-1.5.10:compile -- module org.bytedeco.openblas.windows.x86_64
[INFO]    org.bytedeco:openblas:jar:macosx-x86_64:0.3.26-1.5.10:compile -- module org.bytedeco.openblas.macosx.x86_64
[INFO]    org.bytedeco:openblas:jar:macosx-arm64:0.3.26-1.5.10:compile -- module org.bytedeco.openblas.macosx.arm64
[INFO]    org.bytedeco:arpack-ng:jar:3.9.1-1.5.10:compile -- module org.bytedeco.arpackng
[INFO]    org.bytedeco:openblas:jar:0.3.26-1.5.10:compile -- module org.bytedeco.openblas
[INFO]    org.bytedeco:arpack-ng:jar:linux-x86_64:3.9.1-1.5.10:compile -- module org.bytedeco.arpackng.linux.x86_64
[INFO]    org.bytedeco:arpack-ng:jar:windows-x86_64:3.9.1-1.5.10:compile -- module org.bytedeco.arpackng.windows.x86_64
[INFO]    org.bytedeco:arpack-ng:jar:macosx-x86_64:3.9.1-1.5.10:compile -- module org.bytedeco.arpackng.macosx.x86_64
[INFO]    com.epam:parso:jar:2.0.14:compile -- module parso (auto)
[INFO]    org.apache.commons:commons-csv:jar:1.10.0:compile -- module org.apache.commons.csv [auto]
[INFO]    org.slf4j:slf4j-api:jar:2.0.17:compile -- module org.slf4j
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.895 s
[INFO] Finished at: 2025-04-21T16:14:58-07:00
[INFO] ------------------------------------------------------------------------
tim@Tims-MBP houseprice % which java
/usr/local/Cellar/openjdk@17/17.0.15/libexec/openjdk.jdk/Contents/Home/bin/java
tim@Tims-MBP houseprice % java -version
openjdk version "17.0.15" 2025-04-15
OpenJDK Runtime Environment Homebrew (build 17.0.15+0)
OpenJDK 64-Bit Server VM Homebrew (build 17.0.15+0, mixed mode, sharing)
tim@Tims-MBP houseprice % which mvn
/usr/local/bin/mvn
tim@Tims-MBP houseprice % mvn -version
Apache Maven 3.9.9 (8e8579a9e76f7d015ee5ec7bfcdc97d260186937)
Maven home: /usr/local/Cellar/maven/3.9.9/libexec
Java version: 17.0.15, vendor: Homebrew, runtime: /usr/local/Cellar/openjdk@17/17.0.15/libexec/openjdk.jdk/Contents/Home
Default locale: en_US, platform encoding: UTF-8
OS name: "mac os x", version: "13.7.1", arch: "x86_64", family: "mac"

