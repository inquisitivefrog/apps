
sre@ubuntu:~/java_projects/book-order-app$ vi pom.xml 
sre@ubuntu:~/java_projects/book-order-app$ mvn dependency:resolve
[INFO] Scanning for projects...
[INFO] 
[INFO] ---------------------< com.example:book-order-app >---------------------
[INFO] Building book-order-app 0.0.1-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
Downloading from central: https://repo.maven.apache.org/maven2/mysql/mysql-connector-java/8.0.33/mysql-connector-java-8.0.33.pom
Downloaded from central: https://repo.maven.apache.org/maven2/mysql/mysql-connector-java/8.0.33/mysql-connector-java-8.0.33.pom (2.1 kB at 4.6 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.pom (3.2 kB at 88 kB/s)
[WARNING] The artifact mysql:mysql-connector-java:jar:8.0.33 has been relocated to com.mysql:mysql-connector-j:jar:8.0.33: MySQL Connector/J artifacts moved to reverse-DNS compliant Maven 2+ coordinates.
Downloading from central: https://repo.maven.apache.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar
Downloaded from central: https://repo.maven.apache.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar (2.5 MB at 4.9 MB/s)
[INFO] 
[INFO] --- maven-dependency-plugin:3.8.1:resolve (default-cli) @ book-order-app ---
[INFO] 
[INFO] The following files have been resolved:
[INFO]    org.springframework.boot:spring-boot-starter-web:jar:3.4.2:compile -- module spring.boot.starter.web [auto]
[INFO]    org.springframework.boot:spring-boot-starter:jar:3.4.2:compile -- module spring.boot.starter [auto]
[INFO]    org.springframework.boot:spring-boot:jar:3.4.2:compile -- module spring.boot [auto]
[INFO]    org.springframework.boot:spring-boot-autoconfigure:jar:3.4.2:compile -- module spring.boot.autoconfigure [auto]
[INFO]    org.springframework.boot:spring-boot-starter-logging:jar:3.4.2:compile -- module spring.boot.starter.logging [auto]
[INFO]    ch.qos.logback:logback-classic:jar:1.5.16:compile -- module ch.qos.logback.classic
[INFO]    ch.qos.logback:logback-core:jar:1.5.16:compile -- module ch.qos.logback.core
[INFO]    org.apache.logging.log4j:log4j-to-slf4j:jar:2.24.3:compile -- module org.apache.logging.log4j.to.slf4j
[INFO]    org.apache.logging.log4j:log4j-api:jar:2.24.3:compile -- module org.apache.logging.log4j
[INFO]    org.slf4j:jul-to-slf4j:jar:2.0.16:compile -- module jul.to.slf4j
[INFO]    jakarta.annotation:jakarta.annotation-api:jar:2.1.1:compile -- module jakarta.annotation
[INFO]    org.yaml:snakeyaml:jar:2.3:compile -- module org.yaml.snakeyaml
[INFO]    org.springframework.boot:spring-boot-starter-json:jar:3.4.2:compile -- module spring.boot.starter.json [auto]
[INFO]    com.fasterxml.jackson.core:jackson-databind:jar:2.18.2:compile -- module com.fasterxml.jackson.databind
[INFO]    com.fasterxml.jackson.core:jackson-annotations:jar:2.18.2:compile -- module com.fasterxml.jackson.annotation
[INFO]    com.fasterxml.jackson.core:jackson-core:jar:2.18.2:compile -- module com.fasterxml.jackson.core
[INFO]    com.fasterxml.jackson.datatype:jackson-datatype-jdk8:jar:2.18.2:compile -- module com.fasterxml.jackson.datatype.jdk8
[INFO]    com.fasterxml.jackson.datatype:jackson-datatype-jsr310:jar:2.18.2:compile -- module com.fasterxml.jackson.datatype.jsr310
[INFO]    com.fasterxml.jackson.module:jackson-module-parameter-names:jar:2.18.2:compile -- module com.fasterxml.jackson.module.paramnames
[INFO]    org.springframework.boot:spring-boot-starter-tomcat:jar:3.4.2:compile -- module spring.boot.starter.tomcat [auto]
[INFO]    org.apache.tomcat.embed:tomcat-embed-core:jar:10.1.34:compile -- module org.apache.tomcat.embed.core
[INFO]    org.apache.tomcat.embed:tomcat-embed-el:jar:10.1.34:compile -- module org.apache.tomcat.embed.el
[INFO]    org.apache.tomcat.embed:tomcat-embed-websocket:jar:10.1.34:compile -- module org.apache.tomcat.embed.websocket
[INFO]    org.springframework:spring-web:jar:6.2.2:compile -- module spring.web [auto]
[INFO]    org.springframework:spring-beans:jar:6.2.2:compile -- module spring.beans [auto]
[INFO]    io.micrometer:micrometer-observation:jar:1.14.3:compile -- module micrometer.observation [auto]
[INFO]    io.micrometer:micrometer-commons:jar:1.14.3:compile -- module micrometer.commons [auto]
[INFO]    org.springframework:spring-webmvc:jar:6.2.2:compile -- module spring.webmvc [auto]
[INFO]    org.springframework:spring-aop:jar:6.2.2:compile -- module spring.aop [auto]
[INFO]    org.springframework:spring-context:jar:6.2.2:compile -- module spring.context [auto]
[INFO]    org.springframework:spring-expression:jar:6.2.2:compile -- module spring.expression [auto]
[INFO]    org.springframework.boot:spring-boot-starter-thymeleaf:jar:3.4.2:compile -- module spring.boot.starter.thymeleaf [auto]
[INFO]    org.thymeleaf:thymeleaf-spring6:jar:3.1.3.RELEASE:compile -- module thymeleaf.spring6 [auto]
[INFO]    org.thymeleaf:thymeleaf:jar:3.1.3.RELEASE:compile -- module thymeleaf [auto]
[INFO]    org.attoparser:attoparser:jar:2.0.7.RELEASE:compile -- module attoparser [auto]
[INFO]    org.unbescape:unbescape:jar:1.1.6.RELEASE:compile -- module unbescape [auto]
[INFO]    org.slf4j:slf4j-api:jar:2.0.16:compile -- module org.slf4j
[INFO]    org.springframework.boot:spring-boot-starter-data-jpa:jar:3.4.2:compile -- module spring.boot.starter.data.jpa [auto]
[INFO]    org.springframework.boot:spring-boot-starter-jdbc:jar:3.4.2:compile -- module spring.boot.starter.jdbc [auto]
[INFO]    com.zaxxer:HikariCP:jar:5.1.0:compile -- module com.zaxxer.hikari
[INFO]    org.springframework:spring-jdbc:jar:6.2.2:compile -- module spring.jdbc [auto]
[INFO]    org.hibernate.orm:hibernate-core:jar:6.6.5.Final:compile -- module org.hibernate.orm.core [auto]
[INFO]    jakarta.persistence:jakarta.persistence-api:jar:3.1.0:compile -- module jakarta.persistence
[INFO]    jakarta.transaction:jakarta.transaction-api:jar:2.0.1:compile -- module jakarta.transaction
[INFO]    org.jboss.logging:jboss-logging:jar:3.6.1.Final:runtime -- module org.jboss.logging
[INFO]    org.hibernate.common:hibernate-commons-annotations:jar:7.0.3.Final:runtime -- module org.hibernate.commons.annotations
[INFO]    io.smallrye:jandex:jar:3.2.0:runtime -- module org.jboss.jandex [auto]
[INFO]    com.fasterxml:classmate:jar:1.7.0:runtime -- module com.fasterxml.classmate
[INFO]    net.bytebuddy:byte-buddy:jar:1.15.11:runtime -- module net.bytebuddy
[INFO]    org.glassfish.jaxb:jaxb-runtime:jar:4.0.5:runtime -- module org.glassfish.jaxb.runtime
[INFO]    org.glassfish.jaxb:jaxb-core:jar:4.0.5:runtime -- module org.glassfish.jaxb.core
[INFO]    org.eclipse.angus:angus-activation:jar:2.0.2:runtime -- module org.eclipse.angus.activation
[INFO]    org.glassfish.jaxb:txw2:jar:4.0.5:runtime -- module com.sun.xml.txw2
[INFO]    com.sun.istack:istack-commons-runtime:jar:4.1.2:runtime -- module com.sun.istack.runtime
[INFO]    jakarta.inject:jakarta.inject-api:jar:2.0.1:runtime -- module jakarta.inject
[INFO]    org.antlr:antlr4-runtime:jar:4.13.0:compile -- module org.antlr.antlr4.runtime [auto]
[INFO]    org.springframework.data:spring-data-jpa:jar:3.4.2:compile -- module spring.data.jpa [auto]
[INFO]    org.springframework.data:spring-data-commons:jar:3.4.2:compile -- module spring.data.commons [auto]
[INFO]    org.springframework:spring-orm:jar:6.2.2:compile -- module spring.orm [auto]
[INFO]    org.springframework:spring-tx:jar:6.2.2:compile -- module spring.tx [auto]
[INFO]    org.springframework:spring-aspects:jar:6.2.2:compile -- module spring.aspects [auto]
[INFO]    org.aspectj:aspectjweaver:jar:1.9.22.1:compile -- module org.aspectj.weaver [auto]
[INFO]    com.mysql:mysql-connector-j:jar:8.0.33:compile -- module mysql.connector.j (auto)
[INFO]    org.springframework.boot:spring-boot-starter-test:jar:3.4.2:test -- module spring.boot.starter.test [auto]
[INFO]    org.springframework.boot:spring-boot-test:jar:3.4.2:test -- module spring.boot.test [auto]
[INFO]    org.springframework.boot:spring-boot-test-autoconfigure:jar:3.4.2:test -- module spring.boot.test.autoconfigure [auto]
[INFO]    com.jayway.jsonpath:json-path:jar:2.9.0:test -- module json.path [auto]
[INFO]    jakarta.xml.bind:jakarta.xml.bind-api:jar:4.0.2:runtime -- module jakarta.xml.bind
[INFO]    jakarta.activation:jakarta.activation-api:jar:2.1.3:runtime -- module jakarta.activation
[INFO]    net.minidev:json-smart:jar:2.5.1:test -- module json.smart (auto)
[INFO]    net.minidev:accessors-smart:jar:2.5.1:test -- module accessors.smart (auto)
[INFO]    org.ow2.asm:asm:jar:9.6:test -- module org.objectweb.asm
[INFO]    org.assertj:assertj-core:jar:3.26.3:test -- module org.assertj.core
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
[INFO]    org.springframework:spring-core:jar:6.2.2:compile -- module spring.core [auto]
[INFO]    org.springframework:spring-jcl:jar:6.2.2:compile -- module spring.jcl [auto]
[INFO]    org.springframework:spring-test:jar:6.2.2:test -- module spring.test [auto]
[INFO]    org.xmlunit:xmlunit-core:jar:2.10.0:test -- module org.xmlunit [auto]
[INFO]    junit:junit:jar:3.8.1:test -- module junit (auto)
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  4.132 s
[INFO] Finished at: 2025-02-13T19:57:12Z
[INFO] ------------------------------------------------------------------------
sre@ubuntu:~/java_projects/book-order-app$ 

