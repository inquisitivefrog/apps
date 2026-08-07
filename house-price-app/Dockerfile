FROM openjdk:21-jdk-slim
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} webapp.jar
ENV HOST_IP=192.168.1.107
EXPOSE 8080
ENTRYPOINT ["java","-jar","/webapp.jar"]

