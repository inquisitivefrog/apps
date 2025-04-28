
sre@ubuntu:~/java_projects/simple_app$ mvn dependency:resolve
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------------------< com.simple.apps:myapp >------------------------
[INFO] Building myapp 0.0.1-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-dependency-plugin:3.8.1:resolve (default-cli) @ myapp ---
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
[INFO]    org.springframework.boot:spring-boot-starter-validation:jar:3.4.2:compile -- module spring.boot.starter.validation [auto]
[INFO]    org.apache.tomcat.embed:tomcat-embed-el:jar:10.1.34:compile -- module org.apache.tomcat.embed.el
[INFO]    org.hibernate.validator:hibernate-validator:jar:8.0.2.Final:compile -- module org.hibernate.validator [auto]
[INFO]    jakarta.validation:jakarta.validation-api:jar:3.0.2:compile -- module jakarta.validation
[INFO]    org.jboss.logging:jboss-logging:jar:3.6.1.Final:compile -- module org.jboss.logging
[INFO]    com.fasterxml:classmate:jar:1.7.0:compile -- module com.fasterxml.classmate
[INFO]    org.projectlombok:lombok:jar:1.18.36:compile (optional) -- module lombok
[INFO]    org.springframework.boot:spring-boot-starter-data-jpa:jar:3.4.2:compile -- module spring.boot.starter.data.jpa [auto]
[INFO]    org.springframework.boot:spring-boot-starter-jdbc:jar:3.4.2:compile -- module spring.boot.starter.jdbc [auto]
[INFO]    com.zaxxer:HikariCP:jar:5.1.0:compile -- module com.zaxxer.hikari
[INFO]    org.springframework:spring-jdbc:jar:6.2.2:compile -- module spring.jdbc [auto]
[INFO]    org.hibernate.orm:hibernate-core:jar:6.6.5.Final:compile -- module org.hibernate.orm.core [auto]
[INFO]    jakarta.persistence:jakarta.persistence-api:jar:3.1.0:compile -- module jakarta.persistence
[INFO]    jakarta.transaction:jakarta.transaction-api:jar:2.0.1:compile -- module jakarta.transaction
[INFO]    org.hibernate.common:hibernate-commons-annotations:jar:7.0.3.Final:runtime -- module org.hibernate.commons.annotations
[INFO]    io.smallrye:jandex:jar:3.2.0:runtime -- module org.jboss.jandex [auto]
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
[INFO]    org.slf4j:slf4j-api:jar:2.0.16:compile -- module org.slf4j
[INFO]    org.springframework:spring-aspects:jar:6.2.2:compile -- module spring.aspects [auto]
[INFO]    org.aspectj:aspectjweaver:jar:1.9.22.1:compile -- module org.aspectj.weaver [auto]
[INFO]    com.mysql:mysql-connector-j:jar:9.1.0:compile -- module mysql.connector.j (auto)
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
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.983 s
[INFO] Finished at: 2025-02-12T23:03:28Z
[INFO] ------------------------------------------------------------------------
sre@ubuntu:~/java_projects/simple_app$ 