sre@ubuntu:~/java_projects/book-order-app$ mvn dependency:resolve
[INFO] Scanning for projects...
[WARNING] 
[WARNING] Some problems were encountered while building the effective model for com.example:book-order-app:jar:0.0.1-SNAPSHOT
[WARNING] 'build.plugins.plugin.(groupId:artifactId)' must be unique but found duplicate declaration of plugin org.springframework.boot:spring-boot-maven-plugin @ line 58, column 15
[WARNING] 
[WARNING] It is highly recommended to fix these problems because they threaten the stability of your build.
[WARNING] 
[WARNING] For this reason, future Maven versions might no longer support building such malformed projects.
[WARNING] 
[INFO] 
[INFO] ---------------------< com.example:book-order-app >---------------------
[INFO] Building book-order-app 0.0.1-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[WARNING] The artifact mysql:mysql-connector-java:jar:8.0.33 has been relocated to com.mysql:mysql-connector-j:jar:8.0.33: MySQL Connector/J artifacts moved to reverse-DNS compliant Maven 2+ coordinates.
[INFO] 
[INFO] --- maven-dependency-plugin:3.8.1:resolve (default-cli) @ book-order-app ---
[INFO] 
[INFO] The following files have been resolved:
[INFO]    org.springframework.boot:spring-boot-starter-web:jar:3.4.2:compile -- module spring.boot.starter.web [auto]
[INFO]    org.springframework.boot:spring-boot-starter:jar:3.4.2:compile -- module spring.boot.starter [auto]
[INFO]    org.springframework.boot:spring-boot:jar:3.4.2:compile -- module spring.boot [auto]
[INFO]    org.springframework.boot:spring-boot-autoconfigure:jar:3.4.2:compile -- module spring.boot.autoconfigure [auto]
[INFO]    org.springframework.boot:spring-boot-starter-logging:jar:3.4.2:compile -- module spring.boot.starter.logging [auto]
[INFO]    ch.qos.logback:logback-classic:jar:1.5.16:compile -- module ch.qos.logback.classic
[INFO]    ch.qos.logback:logback-core:jar:1.5.16:compile -- module ch.qos.logback.core
[INFO]    org.apache.logging.log4j:log4j-to-slf4j:jar:2.24.3:compile -- module org.apache.logging.log4j.to.slf4j
[INFO]    org.apache.logging.log4j:log4j-api:jar:2.24.3:compile -- module org.apache.logging.log4j
[INFO]    org.slf4j:jul-to-slf4j:jar:2.0.16:compile -- module jul.to.slf4j
[INFO]    jakarta.annotation:jakarta.annotation-api:jar:2.1.1:compile -- module jakarta.annotation
[INFO]    org.yaml:snakeyaml:jar:2.3:compile -- module org.yaml.snakeyaml
[INFO]    org.springframework.boot:spring-boot-starter-json:jar:3.4.2:compile -- module spring.boot.starter.json [auto]
[INFO]    com.fasterxml.jackson.core:jackson-databind:jar:2.18.2:compile -- module com.fasterxml.jackson.databind
[INFO]    com.fasterxml.jackson.core:jackson-annotations:jar:2.18.2:compile -- module com.fasterxml.jackson.annotation
[INFO]    com.fasterxml.jackson.core:jackson-core:jar:2.18.2:compile -- module com.fasterxml.jackson.core
[INFO]    com.fasterxml.jackson.datatype:jackson-datatype-jdk8:jar:2.18.2:compile -- module com.fasterxml.jackson.datatype.jdk8
[INFO]    com.fasterxml.jackson.datatype:jackson-datatype-jsr310:jar:2.18.2:compile -- module com.fasterxml.jackson.datatype.jsr310
[INFO]    com.fasterxml.jackson.module:jackson-module-parameter-names:jar:2.18.2:compile -- module com.fasterxml.jackson.module.paramnames
[INFO]    org.springframework.boot:spring-boot-starter-tomcat:jar:3.4.2:compile -- module spring.boot.starter.tomcat [auto]
[INFO]    org.apache.tomcat.embed:tomcat-embed-core:jar:10.1.34:compile -- module org.apache.tomcat.embed.core
[INFO]    org.apache.tomcat.embed:tomcat-embed-el:jar:10.1.34:compile -- module org.apache.tomcat.embed.el
[INFO]    org.apache.tomcat.embed:tomcat-embed-websocket:jar:10.1.34:compile -- module org.apache.tomcat.embed.websocket
[INFO]    org.springframework:spring-web:jar:6.2.2:compile -- module spring.web [auto]
[INFO]    org.springframework:spring-beans:jar:6.2.2:compile -- module spring.beans [auto]
[INFO]    io.micrometer:micrometer-observation:jar:1.14.3:compile -- module micrometer.observation [auto]
[INFO]    io.micrometer:micrometer-commons:jar:1.14.3:compile -- module micrometer.commons [auto]
[INFO]    org.springframework:spring-webmvc:jar:6.2.2:compile -- module spring.webmvc [auto]
[INFO]    org.springframework:spring-aop:jar:6.2.2:compile -- module spring.aop [auto]
[INFO]    org.springframework:spring-context:jar:6.2.2:compile -- module spring.context [auto]
[INFO]    org.springframework:spring-expression:jar:6.2.2:compile -- module spring.expression [auto]
[INFO]    org.springframework.boot:spring-boot-starter-thymeleaf:jar:3.4.2:compile -- module spring.boot.starter.thymeleaf [auto]
[INFO]    org.thymeleaf:thymeleaf-spring6:jar:3.1.3.RELEASE:compile -- module thymeleaf.spring6 [auto]
[INFO]    org.thymeleaf:thymeleaf:jar:3.1.3.RELEASE:compile -- module thymeleaf [auto]
[INFO]    org.attoparser:attoparser:jar:2.0.7.RELEASE:compile -- module attoparser [auto]
[INFO]    org.unbescape:unbescape:jar:1.1.6.RELEASE:compile -- module unbescape [auto]
[INFO]    org.slf4j:slf4j-api:jar:2.0.16:compile -- module org.slf4j
[INFO]    org.springframework.boot:spring-boot-starter-data-jpa:jar:3.4.2:compile -- module spring.boot.starter.data.jpa [auto]
[INFO]    org.springframework.boot:spring-boot-starter-jdbc:jar:3.4.2:compile -- module spring.boot.starter.jdbc [auto]
[INFO]    com.zaxxer:HikariCP:jar:5.1.0:compile -- module com.zaxxer.hikari
[INFO]    org.springframework:spring-jdbc:jar:6.2.2:compile -- module spring.jdbc [auto]
[INFO]    org.hibernate.orm:hibernate-core:jar:6.6.5.Final:compile -- module org.hibernate.orm.core [auto]
[INFO]    jakarta.persistence:jakarta.persistence-api:jar:3.1.0:compile -- module jakarta.persistence
[INFO]    jakarta.transaction:jakarta.transaction-api:jar:2.0.1:compile -- module jakarta.transaction
[INFO]    org.jboss.logging:jboss-logging:jar:3.6.1.Final:runtime -- module org.jboss.logging
[INFO]    org.hibernate.common:hibernate-commons-annotations:jar:7.0.3.Final:runtime -- module org.hibernate.commons.annotations
[INFO]    io.smallrye:jandex:jar:3.2.0:runtime -- module org.jboss.jandex [auto]
[INFO]    com.fasterxml:classmate:jar:1.7.0:runtime -- module com.fasterxml.classmate
[INFO]    net.bytebuddy:byte-buddy:jar:1.15.11:runtime -- module net.bytebuddy
[INFO]    org.glassfish.jaxb:jaxb-runtime:jar:4.0.5:runtime -- module org.glassfish.jaxb.runtime
[INFO]    org.glassfish.jaxb:jaxb-core:jar:4.0.5:runtime -- module org.glassfish.jaxb.core
[INFO]    org.eclipse.angus:angus-activation:jar:2.0.2:runtime -- module org.eclipse.angus.activation
[INFO]    org.glassfish.jaxb:txw2:jar:4.0.5:runtime -- module com.sun.xml.txw2
[INFO]    com.sun.istack:istack-commons-runtime:jar:4.1.2:runtime -- module com.sun.istack.runtime
[INFO]    jakarta.inject:jakarta.inject-api:jar:2.0.1:runtime -- module jakarta.inject
[INFO]    org.antlr:antlr4-runtime:jar:4.13.0:compile -- module org.antlr.antlr4.runtime [auto]
[INFO]    org.springframework.data:spring-data-jpa:jar:3.4.2:compile -- module spring.data.jpa [auto]
[INFO]    org.springframework.data:spring-data-commons:jar:3.4.2:compile -- module spring.data.commons [auto]
[INFO]    org.springframework:spring-orm:jar:6.2.2:compile -- module spring.orm [auto]
[INFO]    org.springframework:spring-tx:jar:6.2.2:compile -- module spring.tx [auto]
[INFO]    org.springframework:spring-aspects:jar:6.2.2:compile -- module spring.aspects [auto]
[INFO]    org.aspectj:aspectjweaver:jar:1.9.22.1:compile -- module org.aspectj.weaver [auto]
[INFO]    com.mysql:mysql-connector-j:jar:8.0.33:compile -- module mysql.connector.j (auto)
[INFO]    org.springframework.boot:spring-boot-starter-test:jar:3.4.2:test -- module spring.boot.starter.test [auto]
[INFO]    org.springframework.boot:spring-boot-test:jar:3.4.2:test -- module spring.boot.test [auto]
[INFO]    org.springframework.boot:spring-boot-test-autoconfigure:jar:3.4.2:test -- module spring.boot.test.autoconfigure [auto]
[INFO]    com.jayway.jsonpath:json-path:jar:2.9.0:test -- module json.path [auto]
[INFO]    jakarta.xml.bind:jakarta.xml.bind-api:jar:4.0.2:runtime -- module jakarta.xml.bind
[INFO]    jakarta.activation:jakarta.activation-api:jar:2.1.3:runtime -- module jakarta.activation
[INFO]    net.minidev:json-smart:jar:2.5.1:test -- module json.smart (auto)
[INFO]    net.minidev:accessors-smart:jar:2.5.1:test -- module accessors.smart (auto)
[INFO]    org.ow2.asm:asm:jar:9.6:test -- module org.objectweb.asm
[INFO]    org.assertj:assertj-core:jar:3.26.3:test -- module org.assertj.core
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
[INFO]    org.springframework:spring-core:jar:6.2.2:compile -- module spring.core [auto]
[INFO]    org.springframework:spring-jcl:jar:6.2.2:compile -- module spring.jcl [auto]
[INFO]    org.springframework:spring-test:jar:6.2.2:test -- module spring.test [auto]
[INFO]    org.xmlunit:xmlunit-core:jar:2.10.0:test -- module org.xmlunit [auto]
[INFO]    junit:junit:jar:3.8.1:test -- module junit (auto)
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.030 s
[INFO] Finished at: 2025-02-13T20:04:18Z
[INFO] ------------------------------------------------------------------------
sre@ubuntu:~/java_projects/book-order-app$ 

