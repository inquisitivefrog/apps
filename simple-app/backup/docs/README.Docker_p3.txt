
sre@ubuntu:~/simple_app/myapp$ cat Dockerfile 
FROM openjdk:7u221-jre-slim
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} app.jar
ENTRYPOINT ["java","-jar","/app.jar"]

sre@ubuntu:~/simple_app/myapp$ docker build .
[+] Building 21.9s (7/7) FINISHED                                                                                                 docker:default
 => [internal] load build definition from Dockerfile                                                                                        0.0s
 => => transferring dockerfile: 155B                                                                                                        0.0s
 => [internal] load metadata for docker.io/library/openjdk:7u221-jre-slim                                                                   1.2s
 => [internal] load .dockerignore                                                                                                           0.0s
 => => transferring context: 2B                                                                                                             0.0s
 => [internal] load build context                                                                                                           3.1s
 => => transferring context: 56.42MB                                                                                                        3.0s
 => [1/2] FROM docker.io/library/openjdk:7u221-jre-slim@sha256:38c7b79abce73883d7a193fdc2607a1f36f710bb22440d5f080c2ed4ccba8bbc            19.5s
 => => resolve docker.io/library/openjdk:7u221-jre-slim@sha256:38c7b79abce73883d7a193fdc2607a1f36f710bb22440d5f080c2ed4ccba8bbc             0.0s
 => => sha256:f6db6a5b7899df0dec9649724f674aa5227bb8188538b2de597294477d996f87 1.36kB / 1.36kB                                              0.0s
 => => sha256:aeba7c9f8f84657cc21f04c41840402bae19fda5462d280a6f7d8afdd48e476a 4.38kB / 4.38kB                                              0.0s
 => => sha256:80e253c906dee8d7b26d7dafa4166149c57cb763d43ba6d483710370c32da5cd 30.15MB / 30.15MB                                            8.3s
 => => sha256:359b1e5bffc36ffeb13a6993169cc333fa6661a6c4eed575d232ce4946cde837 463.82kB / 463.82kB                                          0.8s
 => => sha256:3f816a1ef6133e8f97fa4b0edb9b7e83432b998f2d5018b90bb97231273f6821 247B / 247B                                                  0.5s
 => => sha256:38c7b79abce73883d7a193fdc2607a1f36f710bb22440d5f080c2ed4ccba8bbc 986B / 986B                                                  0.0s
 => => sha256:91e0fb57abef91b68244295d0ba40eff5bd83f23133d267124b13df7c99f3fd0 130B / 130B                                                  1.1s
 => => sha256:a0c9810766c76d2372648e43bc8567846fc031357586fd505fc7c88abf18628a 61.72MB / 61.72MB                                           17.3s
 => => extracting sha256:80e253c906dee8d7b26d7dafa4166149c57cb763d43ba6d483710370c32da5cd                                                   4.9s
 => => extracting sha256:359b1e5bffc36ffeb13a6993169cc333fa6661a6c4eed575d232ce4946cde837                                                   0.1s
 => => extracting sha256:3f816a1ef6133e8f97fa4b0edb9b7e83432b998f2d5018b90bb97231273f6821                                                   0.0s
 => => extracting sha256:91e0fb57abef91b68244295d0ba40eff5bd83f23133d267124b13df7c99f3fd0                                                   0.0s
 => => extracting sha256:a0c9810766c76d2372648e43bc8567846fc031357586fd505fc7c88abf18628a                                                   1.8s
 => [2/2] COPY target/*.jar app.jar                                                                                                         0.6s
 => exporting to image                                                                                                                      0.3s
 => => exporting layers                                                                                                                     0.3s
 => => writing image sha256:51bac94299efb54630bdce3cc2d2bbccdd612a272d823480342d09d63dbf66db                                                0.0s

sre@ubuntu:~/simple_app/myapp$ docker images
REPOSITORY    TAG       IMAGE ID       CREATED          SIZE
<none>        <none>    51bac94299ef   43 seconds ago   253MB
hello-world   latest    74cc54e27dc4   2 weeks ago      10.1kB

sre@ubuntu:~/simple_app/myapp$ docker run --name myapp -d 51bac94299ef
821209de3f9ce53a9a168a1281e8bab1c63a316b5fe550075da7ad3752b49690
sre@ubuntu:~/simple_app/myapp$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
sre@ubuntu:~/simple_app/myapp$ docker ps -a
CONTAINER ID   IMAGE          COMMAND                CREATED          STATUS                      PORTS     NAMES
821209de3f9c   51bac94299ef   "java -jar /app.jar"   9 seconds ago    Exited (1) 7 seconds ago              myapp
2f434340b4d6   hello-world    "/hello"               10 minutes ago   Exited (0) 10 minutes ago             cool_haibt
sre@ubuntu:~/simple_app/myapp$ docker logs myapp
Exception in thread "main" java.lang.UnsupportedClassVersionError: org/springframework/boot/loader/launch/JarLauncher : Unsupported major.minor version 61.0
	at java.lang.ClassLoader.defineClass1(Native Method)
	at java.lang.ClassLoader.defineClass(ClassLoader.java:808)
	at java.security.SecureClassLoader.defineClass(SecureClassLoader.java:142)
	at java.net.URLClassLoader.defineClass(URLClassLoader.java:443)
	at java.net.URLClassLoader.access$100(URLClassLoader.java:65)
	at java.net.URLClassLoader$1.run(URLClassLoader.java:355)
	at java.net.URLClassLoader$1.run(URLClassLoader.java:349)
	at java.security.AccessController.doPrivileged(Native Method)
	at java.net.URLClassLoader.findClass(URLClassLoader.java:348)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:430)
	at sun.misc.Launcher$AppClassLoader.loadClass(Launcher.java:323)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:363)
	at sun.launcher.LauncherHelper.checkAndLoadMain(LauncherHelper.java:482)
