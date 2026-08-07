
tim@Tims-MBP myapp % vi Dockerfile

tim@Tims-MBP myapp % cat Dockerfile 
FROM openjdk:8-jre-slim
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} app.jar
ENTRYPOINT ["java","-jar","/app.jar"]

tim@Tims-MBP simple-app % which docker
/usr/local/bin/docker
tim@Tims-MBP simple-app % docker version
Client:
 Version:           27.4.0
 API version:       1.47
 Go version:        go1.22.10
 Git commit:        bde2b89
 Built:             Sat Dec  7 10:35:43 2024
 OS/Arch:           darwin/amd64
 Context:           desktop-linux
Cannot connect to the Docker daemon at unix:///Users/tim/.docker/run/docker.sock. Is the docker daemon running?