sre@ubuntu:~/java_projects/book-order-app$ mvn dependency:purge-local-repository
[INFO] Scanning for projects...
[INFO] 
[INFO] ---------------------< com.example:book-order-app >---------------------
[INFO] Building book-order-app 0.0.1-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-dependency-plugin:3.8.1:purge-local-repository (default-cli) @ book-order-app ---
[INFO] Deleting 70 transitive dependencies for project book-order-app from /home/sre/.m2/repository with artifact version resolution fuzziness
[INFO] Re-resolving dependencies
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-web/3.4.2/spring-boot-starter-web-3.4.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-web/3.4.2/spring-boot-starter-web-3.4.2.pom (2.9 kB at 4.6 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-web/3.4.2/spring-boot-starter-web-3.4.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-web/3.4.2/spring-boot-starter-web-3.4.2.jar (4.8 kB at 166 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter/3.4.2/spring-boot-starter-3.4.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter/3.4.2/spring-boot-starter-3.4.2.pom (3.0 kB at 127 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter/3.4.2/spring-boot-starter-3.4.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter/3.4.2/spring-boot-starter-3.4.2.jar (4.8 kB at 217 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot/3.4.2/spring-boot-3.4.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot/3.4.2/spring-boot-3.4.2.pom (2.2 kB at 91 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot/3.4.2/spring-boot-3.4.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot/3.4.2/spring-boot-3.4.2.jar (1.8 MB at 4.2 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-autoconfigure/3.4.2/spring-boot-autoconfigure-3.4.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-autoconfigure/3.4.2/spring-boot-autoconfigure-3.4.2.pom (2.1 kB at 94 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-autoconfigure/3.4.2/spring-boot-autoconfigure-3.4.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-autoconfigure/3.4.2/spring-boot-autoconfigure-3.4.2.jar (2.0 MB at 4.8 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-logging/3.4.2/spring-boot-starter-logging-3.4.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-logging/3.4.2/spring-boot-starter-logging-3.4.2.pom (2.5 kB at 112 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-logging/3.4.2/spring-boot-starter-logging-3.4.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-logging/3.4.2/spring-boot-starter-logging-3.4.2.jar (4.8 kB at 207 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/ch/qos/logback/logback-classic/1.5.16/logback-classic-1.5.16.pom
Downloaded from central: https://repo.maven.apache.org/maven2/ch/qos/logback/logback-classic/1.5.16/logback-classic-1.5.16.pom (13 kB at 500 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/ch/qos/logback/logback-classic/1.5.16/logback-classic-1.5.16.jar
Downloaded from central: https://repo.maven.apache.org/maven2/ch/qos/logback/logback-classic/1.5.16/logback-classic-1.5.16.jar (307 kB at 3.6 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/ch/qos/logback/logback-core/1.5.16/logback-core-1.5.16.pom
Downloaded from central: https://repo.maven.apache.org/maven2/ch/qos/logback/logback-core/1.5.16/logback-core-1.5.16.pom (7.9 kB at 360 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/ch/qos/logback/logback-core/1.5.16/logback-core-1.5.16.jar
Downloaded from central: https://repo.maven.apache.org/maven2/ch/qos/logback/logback-core/1.5.16/logback-core-1.5.16.jar (622 kB at 3.7 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/logging/log4j/log4j-to-slf4j/2.24.3/log4j-to-slf4j-2.24.3.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/logging/log4j/log4j-to-slf4j/2.24.3/log4j-to-slf4j-2.24.3.pom (5.0 kB at 229 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/logging/log4j/log4j-to-slf4j/2.24.3/log4j-to-slf4j-2.24.3.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/logging/log4j/log4j-to-slf4j/2.24.3/log4j-to-slf4j-2.24.3.jar (24 kB at 1.1 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/logging/log4j/log4j-api/2.24.3/log4j-api-2.24.3.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/logging/log4j/log4j-api/2.24.3/log4j-api-2.24.3.pom (4.4 kB at 259 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/logging/log4j/log4j-api/2.24.3/log4j-api-2.24.3.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/logging/log4j/log4j-api/2.24.3/log4j-api-2.24.3.jar (349 kB at 3.8 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/slf4j/jul-to-slf4j/2.0.16/jul-to-slf4j-2.0.16.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/slf4j/jul-to-slf4j/2.0.16/jul-to-slf4j-2.0.16.pom (1.1 kB at 44 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/slf4j/jul-to-slf4j/2.0.16/jul-to-slf4j-2.0.16.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/slf4j/jul-to-slf4j/2.0.16/jul-to-slf4j-2.0.16.jar (6.4 kB at 334 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/jakarta/annotation/jakarta.annotation-api/2.1.1/jakarta.annotation-api-2.1.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/jakarta/annotation/jakarta.annotation-api/2.1.1/jakarta.annotation-api-2.1.1.pom (16 kB at 752 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/jakarta/annotation/jakarta.annotation-api/2.1.1/jakarta.annotation-api-2.1.1.jar
Downloaded from central: https://repo.maven.apache.org/maven2/jakarta/annotation/jakarta.annotation-api/2.1.1/jakarta.annotation-api-2.1.1.jar (26 kB at 1.0 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-core/6.2.2/spring-core-6.2.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-core/6.2.2/spring-core-6.2.2.pom (2.0 kB at 112 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-core/6.2.2/spring-core-6.2.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-core/6.2.2/spring-core-6.2.2.jar (2.0 MB at 5.3 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-jcl/6.2.2/spring-jcl-6.2.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-jcl/6.2.2/spring-jcl-6.2.2.pom (1.8 kB at 97 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-jcl/6.2.2/spring-jcl-6.2.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-jcl/6.2.2/spring-jcl-6.2.2.jar (25 kB at 1.0 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/yaml/snakeyaml/2.3/snakeyaml-2.3.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/yaml/snakeyaml/2.3/snakeyaml-2.3.pom (22 kB at 804 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/yaml/snakeyaml/2.3/snakeyaml-2.3.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/yaml/snakeyaml/2.3/snakeyaml-2.3.jar (342 kB at 3.8 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-json/3.4.2/spring-boot-starter-json-3.4.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-json/3.4.2/spring-boot-starter-json-3.4.2.pom (3.1 kB at 134 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-json/3.4.2/spring-boot-starter-json-3.4.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-json/3.4.2/spring-boot-starter-json-3.4.2.jar (4.7 kB at 198 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-databind/2.18.2/jackson-databind-2.18.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-databind/2.18.2/jackson-databind-2.18.2.pom (21 kB at 1.0 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-databind/2.18.2/jackson-databind-2.18.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-databind/2.18.2/jackson-databind-2.18.2.jar (1.7 MB at 5.2 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-annotations/2.18.2/jackson-annotations-2.18.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-annotations/2.18.2/jackson-annotations-2.18.2.pom (7.1 kB at 338 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-annotations/2.18.2/jackson-annotations-2.18.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-annotations/2.18.2/jackson-annotations-2.18.2.jar (78 kB at 2.6 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-core/2.18.2/jackson-core-2.18.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-core/2.18.2/jackson-core-2.18.2.pom (10 kB at 455 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-core/2.18.2/jackson-core-2.18.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/core/jackson-core/2.18.2/jackson-core-2.18.2.jar (598 kB at 4.8 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/datatype/jackson-datatype-jdk8/2.18.2/jackson-datatype-jdk8-2.18.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/datatype/jackson-datatype-jdk8/2.18.2/jackson-datatype-jdk8-2.18.2.pom (2.6 kB at 118 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/datatype/jackson-datatype-jdk8/2.18.2/jackson-datatype-jdk8-2.18.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/datatype/jackson-datatype-jdk8/2.18.2/jackson-datatype-jdk8-2.18.2.jar (36 kB at 1.6 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/datatype/jackson-datatype-jsr310/2.18.2/jackson-datatype-jsr310-2.18.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/datatype/jackson-datatype-jsr310/2.18.2/jackson-datatype-jsr310-2.18.2.pom (4.9 kB at 258 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/datatype/jackson-datatype-jsr310/2.18.2/jackson-datatype-jsr310-2.18.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/datatype/jackson-datatype-jsr310/2.18.2/jackson-datatype-jsr310-2.18.2.jar (133 kB at 2.9 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/module/jackson-module-parameter-names/2.18.2/jackson-module-parameter-names-2.18.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/module/jackson-module-parameter-names/2.18.2/jackson-module-parameter-names-2.18.2.pom (4.2 kB at 192 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/module/jackson-module-parameter-names/2.18.2/jackson-module-parameter-names-2.18.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/jackson/module/jackson-module-parameter-names/2.18.2/jackson-module-parameter-names-2.18.2.jar (10 kB at 383 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-tomcat/3.4.2/spring-boot-starter-tomcat-3.4.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-tomcat/3.4.2/spring-boot-starter-tomcat-3.4.2.pom (3.1 kB at 136 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-tomcat/3.4.2/spring-boot-starter-tomcat-3.4.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-tomcat/3.4.2/spring-boot-starter-tomcat-3.4.2.jar (4.8 kB at 218 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/tomcat/embed/tomcat-embed-core/10.1.34/tomcat-embed-core-10.1.34.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/tomcat/embed/tomcat-embed-core/10.1.34/tomcat-embed-core-10.1.34.pom (1.7 kB at 102 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/tomcat/embed/tomcat-embed-core/10.1.34/tomcat-embed-core-10.1.34.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/tomcat/embed/tomcat-embed-core/10.1.34/tomcat-embed-core-10.1.34.jar (3.6 MB at 5.6 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/tomcat/embed/tomcat-embed-websocket/10.1.34/tomcat-embed-websocket-10.1.34.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/tomcat/embed/tomcat-embed-websocket/10.1.34/tomcat-embed-websocket-10.1.34.pom (1.7 kB at 79 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/tomcat/embed/tomcat-embed-websocket/10.1.34/tomcat-embed-websocket-10.1.34.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/tomcat/embed/tomcat-embed-websocket/10.1.34/tomcat-embed-websocket-10.1.34.jar (282 kB at 4.1 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-web/6.2.2/spring-web-6.2.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-web/6.2.2/spring-web-6.2.2.pom (2.4 kB at 141 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-web/6.2.2/spring-web-6.2.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-web/6.2.2/spring-web-6.2.2.jar (2.1 MB at 5.5 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-beans/6.2.2/spring-beans-6.2.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-beans/6.2.2/spring-beans-6.2.2.pom (2.0 kB at 135 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-beans/6.2.2/spring-beans-6.2.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-beans/6.2.2/spring-beans-6.2.2.jar (877 kB at 5.2 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/io/micrometer/micrometer-observation/1.14.3/micrometer-observation-1.14.3.pom
Downloaded from central: https://repo.maven.apache.org/maven2/io/micrometer/micrometer-observation/1.14.3/micrometer-observation-1.14.3.pom (3.8 kB at 213 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/io/micrometer/micrometer-observation/1.14.3/micrometer-observation-1.14.3.jar
Downloaded from central: https://repo.maven.apache.org/maven2/io/micrometer/micrometer-observation/1.14.3/micrometer-observation-1.14.3.jar (75 kB at 2.6 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/io/micrometer/micrometer-commons/1.14.3/micrometer-commons-1.14.3.pom
Downloaded from central: https://repo.maven.apache.org/maven2/io/micrometer/micrometer-commons/1.14.3/micrometer-commons-1.14.3.pom (3.4 kB at 162 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/io/micrometer/micrometer-commons/1.14.3/micrometer-commons-1.14.3.jar
Downloaded from central: https://repo.maven.apache.org/maven2/io/micrometer/micrometer-commons/1.14.3/micrometer-commons-1.14.3.jar (48 kB at 2.0 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-webmvc/6.2.2/spring-webmvc-6.2.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-webmvc/6.2.2/spring-webmvc-6.2.2.pom (3.0 kB at 156 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-webmvc/6.2.2/spring-webmvc-6.2.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-webmvc/6.2.2/spring-webmvc-6.2.2.jar (1.1 MB at 5.3 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-aop/6.2.2/spring-aop-6.2.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-aop/6.2.2/spring-aop-6.2.2.pom (2.2 kB at 130 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-aop/6.2.2/spring-aop-6.2.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-aop/6.2.2/spring-aop-6.2.2.jar (418 kB at 4.4 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-context/6.2.2/spring-context-6.2.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-context/6.2.2/spring-context-6.2.2.pom (2.8 kB at 174 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-context/6.2.2/spring-context-6.2.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-context/6.2.2/spring-context-6.2.2.jar (1.4 MB at 5.3 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-expression/6.2.2/spring-expression-6.2.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-expression/6.2.2/spring-expression-6.2.2.pom (2.1 kB at 109 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-expression/6.2.2/spring-expression-6.2.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-expression/6.2.2/spring-expression-6.2.2.jar (318 kB at 4.1 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-thymeleaf/3.4.2/spring-boot-starter-thymeleaf-3.4.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-thymeleaf/3.4.2/spring-boot-starter-thymeleaf-3.4.2.pom (2.3 kB at 49 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-thymeleaf/3.4.2/spring-boot-starter-thymeleaf-3.4.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-thymeleaf/3.4.2/spring-boot-starter-thymeleaf-3.4.2.jar (4.8 kB at 318 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/thymeleaf/thymeleaf-spring6/3.1.3.RELEASE/thymeleaf-spring6-3.1.3.RELEASE.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/thymeleaf/thymeleaf-spring6/3.1.3.RELEASE/thymeleaf-spring6-3.1.3.RELEASE.pom (4.6 kB at 258 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/thymeleaf/thymeleaf-spring6/3.1.3.RELEASE/thymeleaf-spring6-3.1.3.RELEASE.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/thymeleaf/thymeleaf-spring6/3.1.3.RELEASE/thymeleaf-spring6-3.1.3.RELEASE.jar (189 kB at 3.6 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/thymeleaf/thymeleaf/3.1.3.RELEASE/thymeleaf-3.1.3.RELEASE.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/thymeleaf/thymeleaf/3.1.3.RELEASE/thymeleaf-3.1.3.RELEASE.pom (4.0 kB at 174 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/thymeleaf/thymeleaf/3.1.3.RELEASE/thymeleaf-3.1.3.RELEASE.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/thymeleaf/thymeleaf/3.1.3.RELEASE/thymeleaf-3.1.3.RELEASE.jar (939 kB at 5.1 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/attoparser/attoparser/2.0.7.RELEASE/attoparser-2.0.7.RELEASE.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/attoparser/attoparser/2.0.7.RELEASE/attoparser-2.0.7.RELEASE.pom (11 kB at 589 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/attoparser/attoparser/2.0.7.RELEASE/attoparser-2.0.7.RELEASE.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/attoparser/attoparser/2.0.7.RELEASE/attoparser-2.0.7.RELEASE.jar (246 kB at 4.1 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/unbescape/unbescape/1.1.6.RELEASE/unbescape-1.1.6.RELEASE.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/unbescape/unbescape/1.1.6.RELEASE/unbescape-1.1.6.RELEASE.pom (10.0 kB at 524 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/unbescape/unbescape/1.1.6.RELEASE/unbescape-1.1.6.RELEASE.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/unbescape/unbescape/1.1.6.RELEASE/unbescape-1.1.6.RELEASE.jar (174 kB at 3.2 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/slf4j/slf4j-api/2.0.16/slf4j-api-2.0.16.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/slf4j/slf4j-api/2.0.16/slf4j-api-2.0.16.pom (2.8 kB at 177 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/slf4j/slf4j-api/2.0.16/slf4j-api-2.0.16.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/slf4j/slf4j-api/2.0.16/slf4j-api-2.0.16.jar (69 kB at 1.5 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-data-jpa/3.4.2/spring-boot-starter-data-jpa-3.4.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-data-jpa/3.4.2/spring-boot-starter-data-jpa-3.4.2.pom (2.9 kB at 159 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-data-jpa/3.4.2/spring-boot-starter-data-jpa-3.4.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-data-jpa/3.4.2/spring-boot-starter-data-jpa-3.4.2.jar (4.8 kB at 280 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-jdbc/3.4.2/spring-boot-starter-jdbc-3.4.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-jdbc/3.4.2/spring-boot-starter-jdbc-3.4.2.pom (2.5 kB at 153 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-jdbc/3.4.2/spring-boot-starter-jdbc-3.4.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-jdbc/3.4.2/spring-boot-starter-jdbc-3.4.2.jar (4.8 kB at 227 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/zaxxer/HikariCP/5.1.0/HikariCP-5.1.0.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/zaxxer/HikariCP/5.1.0/HikariCP-5.1.0.pom (26 kB at 900 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/zaxxer/HikariCP/5.1.0/HikariCP-5.1.0.jar
Downloaded from central: https://repo.maven.apache.org/maven2/com/zaxxer/HikariCP/5.1.0/HikariCP-5.1.0.jar (162 kB at 3.4 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-jdbc/6.2.2/spring-jdbc-6.2.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-jdbc/6.2.2/spring-jdbc-6.2.2.pom (2.4 kB at 133 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-jdbc/6.2.2/spring-jdbc-6.2.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-jdbc/6.2.2/spring-jdbc-6.2.2.jar (471 kB at 4.6 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/hibernate/orm/hibernate-core/6.6.5.Final/hibernate-core-6.6.5.Final.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/hibernate/orm/hibernate-core/6.6.5.Final/hibernate-core-6.6.5.Final.pom (5.8 kB at 303 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/hibernate/orm/hibernate-core/6.6.5.Final/hibernate-core-6.6.5.Final.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/hibernate/orm/hibernate-core/6.6.5.Final/hibernate-core-6.6.5.Final.jar (12 MB at 5.5 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/jakarta/persistence/jakarta.persistence-api/3.1.0/jakarta.persistence-api-3.1.0.pom
Downloaded from central: https://repo.maven.apache.org/maven2/jakarta/persistence/jakarta.persistence-api/3.1.0/jakarta.persistence-api-3.1.0.pom (16 kB at 914 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/jakarta/persistence/jakarta.persistence-api/3.1.0/jakarta.persistence-api-3.1.0.jar
Downloaded from central: https://repo.maven.apache.org/maven2/jakarta/persistence/jakarta.persistence-api/3.1.0/jakarta.persistence-api-3.1.0.jar (165 kB at 3.7 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/jakarta/transaction/jakarta.transaction-api/2.0.1/jakarta.transaction-api-2.0.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/jakarta/transaction/jakarta.transaction-api/2.0.1/jakarta.transaction-api-2.0.1.pom (14 kB at 758 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/jakarta/transaction/jakarta.transaction-api/2.0.1/jakarta.transaction-api-2.0.1.jar
Downloaded from central: https://repo.maven.apache.org/maven2/jakarta/transaction/jakarta.transaction-api/2.0.1/jakarta.transaction-api-2.0.1.jar (29 kB at 1.1 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/jboss/logging/jboss-logging/3.6.1.Final/jboss-logging-3.6.1.Final.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/jboss/logging/jboss-logging/3.6.1.Final/jboss-logging-3.6.1.Final.pom (18 kB at 1.0 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/jboss/logging/jboss-logging/3.6.1.Final/jboss-logging-3.6.1.Final.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/jboss/logging/jboss-logging/3.6.1.Final/jboss-logging-3.6.1.Final.jar (62 kB at 2.4 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/hibernate/common/hibernate-commons-annotations/7.0.3.Final/hibernate-commons-annotations-7.0.3.Final.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/hibernate/common/hibernate-commons-annotations/7.0.3.Final/hibernate-commons-annotations-7.0.3.Final.pom (2.0 kB at 102 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/hibernate/common/hibernate-commons-annotations/7.0.3.Final/hibernate-commons-annotations-7.0.3.Final.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/hibernate/common/hibernate-commons-annotations/7.0.3.Final/hibernate-commons-annotations-7.0.3.Final.jar (68 kB at 2.2 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/io/smallrye/jandex/3.2.0/jandex-3.2.0.pom
Downloaded from central: https://repo.maven.apache.org/maven2/io/smallrye/jandex/3.2.0/jandex-3.2.0.pom (7.0 kB at 387 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/io/smallrye/jandex/3.2.0/jandex-3.2.0.jar
Downloaded from central: https://repo.maven.apache.org/maven2/io/smallrye/jandex/3.2.0/jandex-3.2.0.jar (375 kB at 4.5 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/classmate/1.7.0/classmate-1.7.0.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/classmate/1.7.0/classmate-1.7.0.pom (7.0 kB at 414 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/fasterxml/classmate/1.7.0/classmate-1.7.0.jar
Downloaded from central: https://repo.maven.apache.org/maven2/com/fasterxml/classmate/1.7.0/classmate-1.7.0.jar (69 kB at 2.4 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/net/bytebuddy/byte-buddy/1.15.11/byte-buddy-1.15.11.pom
Downloaded from central: https://repo.maven.apache.org/maven2/net/bytebuddy/byte-buddy/1.15.11/byte-buddy-1.15.11.pom (17 kB at 963 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/net/bytebuddy/byte-buddy/1.15.11/byte-buddy-1.15.11.jar
Downloaded from central: https://repo.maven.apache.org/maven2/net/bytebuddy/byte-buddy/1.15.11/byte-buddy-1.15.11.jar (8.5 MB at 5.0 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/jakarta/xml/bind/jakarta.xml.bind-api/4.0.2/jakarta.xml.bind-api-4.0.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/jakarta/xml/bind/jakarta.xml.bind-api/4.0.2/jakarta.xml.bind-api-4.0.2.pom (13 kB at 707 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/jakarta/xml/bind/jakarta.xml.bind-api/4.0.2/jakarta.xml.bind-api-4.0.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/jakarta/xml/bind/jakarta.xml.bind-api/4.0.2/jakarta.xml.bind-api-4.0.2.jar (131 kB at 3.3 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/jakarta/activation/jakarta.activation-api/2.1.3/jakarta.activation-api-2.1.3.pom
Downloaded from central: https://repo.maven.apache.org/maven2/jakarta/activation/jakarta.activation-api/2.1.3/jakarta.activation-api-2.1.3.pom (19 kB at 1.0 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/jakarta/activation/jakarta.activation-api/2.1.3/jakarta.activation-api-2.1.3.jar
Downloaded from central: https://repo.maven.apache.org/maven2/jakarta/activation/jakarta.activation-api/2.1.3/jakarta.activation-api-2.1.3.jar (67 kB at 2.5 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/glassfish/jaxb/jaxb-runtime/4.0.5/jaxb-runtime-4.0.5.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/glassfish/jaxb/jaxb-runtime/4.0.5/jaxb-runtime-4.0.5.pom (11 kB at 542 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/glassfish/jaxb/jaxb-runtime/4.0.5/jaxb-runtime-4.0.5.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/glassfish/jaxb/jaxb-runtime/4.0.5/jaxb-runtime-4.0.5.jar (920 kB at 5.2 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/glassfish/jaxb/jaxb-core/4.0.5/jaxb-core-4.0.5.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/glassfish/jaxb/jaxb-core/4.0.5/jaxb-core-4.0.5.pom (3.7 kB at 249 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/glassfish/jaxb/jaxb-core/4.0.5/jaxb-core-4.0.5.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/glassfish/jaxb/jaxb-core/4.0.5/jaxb-core-4.0.5.jar (139 kB at 3.6 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/eclipse/angus/angus-activation/2.0.2/angus-activation-2.0.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/eclipse/angus/angus-activation/2.0.2/angus-activation-2.0.2.pom (4.0 kB at 285 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/eclipse/angus/angus-activation/2.0.2/angus-activation-2.0.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/eclipse/angus/angus-activation/2.0.2/angus-activation-2.0.2.jar (27 kB at 1.3 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/glassfish/jaxb/txw2/4.0.5/txw2-4.0.5.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/glassfish/jaxb/txw2/4.0.5/txw2-4.0.5.pom (1.8 kB at 137 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/glassfish/jaxb/txw2/4.0.5/txw2-4.0.5.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/glassfish/jaxb/txw2/4.0.5/txw2-4.0.5.jar (73 kB at 2.4 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/sun/istack/istack-commons-runtime/4.1.2/istack-commons-runtime-4.1.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/sun/istack/istack-commons-runtime/4.1.2/istack-commons-runtime-4.1.2.pom (1.6 kB at 107 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/sun/istack/istack-commons-runtime/4.1.2/istack-commons-runtime-4.1.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/com/sun/istack/istack-commons-runtime/4.1.2/istack-commons-runtime-4.1.2.jar (26 kB at 1.4 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/jakarta/inject/jakarta.inject-api/2.0.1/jakarta.inject-api-2.0.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/jakarta/inject/jakarta.inject-api/2.0.1/jakarta.inject-api-2.0.1.pom (5.9 kB at 329 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/jakarta/inject/jakarta.inject-api/2.0.1/jakarta.inject-api-2.0.1.jar
Downloaded from central: https://repo.maven.apache.org/maven2/jakarta/inject/jakarta.inject-api/2.0.1/jakarta.inject-api-2.0.1.jar (11 kB at 593 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/antlr/antlr4-runtime/4.13.0/antlr4-runtime-4.13.0.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/antlr/antlr4-runtime/4.13.0/antlr4-runtime-4.13.0.pom (3.6 kB at 237 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/antlr/antlr4-runtime/4.13.0/antlr4-runtime-4.13.0.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/antlr/antlr4-runtime/4.13.0/antlr4-runtime-4.13.0.jar (326 kB at 4.4 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/data/spring-data-jpa/3.4.2/spring-data-jpa-3.4.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/data/spring-data-jpa/3.4.2/spring-data-jpa-3.4.2.pom (12 kB at 426 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/data/spring-data-jpa/3.4.2/spring-data-jpa-3.4.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/data/spring-data-jpa/3.4.2/spring-data-jpa-3.4.2.jar (1.8 MB at 5.5 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/data/spring-data-commons/3.4.2/spring-data-commons-3.4.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/data/spring-data-commons/3.4.2/spring-data-commons-3.4.2.pom (9.9 kB at 397 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/data/spring-data-commons/3.4.2/spring-data-commons-3.4.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/data/spring-data-commons/3.4.2/spring-data-commons-3.4.2.jar (1.5 MB at 5.4 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-orm/6.2.2/spring-orm-6.2.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-orm/6.2.2/spring-orm-6.2.2.pom (2.6 kB at 145 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-orm/6.2.2/spring-orm-6.2.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-orm/6.2.2/spring-orm-6.2.2.jar (234 kB at 3.7 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-tx/6.2.2/spring-tx-6.2.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-tx/6.2.2/spring-tx-6.2.2.pom (2.2 kB at 123 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-tx/6.2.2/spring-tx-6.2.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-tx/6.2.2/spring-tx-6.2.2.jar (285 kB at 4.1 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-aspects/6.2.2/spring-aspects-6.2.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-aspects/6.2.2/spring-aspects-6.2.2.pom (2.0 kB at 97 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/spring-aspects/6.2.2/spring-aspects-6.2.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/spring-aspects/6.2.2/spring-aspects-6.2.2.jar (50 kB at 1.2 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/aspectj/aspectjweaver/1.9.22.1/aspectjweaver-1.9.22.1.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/aspectj/aspectjweaver/1.9.22.1/aspectjweaver-1.9.22.1.pom (2.2 kB at 106 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/aspectj/aspectjweaver/1.9.22.1/aspectjweaver-1.9.22.1.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/aspectj/aspectjweaver/1.9.22.1/aspectjweaver-1.9.22.1.jar (2.2 MB at 5.5 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-validation/3.4.2/spring-boot-starter-validation-3.4.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-validation/3.4.2/spring-boot-starter-validation-3.4.2.pom (2.5 kB at 167 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-validation/3.4.2/spring-boot-starter-validation-3.4.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-validation/3.4.2/spring-boot-starter-validation-3.4.2.jar (4.8 kB at 251 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/tomcat/embed/tomcat-embed-el/10.1.34/tomcat-embed-el-10.1.34.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/tomcat/embed/tomcat-embed-el/10.1.34/tomcat-embed-el-10.1.34.pom (1.5 kB at 84 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/tomcat/embed/tomcat-embed-el/10.1.34/tomcat-embed-el-10.1.34.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/tomcat/embed/tomcat-embed-el/10.1.34/tomcat-embed-el-10.1.34.jar (263 kB at 1.5 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/hibernate/validator/hibernate-validator/8.0.2.Final/hibernate-validator-8.0.2.Final.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/hibernate/validator/hibernate-validator/8.0.2.Final/hibernate-validator-8.0.2.Final.pom (15 kB at 693 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/hibernate/validator/hibernate-validator/8.0.2.Final/hibernate-validator-8.0.2.Final.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/hibernate/validator/hibernate-validator/8.0.2.Final/hibernate-validator-8.0.2.Final.jar (1.3 MB at 5.4 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/jakarta/validation/jakarta.validation-api/3.0.2/jakarta.validation-api-3.0.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/jakarta/validation/jakarta.validation-api/3.0.2/jakarta.validation-api-3.0.2.pom (11 kB at 687 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/jakarta/validation/jakarta.validation-api/3.0.2/jakarta.validation-api-3.0.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/jakarta/validation/jakarta.validation-api/3.0.2/jakarta.validation-api-3.0.2.jar (93 kB at 2.9 MB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.pom
Downloaded from central: https://repo.maven.apache.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.pom (3.2 kB at 177 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar
Downloaded from central: https://repo.maven.apache.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar (2.5 MB at 5.6 MB/s)
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  16.442 s
[INFO] Finished at: 2025-02-13T21:35:40Z
[INFO] ------------------------------------------------------------------------
sre@ubuntu:~/java_projects/book-order-app$ mvn dependency:resolve
[INFO] Scanning for projects...
[INFO] 
[INFO] ---------------------< com.example:book-order-app >---------------------
[INFO] Building book-order-app 0.0.1-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[WARNING] The artifact mysql:mysql-connector-java:jar:8.0.33 has been relocated to com.mysql:mysql-connector-j:jar:8.0.33: MySQL Connector/J artifacts moved to reverse-DNS compliant Maven 2+ coordinates.
[INFO] 
[INFO] --- maven-dependency-plugin:3.8.1:resolve (default-cli) @ book-order-app ---
[INFO] 
[INFO] The following files have been resolved:
[INFO]    org.springframework.boot:spring-boot-starter-web:jar:3.4.2:compile -- module spring.boot.starter.web [auto]
[INFO]    org.springframework.boot:spring-boot-starter:jar:3.4.2:compile -- module spring.boot.starter [auto]
[INFO]    org.springframework.boot:spring-boot:jar:3.4.2:compile -- module spring.boot [auto]
[INFO]    org.springframework.boot:spring-boot-autoconfigure:jar:3.4.2:compile -- module spring.boot.autoconfigure [auto]
[INFO]    org.springframework.boot:spring-boot-starter-logging:jar:3.4.2:compile -- module spring.boot.starter.logging [auto]
[INFO]    ch.qos.logback:logback-classic:jar:1.5.16:compile -- module ch.qos.logback.classic
[INFO]    ch.qos.logback:logback-core:jar:1.5.16:compile -- module ch.qos.logback.core
[INFO]    org.apache.logging.log4j:log4j-to-slf4j:jar:2.24.3:compile -- module org.apache.logging.log4j.to.slf4j
[INFO]    org.apache.logging.log4j:log4j-api:jar:2.24.3:compile -- module org.apache.logging.log4j
[INFO]    org.slf4j:jul-to-slf4j:jar:2.0.16:compile -- module jul.to.slf4j
[INFO]    jakarta.annotation:jakarta.annotation-api:jar:2.1.1:compile -- module jakarta.annotation
[INFO]    org.yaml:snakeyaml:jar:2.3:compile -- module org.yaml.snakeyaml
[INFO]    org.springframework.boot:spring-boot-starter-json:jar:3.4.2:compile -- module spring.boot.starter.json [auto]
[INFO]    com.fasterxml.jackson.core:jackson-databind:jar:2.18.2:compile -- module com.fasterxml.jackson.databind
[INFO]    com.fasterxml.jackson.core:jackson-annotations:jar:2.18.2:compile -- module com.fasterxml.jackson.annotation
[INFO]    com.fasterxml.jackson.core:jackson-core:jar:2.18.2:compile -- module com.fasterxml.jackson.core
[INFO]    com.fasterxml.jackson.datatype:jackson-datatype-jdk8:jar:2.18.2:compile -- module com.fasterxml.jackson.datatype.jdk8
[INFO]    com.fasterxml.jackson.datatype:jackson-datatype-jsr310:jar:2.18.2:compile -- module com.fasterxml.jackson.datatype.jsr310
[INFO]    com.fasterxml.jackson.module:jackson-module-parameter-names:jar:2.18.2:compile -- module com.fasterxml.jackson.module.paramnames
[INFO]    org.springframework.boot:spring-boot-starter-tomcat:jar:3.4.2:compile -- module spring.boot.starter.tomcat [auto]
[INFO]    org.apache.tomcat.embed:tomcat-embed-core:jar:10.1.34:compile -- module org.apache.tomcat.embed.core
[INFO]    org.apache.tomcat.embed:tomcat-embed-websocket:jar:10.1.34:compile -- module org.apache.tomcat.embed.websocket
[INFO]    org.springframework:spring-web:jar:6.2.2:compile -- module spring.web [auto]
[INFO]    org.springframework:spring-beans:jar:6.2.2:compile -- module spring.beans [auto]
[INFO]    io.micrometer:micrometer-observation:jar:1.14.3:compile -- module micrometer.observation [auto]
[INFO]    io.micrometer:micrometer-commons:jar:1.14.3:compile -- module micrometer.commons [auto]
[INFO]    org.springframework:spring-webmvc:jar:6.2.2:compile -- module spring.webmvc [auto]
[INFO]    org.springframework:spring-aop:jar:6.2.2:compile -- module spring.aop [auto]
[INFO]    org.springframework:spring-context:jar:6.2.2:compile -- module spring.context [auto]
[INFO]    org.springframework:spring-expression:jar:6.2.2:compile -- module spring.expression [auto]
[INFO]    org.springframework.boot:spring-boot-starter-thymeleaf:jar:3.4.2:compile -- module spring.boot.starter.thymeleaf [auto]
[INFO]    org.thymeleaf:thymeleaf-spring6:jar:3.1.3.RELEASE:compile -- module thymeleaf.spring6 [auto]
[INFO]    org.thymeleaf:thymeleaf:jar:3.1.3.RELEASE:compile -- module thymeleaf [auto]
[INFO]    org.attoparser:attoparser:jar:2.0.7.RELEASE:compile -- module attoparser [auto]
[INFO]    org.unbescape:unbescape:jar:1.1.6.RELEASE:compile -- module unbescape [auto]
[INFO]    org.slf4j:slf4j-api:jar:2.0.16:compile -- module org.slf4j
[INFO]    org.springframework.boot:spring-boot-starter-data-jpa:jar:3.4.2:compile -- module spring.boot.starter.data.jpa [auto]
[INFO]    org.springframework.boot:spring-boot-starter-jdbc:jar:3.4.2:compile -- module spring.boot.starter.jdbc [auto]
[INFO]    com.zaxxer:HikariCP:jar:5.1.0:compile -- module com.zaxxer.hikari
[INFO]    org.springframework:spring-jdbc:jar:6.2.2:compile -- module spring.jdbc [auto]
[INFO]    org.hibernate.orm:hibernate-core:jar:6.6.5.Final:compile -- module org.hibernate.orm.core [auto]
[INFO]    jakarta.persistence:jakarta.persistence-api:jar:3.1.0:compile -- module jakarta.persistence
[INFO]    jakarta.transaction:jakarta.transaction-api:jar:2.0.1:compile -- module jakarta.transaction
[INFO]    org.jboss.logging:jboss-logging:jar:3.6.1.Final:compile -- module org.jboss.logging
[INFO]    org.hibernate.common:hibernate-commons-annotations:jar:7.0.3.Final:runtime -- module org.hibernate.commons.annotations
[INFO]    io.smallrye:jandex:jar:3.2.0:runtime -- module org.jboss.jandex [auto]
[INFO]    com.fasterxml:classmate:jar:1.7.0:compile -- module com.fasterxml.classmate
[INFO]    net.bytebuddy:byte-buddy:jar:1.15.11:runtime -- module net.bytebuddy
[INFO]    org.glassfish.jaxb:jaxb-runtime:jar:4.0.5:runtime -- module org.glassfish.jaxb.runtime
[INFO]    org.glassfish.jaxb:jaxb-core:jar:4.0.5:runtime -- module org.glassfish.jaxb.core
[INFO]    org.eclipse.angus:angus-activation:jar:2.0.2:runtime -- module org.eclipse.angus.activation
[INFO]    org.glassfish.jaxb:txw2:jar:4.0.5:runtime -- module com.sun.xml.txw2
[INFO]    com.sun.istack:istack-commons-runtime:jar:4.1.2:runtime -- module com.sun.istack.runtime
[INFO]    jakarta.inject:jakarta.inject-api:jar:2.0.1:runtime -- module jakarta.inject
[INFO]    org.antlr:antlr4-runtime:jar:4.13.0:compile -- module org.antlr.antlr4.runtime [auto]
[INFO]    org.springframework.data:spring-data-jpa:jar:3.4.2:compile -- module spring.data.jpa [auto]
[INFO]    org.springframework.data:spring-data-commons:jar:3.4.2:compile -- module spring.data.commons [auto]
[INFO]    org.springframework:spring-orm:jar:6.2.2:compile -- module spring.orm [auto]
[INFO]    org.springframework:spring-tx:jar:6.2.2:compile -- module spring.tx [auto]
[INFO]    org.springframework:spring-aspects:jar:6.2.2:compile -- module spring.aspects [auto]
[INFO]    org.aspectj:aspectjweaver:jar:1.9.22.1:compile -- module org.aspectj.weaver [auto]
[INFO]    org.springframework.boot:spring-boot-starter-validation:jar:3.4.2:compile -- module spring.boot.starter.validation [auto]
[INFO]    org.apache.tomcat.embed:tomcat-embed-el:jar:10.1.34:compile -- module org.apache.tomcat.embed.el
[INFO]    org.hibernate.validator:hibernate-validator:jar:8.0.2.Final:compile -- module org.hibernate.validator [auto]
[INFO]    jakarta.validation:jakarta.validation-api:jar:3.0.2:compile -- module jakarta.validation
[INFO]    com.mysql:mysql-connector-j:jar:8.0.33:compile -- module mysql.connector.j (auto)
[INFO]    org.springframework.boot:spring-boot-starter-test:jar:3.4.2:test -- module spring.boot.starter.test [auto]
[INFO]    org.springframework.boot:spring-boot-test:jar:3.4.2:test -- module spring.boot.test [auto]
[INFO]    org.springframework.boot:spring-boot-test-autoconfigure:jar:3.4.2:test -- module spring.boot.test.autoconfigure [auto]
[INFO]    com.jayway.jsonpath:json-path:jar:2.9.0:test -- module json.path [auto]
[INFO]    jakarta.xml.bind:jakarta.xml.bind-api:jar:4.0.2:runtime -- module jakarta.xml.bind
[INFO]    jakarta.activation:jakarta.activation-api:jar:2.1.3:runtime -- module jakarta.activation
[INFO]    net.minidev:json-smart:jar:2.5.1:test -- module json.smart (auto)
[INFO]    net.minidev:accessors-smart:jar:2.5.1:test -- module accessors.smart (auto)
[INFO]    org.ow2.asm:asm:jar:9.6:test -- module org.objectweb.asm
[INFO]    org.assertj:assertj-core:jar:3.26.3:test -- module org.assertj.core
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
[INFO]    org.springframework:spring-core:jar:6.2.2:compile -- module spring.core [auto]
[INFO]    org.springframework:spring-jcl:jar:6.2.2:compile -- module spring.jcl [auto]
[INFO]    org.springframework:spring-test:jar:6.2.2:test -- module spring.test [auto]
[INFO]    org.xmlunit:xmlunit-core:jar:2.10.0:test -- module org.xmlunit [auto]
[INFO]    junit:junit:jar:3.8.1:test -- module junit (auto)
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.135 s
[INFO] Finished at: 2025-02-13T21:35:59Z
[INFO] ------------------------------------------------------------------------
sre@ubuntu:~/java_projects/book-order-app$ 


sre@ubuntu:~/java_projects/book-order-app$ mvn dependency:resolve
[INFO] Scanning for projects...
[INFO] 
[INFO] ---------------------< com.example:book-order-app >---------------------
[INFO] Building book-order-app 0.0.1-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-security/3.4.2/spring-boot-starter-security-3.4.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-security/3.4.2/spring-boot-starter-security-3.4.2.pom (2.7 kB at 4.5 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-config/6.4.2/spring-security-config-6.4.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-config/6.4.2/spring-security-config-6.4.2.pom (2.8 kB at 94 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-core/6.4.2/spring-security-core-6.4.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-core/6.4.2/spring-security-core-6.4.2.pom (3.2 kB at 115 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-crypto/6.4.2/spring-security-crypto-6.4.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-crypto/6.4.2/spring-security-crypto-6.4.2.pom (1.9 kB at 78 kB/s)
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-web/6.4.2/spring-security-web-6.4.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-web/6.4.2/spring-security-web-6.4.2.pom (3.2 kB at 128 kB/s)
[WARNING] The artifact mysql:mysql-connector-java:jar:8.0.33 has been relocated to com.mysql:mysql-connector-j:jar:8.0.33: MySQL Connector/J artifacts moved to reverse-DNS compliant Maven 2+ coordinates.
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-security/3.4.2/spring-boot-starter-security-3.4.2.jar
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-config/6.4.2/spring-security-config-6.4.2.jar
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-core/6.4.2/spring-security-core-6.4.2.jar
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-crypto/6.4.2/spring-security-crypto-6.4.2.jar
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-web/6.4.2/spring-security-web-6.4.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-security/3.4.2/spring-boot-starter-security-3.4.2.jar (4.7 kB at 42 kB/s)
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-crypto/6.4.2/spring-security-crypto-6.4.2.jar (101 kB at 381 kB/s)
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-web/6.4.2/spring-security-web-6.4.2.jar (993 kB at 1.5 MB/s)
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-core/6.4.2/spring-security-core-6.4.2.jar (607 kB at 833 kB/s)
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-config/6.4.2/spring-security-config-6.4.2.jar (2.0 MB at 2.6 MB/s)
[INFO] 
[INFO] --- maven-dependency-plugin:3.8.1:resolve (default-cli) @ book-order-app ---
[INFO] 
[INFO] The following files have been resolved:
[INFO]    org.springframework.boot:spring-boot-starter-web:jar:3.4.2:compile -- module spring.boot.starter.web [auto]
[INFO]    org.springframework.boot:spring-boot-starter:jar:3.4.2:compile -- module spring.boot.starter [auto]
[INFO]    org.springframework.boot:spring-boot:jar:3.4.2:compile -- module spring.boot [auto]
[INFO]    org.springframework.boot:spring-boot-autoconfigure:jar:3.4.2:compile -- module spring.boot.autoconfigure [auto]
[INFO]    org.springframework.boot:spring-boot-starter-logging:jar:3.4.2:compile -- module spring.boot.starter.logging [auto]
[INFO]    ch.qos.logback:logback-classic:jar:1.5.16:compile -- module ch.qos.logback.classic
[INFO]    ch.qos.logback:logback-core:jar:1.5.16:compile -- module ch.qos.logback.core
[INFO]    org.apache.logging.log4j:log4j-to-slf4j:jar:2.24.3:compile -- module org.apache.logging.log4j.to.slf4j
[INFO]    org.apache.logging.log4j:log4j-api:jar:2.24.3:compile -- module org.apache.logging.log4j
[INFO]    org.slf4j:jul-to-slf4j:jar:2.0.16:compile -- module jul.to.slf4j
[INFO]    jakarta.annotation:jakarta.annotation-api:jar:2.1.1:compile -- module jakarta.annotation
[INFO]    org.yaml:snakeyaml:jar:2.3:compile -- module org.yaml.snakeyaml
[INFO]    org.springframework.boot:spring-boot-starter-json:jar:3.4.2:compile -- module spring.boot.starter.json [auto]
[INFO]    com.fasterxml.jackson.core:jackson-databind:jar:2.18.2:compile -- module com.fasterxml.jackson.databind
[INFO]    com.fasterxml.jackson.core:jackson-annotations:jar:2.18.2:compile -- module com.fasterxml.jackson.annotation
[INFO]    com.fasterxml.jackson.core:jackson-core:jar:2.18.2:compile -- module com.fasterxml.jackson.core
[INFO]    com.fasterxml.jackson.datatype:jackson-datatype-jdk8:jar:2.18.2:compile -- module com.fasterxml.jackson.datatype.jdk8
[INFO]    com.fasterxml.jackson.datatype:jackson-datatype-jsr310:jar:2.18.2:compile -- module com.fasterxml.jackson.datatype.jsr310
[INFO]    com.fasterxml.jackson.module:jackson-module-parameter-names:jar:2.18.2:compile -- module com.fasterxml.jackson.module.paramnames
[INFO]    org.springframework.boot:spring-boot-starter-tomcat:jar:3.4.2:compile -- module spring.boot.starter.tomcat [auto]
[INFO]    org.apache.tomcat.embed:tomcat-embed-core:jar:10.1.34:compile -- module org.apache.tomcat.embed.core
[INFO]    org.apache.tomcat.embed:tomcat-embed-websocket:jar:10.1.34:compile -- module org.apache.tomcat.embed.websocket
[INFO]    org.springframework:spring-web:jar:6.2.2:compile -- module spring.web [auto]
[INFO]    org.springframework:spring-beans:jar:6.2.2:compile -- module spring.beans [auto]
[INFO]    io.micrometer:micrometer-observation:jar:1.14.3:compile -- module micrometer.observation [auto]
[INFO]    io.micrometer:micrometer-commons:jar:1.14.3:compile -- module micrometer.commons [auto]
[INFO]    org.springframework:spring-webmvc:jar:6.2.2:compile -- module spring.webmvc [auto]
[INFO]    org.springframework:spring-context:jar:6.2.2:compile -- module spring.context [auto]
[INFO]    org.springframework:spring-expression:jar:6.2.2:compile -- module spring.expression [auto]
[INFO]    org.springframework.boot:spring-boot-starter-thymeleaf:jar:3.4.2:compile -- module spring.boot.starter.thymeleaf [auto]
[INFO]    org.thymeleaf:thymeleaf-spring6:jar:3.1.3.RELEASE:compile -- module thymeleaf.spring6 [auto]
[INFO]    org.thymeleaf:thymeleaf:jar:3.1.3.RELEASE:compile -- module thymeleaf [auto]
[INFO]    org.attoparser:attoparser:jar:2.0.7.RELEASE:compile -- module attoparser [auto]
[INFO]    org.unbescape:unbescape:jar:1.1.6.RELEASE:compile -- module unbescape [auto]
[INFO]    org.slf4j:slf4j-api:jar:2.0.16:compile -- module org.slf4j
[INFO]    org.springframework.boot:spring-boot-starter-data-jpa:jar:3.4.2:compile -- module spring.boot.starter.data.jpa [auto]
[INFO]    org.springframework.boot:spring-boot-starter-jdbc:jar:3.4.2:compile -- module spring.boot.starter.jdbc [auto]
[INFO]    com.zaxxer:HikariCP:jar:5.1.0:compile -- module com.zaxxer.hikari
[INFO]    org.springframework:spring-jdbc:jar:6.2.2:compile -- module spring.jdbc [auto]
[INFO]    org.hibernate.orm:hibernate-core:jar:6.6.5.Final:compile -- module org.hibernate.orm.core [auto]
[INFO]    jakarta.persistence:jakarta.persistence-api:jar:3.1.0:compile -- module jakarta.persistence
[INFO]    jakarta.transaction:jakarta.transaction-api:jar:2.0.1:compile -- module jakarta.transaction
[INFO]    org.jboss.logging:jboss-logging:jar:3.6.1.Final:compile -- module org.jboss.logging
[INFO]    org.hibernate.common:hibernate-commons-annotations:jar:7.0.3.Final:runtime -- module org.hibernate.commons.annotations
[INFO]    io.smallrye:jandex:jar:3.2.0:runtime -- module org.jboss.jandex [auto]
[INFO]    com.fasterxml:classmate:jar:1.7.0:compile -- module com.fasterxml.classmate
[INFO]    net.bytebuddy:byte-buddy:jar:1.15.11:runtime -- module net.bytebuddy
[INFO]    org.glassfish.jaxb:jaxb-runtime:jar:4.0.5:runtime -- module org.glassfish.jaxb.runtime
[INFO]    org.glassfish.jaxb:jaxb-core:jar:4.0.5:runtime -- module org.glassfish.jaxb.core
[INFO]    org.eclipse.angus:angus-activation:jar:2.0.2:runtime -- module org.eclipse.angus.activation
[INFO]    org.glassfish.jaxb:txw2:jar:4.0.5:runtime -- module com.sun.xml.txw2
[INFO]    com.sun.istack:istack-commons-runtime:jar:4.1.2:runtime -- module com.sun.istack.runtime
[INFO]    jakarta.inject:jakarta.inject-api:jar:2.0.1:runtime -- module jakarta.inject
[INFO]    org.antlr:antlr4-runtime:jar:4.13.0:compile -- module org.antlr.antlr4.runtime [auto]
[INFO]    org.springframework.data:spring-data-jpa:jar:3.4.2:compile -- module spring.data.jpa [auto]
[INFO]    org.springframework.data:spring-data-commons:jar:3.4.2:compile -- module spring.data.commons [auto]
[INFO]    org.springframework:spring-orm:jar:6.2.2:compile -- module spring.orm [auto]
[INFO]    org.springframework:spring-tx:jar:6.2.2:compile -- module spring.tx [auto]
[INFO]    org.springframework:spring-aspects:jar:6.2.2:compile -- module spring.aspects [auto]
[INFO]    org.aspectj:aspectjweaver:jar:1.9.22.1:compile -- module org.aspectj.weaver [auto]
[INFO]    org.springframework.boot:spring-boot-starter-validation:jar:3.4.2:compile -- module spring.boot.starter.validation [auto]
[INFO]    org.apache.tomcat.embed:tomcat-embed-el:jar:10.1.34:compile -- module org.apache.tomcat.embed.el
[INFO]    org.hibernate.validator:hibernate-validator:jar:8.0.2.Final:compile -- module org.hibernate.validator [auto]
[INFO]    jakarta.validation:jakarta.validation-api:jar:3.0.2:compile -- module jakarta.validation
[INFO]    org.springframework.boot:spring-boot-starter-security:jar:3.4.2:compile -- module spring.boot.starter.security [auto]
[INFO]    org.springframework:spring-aop:jar:6.2.2:compile -- module spring.aop [auto]
[INFO]    org.springframework.security:spring-security-config:jar:6.4.2:compile -- module spring.security.config [auto]
[INFO]    org.springframework.security:spring-security-core:jar:6.4.2:compile -- module spring.security.core [auto]
[INFO]    org.springframework.security:spring-security-crypto:jar:6.4.2:compile -- module spring.security.crypto [auto]
[INFO]    org.springframework.security:spring-security-web:jar:6.4.2:compile -- module spring.security.web [auto]
[INFO]    com.mysql:mysql-connector-j:jar:8.0.33:compile -- module mysql.connector.j (auto)
[INFO]    org.springframework.boot:spring-boot-starter-test:jar:3.4.2:test -- module spring.boot.starter.test [auto]
[INFO]    org.springframework.boot:spring-boot-test:jar:3.4.2:test -- module spring.boot.test [auto]
[INFO]    org.springframework.boot:spring-boot-test-autoconfigure:jar:3.4.2:test -- module spring.boot.test.autoconfigure [auto]
[INFO]    com.jayway.jsonpath:json-path:jar:2.9.0:test -- module json.path [auto]
[INFO]    jakarta.xml.bind:jakarta.xml.bind-api:jar:4.0.2:runtime -- module jakarta.xml.bind
[INFO]    jakarta.activation:jakarta.activation-api:jar:2.1.3:runtime -- module jakarta.activation
[INFO]    net.minidev:json-smart:jar:2.5.1:test -- module json.smart (auto)
[INFO]    net.minidev:accessors-smart:jar:2.5.1:test -- module accessors.smart (auto)
[INFO]    org.ow2.asm:asm:jar:9.6:test -- module org.objectweb.asm
[INFO]    org.assertj:assertj-core:jar:3.26.3:test -- module org.assertj.core
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
[INFO]    org.springframework:spring-core:jar:6.2.2:compile -- module spring.core [auto]
[INFO]    org.springframework:spring-jcl:jar:6.2.2:compile -- module spring.jcl [auto]
[INFO]    org.springframework:spring-test:jar:6.2.2:test -- module spring.test [auto]
[INFO]    org.xmlunit:xmlunit-core:jar:2.10.0:test -- module org.xmlunit [auto]
[INFO]    junit:junit:jar:3.8.1:test -- module junit (auto)
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  5.802 s
[INFO] Finished at: 2025-02-17T18:42:58Z
[INFO] ------------------------------------------------------------------------

sre@ubuntu:~/java_projects/book-order-app$ mvn dependency:resolve
[INFO] Scanning for projects...
[INFO] 
[INFO] ---------------------< com.example:book-order-app >---------------------
[INFO] Building book-order-app 0.0.1-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-test/6.4.2/spring-security-test-6.4.2.pom
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-test/6.4.2/spring-security-test-6.4.2.pom (2.7 kB at 5.5 kB/s)
[WARNING] The artifact mysql:mysql-connector-java:jar:8.0.33 has been relocated to com.mysql:mysql-connector-j:jar:8.0.33: MySQL Connector/J artifacts moved to reverse-DNS compliant Maven 2+ coordinates.
Downloading from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-test/6.4.2/spring-security-test-6.4.2.jar
Downloaded from central: https://repo.maven.apache.org/maven2/org/springframework/security/spring-security-test/6.4.2/spring-security-test-6.4.2.jar (132 kB at 1.4 MB/s)
[INFO] 
[INFO] --- maven-dependency-plugin:3.8.1:resolve (default-cli) @ book-order-app ---
[INFO] 
[INFO] The following files have been resolved:
[INFO]    org.springframework.boot:spring-boot-starter-web:jar:3.4.2:compile -- module spring.boot.starter.web [auto]
[INFO]    org.springframework.boot:spring-boot-starter:jar:3.4.2:compile -- module spring.boot.starter [auto]
[INFO]    org.springframework.boot:spring-boot:jar:3.4.2:compile -- module spring.boot [auto]
[INFO]    org.springframework.boot:spring-boot-autoconfigure:jar:3.4.2:compile -- module spring.boot.autoconfigure [auto]
[INFO]    org.springframework.boot:spring-boot-starter-logging:jar:3.4.2:compile -- module spring.boot.starter.logging [auto]
[INFO]    ch.qos.logback:logback-classic:jar:1.5.16:compile -- module ch.qos.logback.classic
[INFO]    ch.qos.logback:logback-core:jar:1.5.16:compile -- module ch.qos.logback.core
[INFO]    org.apache.logging.log4j:log4j-to-slf4j:jar:2.24.3:compile -- module org.apache.logging.log4j.to.slf4j
[INFO]    org.apache.logging.log4j:log4j-api:jar:2.24.3:compile -- module org.apache.logging.log4j
[INFO]    org.slf4j:jul-to-slf4j:jar:2.0.16:compile -- module jul.to.slf4j
[INFO]    jakarta.annotation:jakarta.annotation-api:jar:2.1.1:compile -- module jakarta.annotation
[INFO]    org.yaml:snakeyaml:jar:2.3:compile -- module org.yaml.snakeyaml
[INFO]    org.springframework.boot:spring-boot-starter-json:jar:3.4.2:compile -- module spring.boot.starter.json [auto]
[INFO]    com.fasterxml.jackson.core:jackson-databind:jar:2.18.2:compile -- module com.fasterxml.jackson.databind
[INFO]    com.fasterxml.jackson.core:jackson-annotations:jar:2.18.2:compile -- module com.fasterxml.jackson.annotation
[INFO]    com.fasterxml.jackson.core:jackson-core:jar:2.18.2:compile -- module com.fasterxml.jackson.core
[INFO]    com.fasterxml.jackson.datatype:jackson-datatype-jdk8:jar:2.18.2:compile -- module com.fasterxml.jackson.datatype.jdk8
[INFO]    com.fasterxml.jackson.datatype:jackson-datatype-jsr310:jar:2.18.2:compile -- module com.fasterxml.jackson.datatype.jsr310
[INFO]    com.fasterxml.jackson.module:jackson-module-parameter-names:jar:2.18.2:compile -- module com.fasterxml.jackson.module.paramnames
[INFO]    org.springframework.boot:spring-boot-starter-tomcat:jar:3.4.2:compile -- module spring.boot.starter.tomcat [auto]
[INFO]    org.apache.tomcat.embed:tomcat-embed-core:jar:10.1.34:compile -- module org.apache.tomcat.embed.core
[INFO]    org.apache.tomcat.embed:tomcat-embed-websocket:jar:10.1.34:compile -- module org.apache.tomcat.embed.websocket
[INFO]    org.springframework:spring-web:jar:6.2.2:compile -- module spring.web [auto]
[INFO]    org.springframework:spring-beans:jar:6.2.2:compile -- module spring.beans [auto]
[INFO]    io.micrometer:micrometer-observation:jar:1.14.3:compile -- module micrometer.observation [auto]
[INFO]    io.micrometer:micrometer-commons:jar:1.14.3:compile -- module micrometer.commons [auto]
[INFO]    org.springframework:spring-webmvc:jar:6.2.2:compile -- module spring.webmvc [auto]
[INFO]    org.springframework:spring-context:jar:6.2.2:compile -- module spring.context [auto]
[INFO]    org.springframework:spring-expression:jar:6.2.2:compile -- module spring.expression [auto]
[INFO]    org.springframework.boot:spring-boot-starter-thymeleaf:jar:3.4.2:compile -- module spring.boot.starter.thymeleaf [auto]
[INFO]    org.thymeleaf:thymeleaf-spring6:jar:3.1.3.RELEASE:compile -- module thymeleaf.spring6 [auto]
[INFO]    org.thymeleaf:thymeleaf:jar:3.1.3.RELEASE:compile -- module thymeleaf [auto]
[INFO]    org.attoparser:attoparser:jar:2.0.7.RELEASE:compile -- module attoparser [auto]
[INFO]    org.unbescape:unbescape:jar:1.1.6.RELEASE:compile -- module unbescape [auto]
[INFO]    org.slf4j:slf4j-api:jar:2.0.16:compile -- module org.slf4j
[INFO]    org.springframework.boot:spring-boot-starter-data-jpa:jar:3.4.2:compile -- module spring.boot.starter.data.jpa [auto]
[INFO]    org.springframework.boot:spring-boot-starter-jdbc:jar:3.4.2:compile -- module spring.boot.starter.jdbc [auto]
[INFO]    com.zaxxer:HikariCP:jar:5.1.0:compile -- module com.zaxxer.hikari
[INFO]    org.springframework:spring-jdbc:jar:6.2.2:compile -- module spring.jdbc [auto]
[INFO]    org.hibernate.orm:hibernate-core:jar:6.6.5.Final:compile -- module org.hibernate.orm.core [auto]
[INFO]    jakarta.persistence:jakarta.persistence-api:jar:3.1.0:compile -- module jakarta.persistence
[INFO]    jakarta.transaction:jakarta.transaction-api:jar:2.0.1:compile -- module jakarta.transaction
[INFO]    org.jboss.logging:jboss-logging:jar:3.6.1.Final:compile -- module org.jboss.logging
[INFO]    org.hibernate.common:hibernate-commons-annotations:jar:7.0.3.Final:runtime -- module org.hibernate.commons.annotations
[INFO]    io.smallrye:jandex:jar:3.2.0:runtime -- module org.jboss.jandex [auto]
[INFO]    com.fasterxml:classmate:jar:1.7.0:compile -- module com.fasterxml.classmate
[INFO]    net.bytebuddy:byte-buddy:jar:1.15.11:runtime -- module net.bytebuddy
[INFO]    org.glassfish.jaxb:jaxb-runtime:jar:4.0.5:runtime -- module org.glassfish.jaxb.runtime
[INFO]    org.glassfish.jaxb:jaxb-core:jar:4.0.5:runtime -- module org.glassfish.jaxb.core
[INFO]    org.eclipse.angus:angus-activation:jar:2.0.2:runtime -- module org.eclipse.angus.activation
[INFO]    org.glassfish.jaxb:txw2:jar:4.0.5:runtime -- module com.sun.xml.txw2
[INFO]    com.sun.istack:istack-commons-runtime:jar:4.1.2:runtime -- module com.sun.istack.runtime
[INFO]    jakarta.inject:jakarta.inject-api:jar:2.0.1:runtime -- module jakarta.inject
[INFO]    org.antlr:antlr4-runtime:jar:4.13.0:compile -- module org.antlr.antlr4.runtime [auto]
[INFO]    org.springframework.data:spring-data-jpa:jar:3.4.2:compile -- module spring.data.jpa [auto]
[INFO]    org.springframework.data:spring-data-commons:jar:3.4.2:compile -- module spring.data.commons [auto]
[INFO]    org.springframework:spring-orm:jar:6.2.2:compile -- module spring.orm [auto]
[INFO]    org.springframework:spring-tx:jar:6.2.2:compile -- module spring.tx [auto]
[INFO]    org.springframework:spring-aspects:jar:6.2.2:compile -- module spring.aspects [auto]
[INFO]    org.aspectj:aspectjweaver:jar:1.9.22.1:compile -- module org.aspectj.weaver [auto]
[INFO]    org.springframework.boot:spring-boot-starter-validation:jar:3.4.2:compile -- module spring.boot.starter.validation [auto]
[INFO]    org.apache.tomcat.embed:tomcat-embed-el:jar:10.1.34:compile -- module org.apache.tomcat.embed.el
[INFO]    org.hibernate.validator:hibernate-validator:jar:8.0.2.Final:compile -- module org.hibernate.validator [auto]
[INFO]    jakarta.validation:jakarta.validation-api:jar:3.0.2:compile -- module jakarta.validation
[INFO]    org.springframework.boot:spring-boot-starter-security:jar:3.4.2:compile -- module spring.boot.starter.security [auto]
[INFO]    org.springframework:spring-aop:jar:6.2.2:compile -- module spring.aop [auto]
[INFO]    org.springframework.security:spring-security-config:jar:6.4.2:compile -- module spring.security.config [auto]
[INFO]    org.springframework.security:spring-security-web:jar:6.4.2:compile -- module spring.security.web [auto]
[INFO]    org.springframework.boot:spring-boot-starter-test:jar:3.4.2:test -- module spring.boot.starter.test [auto]
[INFO]    org.springframework.boot:spring-boot-test:jar:3.4.2:test -- module spring.boot.test [auto]
[INFO]    org.springframework.boot:spring-boot-test-autoconfigure:jar:3.4.2:test -- module spring.boot.test.autoconfigure [auto]
[INFO]    com.jayway.jsonpath:json-path:jar:2.9.0:test -- module json.path [auto]
[INFO]    jakarta.xml.bind:jakarta.xml.bind-api:jar:4.0.2:runtime -- module jakarta.xml.bind
[INFO]    jakarta.activation:jakarta.activation-api:jar:2.1.3:runtime -- module jakarta.activation
[INFO]    net.minidev:json-smart:jar:2.5.1:test -- module json.smart (auto)
[INFO]    net.minidev:accessors-smart:jar:2.5.1:test -- module accessors.smart (auto)
[INFO]    org.ow2.asm:asm:jar:9.6:test -- module org.objectweb.asm
[INFO]    org.assertj:assertj-core:jar:3.26.3:test -- module org.assertj.core
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
[INFO]    org.springframework:spring-core:jar:6.2.2:compile -- module spring.core [auto]
[INFO]    org.springframework:spring-jcl:jar:6.2.2:compile -- module spring.jcl [auto]
[INFO]    org.springframework:spring-test:jar:6.2.2:test -- module spring.test [auto]
[INFO]    org.xmlunit:xmlunit-core:jar:2.10.0:test -- module org.xmlunit [auto]
[INFO]    org.springframework.security:spring-security-test:jar:6.4.2:test -- module spring.security.test [auto]
[INFO]    org.springframework.security:spring-security-core:jar:6.4.2:compile -- module spring.security.core [auto]
[INFO]    org.springframework.security:spring-security-crypto:jar:6.4.2:compile -- module spring.security.crypto [auto]
[INFO]    com.mysql:mysql-connector-j:jar:8.0.33:compile -- module mysql.connector.j (auto)
[INFO]    junit:junit:jar:3.8.1:test -- module junit (auto)
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  3.121 s
[INFO] Finished at: 2025-02-17T19:22:53Z
[INFO] ------------------------------------------------------------------------
sre@ubuntu:~/java_projects/book-order-app$ 

sre@ubuntu:~/java_projects/book-order-app$ mvn dependency:resolve
[INFO] Scanning for projects...
[INFO] 
[INFO] ---------------------< com.example:book-order-app >---------------------
[INFO] Building book-order-app 0.0.1-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[WARNING] The artifact mysql:mysql-connector-java:jar:8.0.33 has been relocated to com.mysql:mysql-connector-j:jar:8.0.33: MySQL Connector/J artifacts moved to reverse-DNS compliant Maven 2+ coordinates.
[INFO] 
[INFO] --- maven-dependency-plugin:3.8.1:resolve (default-cli) @ book-order-app ---
[INFO] 
[INFO] The following files have been resolved:
[INFO]    org.springframework.boot:spring-boot-starter-web:jar:3.4.2:compile -- module spring.boot.starter.web [auto]
[INFO]    org.springframework.boot:spring-boot-starter:jar:3.4.2:compile -- module spring.boot.starter [auto]
[INFO]    org.springframework.boot:spring-boot:jar:3.4.2:compile -- module spring.boot [auto]
[INFO]    org.springframework.boot:spring-boot-autoconfigure:jar:3.4.2:compile -- module spring.boot.autoconfigure [auto]
[INFO]    org.springframework.boot:spring-boot-starter-logging:jar:3.4.2:compile -- module spring.boot.starter.logging [auto]
[INFO]    ch.qos.logback:logback-classic:jar:1.5.16:compile -- module ch.qos.logback.classic
[INFO]    ch.qos.logback:logback-core:jar:1.5.16:compile -- module ch.qos.logback.core
[INFO]    org.apache.logging.log4j:log4j-to-slf4j:jar:2.24.3:compile -- module org.apache.logging.log4j.to.slf4j
[INFO]    org.apache.logging.log4j:log4j-api:jar:2.24.3:compile -- module org.apache.logging.log4j
[INFO]    org.slf4j:jul-to-slf4j:jar:2.0.16:compile -- module jul.to.slf4j
[INFO]    jakarta.annotation:jakarta.annotation-api:jar:2.1.1:compile -- module jakarta.annotation
[INFO]    org.yaml:snakeyaml:jar:2.3:compile -- module org.yaml.snakeyaml
[INFO]    org.springframework.boot:spring-boot-starter-json:jar:3.4.2:compile -- module spring.boot.starter.json [auto]
[INFO]    com.fasterxml.jackson.core:jackson-databind:jar:2.18.2:compile -- module com.fasterxml.jackson.databind
[INFO]    com.fasterxml.jackson.core:jackson-annotations:jar:2.18.2:compile -- module com.fasterxml.jackson.annotation
[INFO]    com.fasterxml.jackson.core:jackson-core:jar:2.18.2:compile -- module com.fasterxml.jackson.core
[INFO]    com.fasterxml.jackson.datatype:jackson-datatype-jdk8:jar:2.18.2:compile -- module com.fasterxml.jackson.datatype.jdk8
[INFO]    com.fasterxml.jackson.datatype:jackson-datatype-jsr310:jar:2.18.2:compile -- module com.fasterxml.jackson.datatype.jsr310
[INFO]    com.fasterxml.jackson.module:jackson-module-parameter-names:jar:2.18.2:compile -- module com.fasterxml.jackson.module.paramnames
[INFO]    org.springframework.boot:spring-boot-starter-tomcat:jar:3.4.2:compile -- module spring.boot.starter.tomcat [auto]
[INFO]    org.apache.tomcat.embed:tomcat-embed-core:jar:10.1.34:compile -- module org.apache.tomcat.embed.core
[INFO]    org.apache.tomcat.embed:tomcat-embed-websocket:jar:10.1.34:compile -- module org.apache.tomcat.embed.websocket
[INFO]    org.springframework:spring-web:jar:6.2.2:compile -- module spring.web [auto]
[INFO]    org.springframework:spring-beans:jar:6.2.2:compile -- module spring.beans [auto]
[INFO]    io.micrometer:micrometer-observation:jar:1.14.3:compile -- module micrometer.observation [auto]
[INFO]    io.micrometer:micrometer-commons:jar:1.14.3:compile -- module micrometer.commons [auto]
[INFO]    org.springframework:spring-webmvc:jar:6.2.2:compile -- module spring.webmvc [auto]
[INFO]    org.springframework:spring-context:jar:6.2.2:compile -- module spring.context [auto]
[INFO]    org.springframework:spring-expression:jar:6.2.2:compile -- module spring.expression [auto]
[INFO]    org.springframework.boot:spring-boot-starter-thymeleaf:jar:3.4.2:compile -- module spring.boot.starter.thymeleaf [auto]
[INFO]    org.thymeleaf:thymeleaf-spring6:jar:3.1.3.RELEASE:compile -- module thymeleaf.spring6 [auto]
[INFO]    org.thymeleaf:thymeleaf:jar:3.1.3.RELEASE:compile -- module thymeleaf [auto]
[INFO]    org.attoparser:attoparser:jar:2.0.7.RELEASE:compile -- module attoparser [auto]
[INFO]    org.unbescape:unbescape:jar:1.1.6.RELEASE:compile -- module unbescape [auto]
[INFO]    org.slf4j:slf4j-api:jar:2.0.16:compile -- module org.slf4j
[INFO]    org.springframework.boot:spring-boot-starter-data-jpa:jar:3.4.2:compile -- module spring.boot.starter.data.jpa [auto]
[INFO]    org.springframework.boot:spring-boot-starter-jdbc:jar:3.4.2:compile -- module spring.boot.starter.jdbc [auto]
[INFO]    com.zaxxer:HikariCP:jar:5.1.0:compile -- module com.zaxxer.hikari
[INFO]    org.springframework:spring-jdbc:jar:6.2.2:compile -- module spring.jdbc [auto]
[INFO]    org.hibernate.orm:hibernate-core:jar:6.6.5.Final:compile -- module org.hibernate.orm.core [auto]
[INFO]    jakarta.persistence:jakarta.persistence-api:jar:3.1.0:compile -- module jakarta.persistence
[INFO]    jakarta.transaction:jakarta.transaction-api:jar:2.0.1:compile -- module jakarta.transaction
[INFO]    org.jboss.logging:jboss-logging:jar:3.6.1.Final:compile -- module org.jboss.logging
[INFO]    org.hibernate.common:hibernate-commons-annotations:jar:7.0.3.Final:runtime -- module org.hibernate.commons.annotations
[INFO]    io.smallrye:jandex:jar:3.2.0:runtime -- module org.jboss.jandex [auto]
[INFO]    com.fasterxml:classmate:jar:1.7.0:compile -- module com.fasterxml.classmate
[INFO]    org.glassfish.jaxb:jaxb-runtime:jar:4.0.5:runtime -- module org.glassfish.jaxb.runtime
[INFO]    org.glassfish.jaxb:jaxb-core:jar:4.0.5:runtime -- module org.glassfish.jaxb.core
[INFO]    org.eclipse.angus:angus-activation:jar:2.0.2:runtime -- module org.eclipse.angus.activation
[INFO]    org.glassfish.jaxb:txw2:jar:4.0.5:runtime -- module com.sun.xml.txw2
[INFO]    com.sun.istack:istack-commons-runtime:jar:4.1.2:runtime -- module com.sun.istack.runtime
[INFO]    jakarta.inject:jakarta.inject-api:jar:2.0.1:runtime -- module jakarta.inject
[INFO]    org.antlr:antlr4-runtime:jar:4.13.0:compile -- module org.antlr.antlr4.runtime [auto]
[INFO]    org.springframework.data:spring-data-jpa:jar:3.4.2:compile -- module spring.data.jpa [auto]
[INFO]    org.springframework.data:spring-data-commons:jar:3.4.2:compile -- module spring.data.commons [auto]
[INFO]    org.springframework:spring-orm:jar:6.2.2:compile -- module spring.orm [auto]
[INFO]    org.springframework:spring-tx:jar:6.2.2:compile -- module spring.tx [auto]
[INFO]    org.springframework:spring-aspects:jar:6.2.2:compile -- module spring.aspects [auto]
[INFO]    org.aspectj:aspectjweaver:jar:1.9.22.1:compile -- module org.aspectj.weaver [auto]
[INFO]    org.springframework.boot:spring-boot-starter-validation:jar:3.4.2:compile -- module spring.boot.starter.validation [auto]
[INFO]    org.apache.tomcat.embed:tomcat-embed-el:jar:10.1.34:compile -- module org.apache.tomcat.embed.el
[INFO]    org.hibernate.validator:hibernate-validator:jar:8.0.2.Final:compile -- module org.hibernate.validator [auto]
[INFO]    jakarta.validation:jakarta.validation-api:jar:3.0.2:compile -- module jakarta.validation
[INFO]    org.springframework.boot:spring-boot-starter-security:jar:3.4.2:compile -- module spring.boot.starter.security [auto]
[INFO]    org.springframework:spring-aop:jar:6.2.2:compile -- module spring.aop [auto]
[INFO]    org.springframework.security:spring-security-config:jar:6.4.2:compile -- module spring.security.config [auto]
[INFO]    org.springframework.security:spring-security-web:jar:6.4.2:compile -- module spring.security.web [auto]
[INFO]    org.springframework.boot:spring-boot-starter-test:jar:3.4.2:test -- module spring.boot.starter.test [auto]
[INFO]    org.springframework.boot:spring-boot-test:jar:3.4.2:test -- module spring.boot.test [auto]
[INFO]    org.springframework.boot:spring-boot-test-autoconfigure:jar:3.4.2:test -- module spring.boot.test.autoconfigure [auto]
[INFO]    com.jayway.jsonpath:json-path:jar:2.9.0:test -- module json.path [auto]
[INFO]    jakarta.xml.bind:jakarta.xml.bind-api:jar:4.0.2:runtime -- module jakarta.xml.bind
[INFO]    jakarta.activation:jakarta.activation-api:jar:2.1.3:runtime -- module jakarta.activation
[INFO]    net.minidev:json-smart:jar:2.5.1:test -- module json.smart (auto)
[INFO]    net.minidev:accessors-smart:jar:2.5.1:test -- module accessors.smart (auto)
[INFO]    org.ow2.asm:asm:jar:9.6:test -- module org.objectweb.asm
[INFO]    org.assertj:assertj-core:jar:3.26.3:test -- module org.assertj.core
[INFO]    org.awaitility:awaitility:jar:4.2.2:test -- module awaitility (auto)
[INFO]    org.hamcrest:hamcrest:jar:2.2:test -- module org.hamcrest [auto]
[INFO]    org.junit.jupiter:junit-jupiter:jar:5.11.4:test -- module org.junit.jupiter
[INFO]    org.junit.jupiter:junit-jupiter-params:jar:5.11.4:test -- module org.junit.jupiter.params
[INFO]    org.junit.jupiter:junit-jupiter-engine:jar:5.11.4:test -- module org.junit.jupiter.engine
[INFO]    org.junit.platform:junit-platform-engine:jar:1.11.4:test -- module org.junit.platform.engine
[INFO]    org.skyscreamer:jsonassert:jar:1.5.3:test -- module jsonassert (auto)
[INFO]    com.vaadin.external.google:android-json:jar:0.0.20131108.vaadin1:test -- module android.json (auto)
[INFO]    org.springframework:spring-core:jar:6.2.2:compile -- module spring.core [auto]
[INFO]    org.springframework:spring-jcl:jar:6.2.2:compile -- module spring.jcl [auto]
[INFO]    org.springframework:spring-test:jar:6.2.2:test -- module spring.test [auto]
[INFO]    org.xmlunit:xmlunit-core:jar:2.10.0:test -- module org.xmlunit [auto]
[INFO]    org.springframework.security:spring-security-test:jar:6.4.2:test -- module spring.security.test [auto]
[INFO]    org.springframework.security:spring-security-core:jar:6.4.2:compile -- module spring.security.core [auto]
[INFO]    org.springframework.security:spring-security-crypto:jar:6.4.2:compile -- module spring.security.crypto [auto]
[INFO]    com.mysql:mysql-connector-j:jar:8.0.33:runtime -- module mysql.connector.j (auto)
[INFO]    junit:junit:jar:3.8.1:test -- module junit (auto)
[INFO]    org.mockito:mockito-core:jar:5.15.2:test -- module org.mockito [auto]
[INFO]    net.bytebuddy:byte-buddy:jar:1.15.11:runtime -- module net.bytebuddy
[INFO]    net.bytebuddy:byte-buddy-agent:jar:1.15.11:test -- module net.bytebuddy.agent
[INFO]    org.objenesis:objenesis:jar:3.3:test -- module org.objenesis [auto]
[INFO]    org.mockito:mockito-junit-jupiter:jar:5.15.2:test -- module org.mockito.junit.jupiter [auto]
[INFO]    org.junit.jupiter:junit-jupiter-api:jar:5.11.4:test -- module org.junit.jupiter.api
[INFO]    org.opentest4j:opentest4j:jar:1.3.0:test -- module org.opentest4j
[INFO]    org.junit.platform:junit-platform-commons:jar:1.11.4:test -- module org.junit.platform.commons
[INFO]    org.apiguardian:apiguardian-api:jar:1.1.2:test -- module org.apiguardian.api
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.178 s
[INFO] Finished at: 2025-02-17T22:03:44Z
[INFO] ------------------------------------------------------------------------
sre@ubuntu:~/java_projects/book-order-app$ 

